package sectr

import "core:math"
import "core:os"
import ve         "codebase:font/VEFontCache"
import sokol_gfx  "thirdparty:sokol/gfx"

Font_Provider_Use_Freetype :: false
Font_Largest_Px_Size       :: 152
Font_Size_Interval         :: 2

Font_Default            :: FontID { 0, "" }
Font_Default_Point_Size :: 12.0

Font_Load_Use_Default_Size :: -1
Font_Load_Gen_ID           :: ""

FontID  :: struct {
	key   : u64,
	label : string,
}

FontDef :: struct {
	path_file    : string,
	default_size : i32,
	size_table   : [Font_Largest_Px_Size / Font_Size_Interval] ve.Font_ID,
}

FontProviderContext :: struct
{
	ve_ctx     : ve.Context,
	font_cache : HMapChained(FontDef),

	using render : VE_RenderData,
}

ShapedText :: ve.Shaped_Text

font_provider_startup :: proc( ctx : ^FontProviderContext )
{
	profile(#procedure)
	using ctx

	error : AllocatorError
	font_cache, error = make( HMapChained(FontDef), hmap_closest_prime(1 * Kilo), persistent_allocator(), dbg_name = "font_cache" )
	verify( error == AllocatorError.None, "Failed to allocate font_cache" )

	ve.startup( & ve_ctx, .STB_TrueType, allocator = persistent_slab_allocator() )
	ve_ctx.glyph_buffer.over_sample = { 4,4 }
	log("VEFontCached initialized")
	font_provider_setup_sokol_gfx_objects( & render, ve_ctx )
}

font_provider_reload :: proc( ctx : ^FontProviderContext )
{
	ctx.ve_ctx.glyph_buffer.over_sample = { 4,4 } * 1.0
	hmap_chained_reload( ctx.font_cache, persistent_allocator())
	ve.hot_reload( & ctx.ve_ctx, persistent_slab_allocator() )
	ve.clear_atlas_region_caches(& ctx.ve_ctx)
	ve.clear_shape_cache(& ctx.ve_ctx)
}

font_provider_shutdown :: proc(  ctx : ^FontProviderContext )
{
	ve.shutdown( & ctx.ve_ctx )
}

font_load :: proc(path_file : string,
	default_size : i32    = Font_Load_Use_Default_Size,
	desired_id   : string = Font_Load_Gen_ID
) -> FontID
{
	provider_data := & get_state().font_provider_ctx; using provider_data

	msg := str_fmt_tmp("Loading font: %v", path_file)
	profile(msg)
	log(msg)

	font_data, read_succeded : = os.read_entire_file( path_file, persistent_allocator() )
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

	font_cache_watch := font_cache

	key            := cast(u64) crc32( transmute([]byte) desired_id )
	def, set_error := hmap_chained_set(font_cache, key, FontDef{})
	verify( set_error == AllocatorError.None, "Failed to add new font entry to cache" )

	default_size := default_size
	if default_size < 0 {
		default_size = Font_Default_Point_Size
	}

	def.path_file    = path_file
	def.default_size = default_size

	for font_size : i32 = clamp( Font_Size_Interval, 2, Font_Size_Interval ); font_size <= Font_Largest_Px_Size; font_size += Font_Size_Interval
	{
		// logf("Loading at size %v", font_size)
		id    := (font_size / Font_Size_Interval) + (font_size % Font_Size_Interval)
		ve_id := & def.size_table[id - 1]
		ve_ret_id := ve.load_font( & ve_ctx, desired_id, font_data, f32(font_size) )
		(ve_id^) = ve_ret_id
	}

	fid := FontID { key, desired_id }
	return fid
}

Font_Use_Default_Size :: f32(0.0)

font_provider_resolve_draw_id :: #force_inline proc( id : FontID, size := Font_Use_Default_Size ) -> (ve_id :ve.Font_ID, resolved_size : i32)
{
	provider_data := get_state().font_provider_ctx; using provider_data

	def           := hmap_chained_get( font_cache, id.key )
	size          := size == 0.0 ? f32(def.default_size) : size
	even_size     := math.round(size * (1.0 / f32(Font_Size_Interval))) * f32(Font_Size_Interval)
	resolved_size  = clamp( i32( even_size), 2, Font_Largest_Px_Size )

	id    := (resolved_size / Font_Size_Interval) + (resolved_size % Font_Size_Interval)
	ve_id  = def.size_table[ id - 1 ]
	return
}

measure_text_size :: #force_inline proc( text : string, font : FontID, font_size := Font_Use_Default_Size, spacing : f32 ) -> Vec2
{
	ve_id, size := font_provider_resolve_draw_id( font, font_size )
	measured    := ve.measure_text_size( & get_state().font_provider_ctx.ve_ctx, ve_id, f32(size), text )
	return measured
}

get_font_vertical_metrics :: #force_inline proc ( font : FontID, font_size := Font_Use_Default_Size ) -> ( ascent, descent, line_gap : f32 )
{
	ve_id, size := font_provider_resolve_draw_id( font, font_size )
	ascent, descent, line_gap = ve.get_font_vertical_metrics( & get_state().font_provider_ctx.ve_ctx, ve_id, font_size )
	return
}

shape_text_cached_latin :: #force_inline proc( text : string, font : FontID, font_size := Font_Use_Default_Size, scalar : f32 ) -> ShapedText
{
	ve_id, size := font_provider_resolve_draw_id( font, font_size * scalar )
	shape       := ve.shape_text_latin( & get_state().font_provider_ctx.ve_ctx, ve_id, f32(size), text )
	return shape
}

shape_text_cached :: #force_inline proc( text : string, font : FontID, font_size := Font_Use_Default_Size, scalar : f32 ) -> ShapedText
{
	ve_id, size := font_provider_resolve_draw_id( font, font_size * scalar )
	shape       := ve.shape_text_advanced( & get_state().font_provider_ctx.ve_ctx, ve_id, f32(size), text )
	return shape
}
