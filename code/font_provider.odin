package sectr

import "core:fmt"
import "core:math"
import "core:mem"
import "core:path/filepath"
import "core:os"

import rl "vendor:raylib"

Font_Arena_Size      :: 32 * Megabyte
Font_Largest_Px_Size :: 96

Font_Default :: ""
Font_Default_Point_Size :: 18.0

Font_TTF_Default_Chars_Padding :: 4

Font_Load_Use_Default_Size :: -1
Font_Load_Gen_ID           :: ""

Font_Atlas_Packing_Method :: enum u32 {
	Raylib_Basic = 0,  // Basic packing algo
	Skyeline_Rect = 1, // stb_pack_rect
}

// TODO(Ed) : This isn't good enough for what we need font wise..
Font :: rl.Font

// TODO(Ed) : Use this instead of the raylib font directly
FontID  :: distinct string
FontTag :: struct {
	key        : FontID,
	point_size : f32
}

FontGlyphsRender :: struct {
	size    : i32,
	count   : i32,
	padding : i32,
	texture : rl.Texture2D,
	recs    : [^]rl.Rectangle, // Characters rectangles in texture
	glyphs  : [^]rl.GlyphInfo, // Characters info data
}

FontDef :: struct {
	path_file    : string,
	data         : [] u8,
	default_size : i32,
	size_table   : [Font_Largest_Px_Size] FontGlyphsRender,
}

FontProviderData :: struct {
	font_arena : Arena,
	font_cache : ^ map [FontID] FontDef,
}

font_provider_startup :: proc()
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	data, alloc_result := alloc_bytes( Font_Arena_Size, allocator = persistent_allocator() )
	verify( alloc_result != AllocatorError.None, "Failed to allocate memory for font_arena from persistent" )
	log("font_arena allocated from persistent memory")

	arena_init( & font_arena, data )

	font_cache = new( type_of(font_cache ^), arena_allocator( & font_arena) )
	log("font_cache created")
	log("font_provider initialized")
}

font_provider_shutdown :: proc()
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	for key, & value in font_cache        {
		for & px_render in value.size_table {
			using px_render
			rl.UnloadFontData( glyphs, count )
			rl.UnloadTexture ( texture )
			rl.MemFree( recs )
		}
	}
}

font_load :: proc ( path_file : string,
	default_size : f32    = Font_Load_Use_Default_Size,
	desired_id   : FontID = Font_Load_Gen_ID
) -> FontID
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_data, read_succeded : = os.read_entire_file( path_file  )
	verify( ! read_succeded, fmt.tprintf("Failed to read font file for: %v", path_file) )
	font_data_size := cast(i32) len(font_data)

	desired_id := desired_id
	// Use file name as key
	if len(desired_id) == 0 {
		// NOTE(Ed): This should never be used except for laziness so I'll be throwing a warning everytime.
		log("desired_key not provided, using file name. Give it a proper name!")
		desired_id = cast(FontID) file_name_from_path(path_file)
	}

	default_size := default_size
	if default_size == Font_Load_Use_Default_Size {
		default_size = Font_Default_Point_Size
	}

	font_cache[desired_id] = {}
	def := & font_cache[desired_id];
	def.path_file    = path_file
	def.data         = font_data
	def.default_size = i32(points_to_pixels(default_size))

	// TODO(Ed): this is extremely slow
	// Render all sizes at once
	for id : i32 = 0; id < Font_Largest_Px_Size; id += 1
	{
		px_render := & def.size_table[id]
		using px_render
		size    = id + 1
		count   = 95 // This is the default codepoint count from raylib when loading a font.
		padding = Font_TTF_Default_Chars_Padding
		glyphs  = rl.LoadFontData( raw_data(font_data), font_data_size,
			fontSize       = size,
			codepoints     = nil,
			codepointCount = count,
			type = rl.FontType.DEFAULT )
		verify( glyphs == nil, fmt.tprintf("Failed to load glyphs for font: %v at desired size: %v", desired_id, size ) )

		atlas  := rl.GenImageFontAtlas( glyphs, & recs, count, size, padding, i32(Font_Atlas_Packing_Method.Raylib_Basic) )
		texture = rl.LoadTextureFromImage( atlas )
		rl.SetTextureFilter( texture, rl.TextureFilter.POINT )

		// glyphs_slice := slice_ptr( glyphs, count )
		// for glyph in glyphs_slice {
		// TODO(Ed) : See if above can properly reference

		// NOTE(raylib): Update glyphs[i].image to use alpha, required to be used on image_draw_text()
		for glyph_id : i32 = 0; glyph_id < count; glyph_id += 1 {
			glyph := & glyphs[glyph_id]

			rl.UnloadImage( glyph.image )
			glyph.image = rl.ImageFromImage( atlas, recs[glyph_id] )
		}
		rl.UnloadImage( atlas )
	}

	return desired_id
}

Font_Use_Default_Size :: f32(0.0)

to_rl_Font :: proc ( id : FontID, size := Font_Use_Default_Size ) -> rl.Font {
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	size := clamp( i32(math.round(size)), 12, Font_Largest_Px_Size )

	verify( size > Font_Largest_Px_Size, "attempt to get a font larger than the largest loaded pixel size" )
	def       := & font_cache[id]
	size       = size if size != i32(Font_Use_Default_Size) else def.default_size
	px_render := & def.size_table[ size - 1 ]

	rl_font : rl.Font
	rl_font.baseSize     = px_render.size
	rl_font.charsCount   = px_render.count
	rl_font.charsPadding = px_render.padding
	rl_font.glyphs       = px_render.glyphs
	rl_font.recs         = px_render.recs
	rl_font.texture      = px_render.texture
	return rl_font
}
