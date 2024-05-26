package sectr

import "core:os"

Font_Largest_Px_Size :: 32

Font_Size_Interval :: 2

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

FontID  :: struct {
	key   : u64,
	label : string,
}
FontTag :: struct {
	key        : FontID,
	point_size : f32
}

FontDef :: struct {
	path_file : string,

	
}

FontProviderData :: struct {
	font_cache : HMapChainedPtr(FontDef),
}

font_provider_startup :: proc()
{
	profile(#procedure)
	state := get_state()
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_cache_alloc_error : AllocatorError
	font_cache, font_cache_alloc_error = hmap_chained_init(FontDef, hmap_closest_prime(1 * Kilo), persistent_allocator(), dbg_name = "font_cache" )
	verify( font_cache_alloc_error == AllocatorError.None, "Failed to allocate font_cache" )

	log("font_cache created")
	log("font_provider initialized")
}

font_provider_shutdown :: proc()
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	for & entry in font_cache.lookup
	{
		if entry == nil do continue

		def := entry.value
		// for & px_render in def.size_table {
		// 	using px_render
			// rl.UnloadFontData( glyphs, count )
			// rl.UnloadTexture ( texture )
			// rl.MemFree( recs )
		// }
	}
}

font_load :: proc(path_file : string,
	default_size : f32    = Font_Load_Use_Default_Size,
	desired_id   : string = Font_Load_Gen_ID
) -> FontID
{
	profile(#procedure)

	logf("Loading font: %v", path_file)
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_data, read_succeded : = os.read_entire_file( path_file )
	verify( b32(read_succeded), str_fmt("Failed to read font file for: %v", path_file) )
	font_data_size := cast(i32) len(font_data)

	desired_id := desired_id
	// Use file name as key
	if len(desired_id) == 0 {
		// NOTE(Ed): This should never be used except for laziness so I'll be throwing a warning everytime.
		log("desired_key not provided, using file name. Give it a proper name!", LogLevel.Warning)
		// desired_id = cast(FontID) file_name_from_path(path_file)
		desired_id = file_name_from_path(path_file)
	}

	// default_size := default_size
	// if default_size == Font_Load_Use_Default_Size {
	// 	default_size = Font_Default_Point_Size
	// }

	key            := cast(u64) crc32( transmute([]byte) desired_id )
	def, set_error := hmap_chained_set(font_cache, key, FontDef{})
	verify( set_error == AllocatorError.None, "Failed to add new font entry to cache" )

	def.path_file    = path_file
	// def.default_size = i32(points_to_pixels(default_size))



	return {}
}
