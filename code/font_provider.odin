package sectr

import "core:fmt"
import "core:math"
import "core:mem"
import "core:path/filepath"
import "core:os"

import rl "vendor:raylib"

Font_Largest_Px_Size :: 96

// Font_Default :: ""
Font_Default            :: FontID { 0, "" }
Font_Default_Point_Size :: 18.0

Font_TTF_Default_Chars_Padding :: 4

Font_Load_Use_Default_Size :: -1
Font_Load_Gen_ID           :: ""

Font_Atlas_Packing_Method :: enum u32 {
	Raylib_Basic  = 0, // Basic packing algo
	Skyeline_Rect = 1, // stb_pack_rect
}

// TODO(Ed) : These are currently i32, I wanted them to be string ids for debug ease of use.
// There is an issue with the hash map type preventing me from doing so. Its allocator reference breaks.
// FontID  :: distinct string
FontID  :: struct {
	key   : u64,
	label : string,
}
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

	// TODO(Ed) : you may have to store font data in the future if we render on demand
	// data         : []u8,

	default_size : i32,
	size_table   : [Font_Largest_Px_Size / 2] FontGlyphsRender,
}

FontProviderData :: struct {
	font_cache : HMapZPL(FontDef),
}

font_provider_startup :: proc()
{
	state := get_state()
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_cache_alloc_error : AllocatorError
	font_cache, font_cache_alloc_error = zpl_hmap_init_reserve( FontDef, general_slab_allocator(), 2 )
	verify( font_cache_alloc_error == AllocatorError.None, "Failed to allocate font_cache" )

	log("font_cache created")
	log("font_provider initialized")
}

font_provider_shutdown :: proc()
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	for id in 0 ..< font_cache.entries.num
	{
		def := & font_cache.entries.data[id].value

		for & px_render in def.size_table {
			using px_render
			rl.UnloadFontData( glyphs, count )
			rl.UnloadTexture ( texture )
			rl.MemFree( recs )
		}
	}
}

font_load :: proc( path_file : string,
	default_size : f32    = Font_Load_Use_Default_Size,
	desired_id   : string = Font_Load_Gen_ID
) -> FontID
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_data, read_succeded : = os.read_entire_file( path_file, context.temp_allocator )
	verify( b32(read_succeded), str_fmt_tmp("Failed to read font file for: %v", path_file) )
	font_data_size := cast(i32) len(font_data)

	desired_id := desired_id
	// Use file name as key
	if len(desired_id) == 0 {
		// NOTE(Ed): This should never be used except for laziness so I'll be throwing a warning everytime.
		log("desired_key not provided, using file name. Give it a proper name!", LogLevel.Warning)
		// desired_id = cast(FontID) file_name_from_path(path_file)
		desired_id = file_name_from_path(path_file)
	}

	default_size := default_size
	if default_size == Font_Load_Use_Default_Size {
		default_size = Font_Default_Point_Size
	}

	key            := cast(u64) crc32( transmute([]byte) desired_id )
	def, set_error := zpl_hmap_set( & font_cache, key,FontDef {} )
	verify( set_error == AllocatorError.None, "Failed to add new font entry to cache" )

	def.path_file    = path_file
	// def.data         = font_data
	def.default_size = i32(points_to_pixels(default_size))

	// TODO(Ed): this is slow & eats quite a bit of memory early on. Setup a more on demand load for a specific size.
	// Also, we need to eventually switch to a SDF shader for rendering

	// Render all sizes at once
	// Note(Ed) : We only generate textures for even multiples of the font.
	for font_size : i32 = 2; font_size <= Font_Largest_Px_Size; font_size += 2
	{
		id := (font_size / 2) + (font_size % 2)

		px_render := & def.size_table[id - 1]
		using px_render
		size    = font_size
		count   = 95 // This is the default codepoint count from raylib when loading a font.
		padding = Font_TTF_Default_Chars_Padding
		glyphs  = rl.LoadFontData( raw_data(font_data), font_data_size,
			fontSize       = size,
			codepoints     = nil,
			codepointCount = count,
			type = rl.FontType.DEFAULT )
		verify( glyphs != nil, str_fmt_tmp("Failed to load glyphs for font: %v at desired size: %v", desired_id, size ) )

		atlas  := rl.GenImageFontAtlas( glyphs, & recs, count, size, padding, i32(Font_Atlas_Packing_Method.Raylib_Basic) )
		texture = rl.LoadTextureFromImage( atlas )

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

	free_all( context.temp_allocator )
	return { key, desired_id }
}

Font_Use_Default_Size :: f32(0.0)

to_rl_Font :: proc( id : FontID, size := Font_Use_Default_Size ) -> rl.Font
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	even_size := math.round(size * 0.5) * 2.0
	size      := clamp( i32( even_size), 8, Font_Largest_Px_Size )
	def       := zpl_hmap_get( & font_cache, id.key )
	size       = size if size != i32(Font_Use_Default_Size) else def.default_size

	id        := (size / 2) + (size % 2)
	px_render := & def.size_table[ id - 1 ]

	// This is free for now perf wise... may have to move this out to on a setting change later.
	rl.SetTextureFilter( px_render.texture, rl.TextureFilter.TRILINEAR )

	rl_font : rl.Font
	rl_font.baseSize     = px_render.size
	rl_font.glyphCount   = px_render.count
	rl_font.glyphPadding = px_render.padding
	rl_font.glyphs       = px_render.glyphs
	rl_font.recs         = px_render.recs
	rl_font.texture      = px_render.texture
	return rl_font
}
