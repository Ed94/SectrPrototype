package sectr

import "core:os"
import ve        "codebase:font/VEFontCache"
import sokol_gfx "thirdparty:sokol/gfx"


Font_Provider_Use_Freetype :: false
Font_Largest_Px_Size       :: 72
Font_Size_Interval         :: 2

Font_Default            :: FontID { 0, "" }
Font_Default_Point_Size :: 18.0

Font_Load_Use_Default_Size :: -1
Font_Load_Gen_ID           :: ""

FontID  :: struct {
	key   : u64,
	label : string,
}

FontDef :: struct {
	path_file : string,
	ve_id     : ve.FontID,
}

FontProviderData :: struct
{
	ve_font_cache : ve.Context,
	font_cache    : HMapChained(FontDef),

	gfx_bindings  : sokol_gfx.Bindings,
	gfx_pipeline  : sokol_gfx.Pipeline,
	gfx_v_buffer  : sokol_gfx.Buffer,
	gfx_uv_buffer : sokol_gfx.Buffer,
	gfx_sampler   : sokol_gfx.Sampler,
}

font_provider_startup :: proc()
{
	profile(#procedure)
	state := get_state()

	provider_data := & state.font_provider_data; using provider_data

	error : AllocatorError
	font_cache, error = make( HMapChained(FontDef), hmap_closest_prime(1 * Kilo), persistent_allocator() /*dbg_name = "font_cache"*/ )
	verify( error == AllocatorError.None, "Failed to allocate font_cache" )

	ve.init( & provider_data.ve_font_cache, .STB_TrueType, allocator = persistent_slab_allocator() )
	log("VEFontCached initialized")

	// TODO(Ed): Setup sokol hookup for VEFontCache
}

font_provider_shutdown :: proc()
{
	state := get_state()
	provider_data := state.font_provider_data; using provider_data

	ve.shutdown( & provider_data.ve_font_cache )
}

font_load :: proc(path_file : string,
	default_size : f32    = Font_Load_Use_Default_Size,
	desired_id   : string = Font_Load_Gen_ID
) -> FontID
{
	profile(#procedure)

	logf("Loading font: %v", path_file)
	provider_data := & get_state().font_provider_data; using provider_data

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

	font_cache_watch := provider_data.font_cache

	key            := cast(u64) crc32( transmute([]byte) desired_id )
	def, set_error := hmap_chained_set(font_cache, key, FontDef{})
	verify( set_error == AllocatorError.None, "Failed to add new font entry to cache" )

	// TODO(Ed): Load even sizes from 8px to upper bound.
	def.ve_id = ve.load_font( & provider_data.ve_font_cache, desired_id, font_data, default_size )

	fid := FontID { key, desired_id }
	return fid
}
