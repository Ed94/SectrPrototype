/*
A port of (https://github.com/hypernewbie/VEFontCache) to Odin.

See: https://github.com/Ed94/VEFontCache-Odin
*/
package vefontcache

import "base:runtime"

// White: Cached Hit, Red: Cache Miss, Yellow: Oversized
ENABLE_DRAW_TYPE_VIS :: true 
// See: mappings.odin for profiling hookup
DISABLE_PROFILING    :: false

Font_ID :: distinct i32
Glyph   :: distinct i32

Entry :: struct {
	parser_info   : Parser_Font_Info,
	shaper_info   : Shaper_Info,
	id            : Font_ID,
	used          : b32,
	curve_quality : f32,

	ascent   : f32,
	descent  : f32,
	line_gap : f32,
}

Entry_Default :: Entry {
	id            = 0,
	used          = false,
	curve_quality = 3,
}

Context :: struct {
	backing : Allocator,

	parser_ctx  : Parser_Context, // Glyph parser state
	shaper_ctx  : Shaper_Context, // Text shaper state

	// The managed font instances
	entries : [dynamic]Entry,

	glyph_buffer : Glyph_Draw_Buffer,
	atlas        : Atlas,
	shape_cache  : Shaped_Text_Cache,
	draw_list    : Draw_List,

	// Tracks the offsets for the current layer in a draw_list
	draw_layer : struct {
		vertices_offset : int,
		indices_offset  : int,
		calls_offset    : int,
	},

	// Helps with hinting
	snap_width  : f32,
	snap_height : f32,

	colour       : Colour, // Color used in draw interface
	cursor_pos   : Vec2,
	alpha_scalar : f32,    // Will apply a multiplier to the colour's alpha which provides some sharpening of the edges.
	// Used by draw interface to super-scale the text by 
	// upscaling px_size with px_scalar and then down-scaling
	// the draw_list result by the same amount.
	px_scalar    : f32,

	default_curve_quality : i32,

	debug_print         : b32,
	debug_print_verbose : b32,
}

Init_Atlas_Region_Params :: struct {
	width  : u32,
	height : u32,
}

Init_Atlas_Params :: struct {
	width             : u32,
	height            : u32,
	glyph_padding     : u32, // Padding to add to bounds_<width/height>_scaled for choosing which atlas region.
	glyph_over_scalar : f32, // Scalar to apply to bounds_<width/height>_scaled for choosing which atlas region.

	region_a : Init_Atlas_Region_Params,
	region_b : Init_Atlas_Region_Params,
	region_c : Init_Atlas_Region_Params,
	region_d : Init_Atlas_Region_Params,
}

Init_Atlas_Params_Default :: Init_Atlas_Params {
	width             = 4096,
	height            = 2048,
	glyph_padding     = 1,
	glyph_over_scalar = 1,

	region_a = {
		width  = 32,
		height = 32,
	},
	region_b = {
		width  = 32,
		height = 64,
	},
	region_c = {
		width  = 64,
		height = 64,
	},
	region_d = {
		width  = 128,
		height = 128,
	}
}

Init_Glyph_Draw_Params :: struct {
	over_sample               : Vec2,
	draw_padding              : u32,
	shape_gen_scratch_reserve : u32,
	buffer_batch              : u32,
	buffer_batch_glyph_limit  : u32, // How many glyphs can at maximimum be proccessed at once by batch_generate_glyphs_draw_list
}

Init_Glyph_Draw_Params_Default :: Init_Glyph_Draw_Params {
	over_sample                     = Vec2 { 4, 4 },
	draw_padding                    = Init_Atlas_Params_Default.glyph_padding,
	shape_gen_scratch_reserve       = 10 * 1024,
	buffer_batch                    = 4,
	buffer_batch_glyph_limit        = 512,
}

Init_Shaper_Params :: struct {
	snap_glyph_position           : b32,
	adv_snap_small_font_threshold : u32,
}

Init_Shaper_Params_Default :: Init_Shaper_Params {
	snap_glyph_position           = true,
	adv_snap_small_font_threshold = 0,
}

Init_Shape_Cache_Params :: struct {
	capacity       : u32,
	reserve_length : u32,
}

Init_Shape_Cache_Params_Default :: Init_Shape_Cache_Params {
	capacity       = 10 * 1024,
	reserve_length = 10 * 1024,
}

//#region("lifetime")

// ve_fontcache_init
startup :: proc( ctx : ^Context, parser_kind : Parser_Kind = .STB_TrueType,
	allocator                   := context.allocator,
	atlas_params                := Init_Atlas_Params_Default,
	glyph_draw_params           := Init_Glyph_Draw_Params_Default,
	shape_cache_params          := Init_Shape_Cache_Params_Default,
	shaper_params               := Init_Shaper_Params_Default,
	alpha_sharpen               := 0.2,
	// Curve quality to use for a font when unspecified,
	// Affects step size for bezier curve passes in generate_glyph_pass_draw_list
	default_curve_quality       : u32 = 3,
	entires_reserve             : u32 = 256,
)
{
	assert( ctx != nil, "Must provide a valid context" )
	using ctx

	ctx.backing       = allocator
	context.allocator = ctx.backing

	ctx.colour = { 1, 1, 1, 1 }

	shaper_ctx.adv_snap_small_font_threshold = f32(shaper_params.adv_snap_small_font_threshold)
	shaper_ctx.snap_glyph_position           = shaper_params.snap_glyph_position

	if default_curve_quality == 0 {
		default_curve_quality = 3
	}
	ctx.default_curve_quality = default_curve_quality

	error : Allocator_Error
	entries, error = make( [dynamic]Entry, len = 0, cap = entires_reserve )
	assert(error == .None, "VEFontCache.init : Failed to allocate entries")

	draw_list.vertices, error = make( [dynamic]Vertex, len = 0, cap = 8 * Kilobyte )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.vertices")

	draw_list.indices, error = make( [dynamic]u32, len = 0, cap = 16 * Kilobyte )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.indices")

	draw_list.calls, error = make( [dynamic]Draw_Call, len = 0, cap = 1024 )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.calls")

	init_atlas_region :: proc( region : ^Atlas_Region, params : Init_Atlas_Params, region_params : Init_Atlas_Region_Params, factor : Vec2i, expected_cap : i32 )
	{
		using region

		next_idx = 0;
		width    = i32(region_params.width)
		height   = i32(region_params.height)
		size = {
			i32(params.width)  / factor.x,
			i32(params.height) / factor.y,
		}
		capacity = {
			size.x / i32(width),
			size.y / i32(height),
		}
		assert( capacity.x * capacity.y == expected_cap )

		error : Allocator_Error
		lru_init( & state, capacity.x * capacity.y )
	}
	init_atlas_region( & atlas.region_a, atlas_params, atlas_params.region_a, { 4, 2}, 1024 )
	init_atlas_region( & atlas.region_b, atlas_params, atlas_params.region_b, { 4, 2}, 512 )
	init_atlas_region( & atlas.region_c, atlas_params, atlas_params.region_c, { 4, 1}, 512 )
	init_atlas_region( & atlas.region_d, atlas_params, atlas_params.region_d, { 2, 1}, 256 )

	atlas.width             = i32(atlas_params.width)
	atlas.height            = i32(atlas_params.height)
	atlas.glyph_padding     = f32(atlas_params.glyph_padding)
	atlas.glyph_over_scalar = atlas_params.glyph_over_scalar

	atlas.region_a.offset   = {0, 0}
	atlas.region_b.offset.x = 0
	atlas.region_b.offset.y = atlas.region_a.size.y
	atlas.region_c.offset.x = atlas.region_a.size.x
	atlas.region_c.offset.y = 0
	atlas.region_d.offset.x = atlas.width / 2
	atlas.region_d.offset.y = 0

	atlas.regions = {
		nil,
		& atlas.region_a,
		& atlas.region_b,
		& atlas.region_c,
		& atlas.region_d,
	}

	lru_init( & shape_cache.state, i32(shape_cache_params.capacity) )

	shape_cache.storage, error = make( [dynamic]Shaped_Text, shape_cache_params.capacity )
	assert(error == .None, "VEFontCache.init : Failed to allocate shape_cache.storage")

	for idx : u32 = 0; idx < shape_cache_params.capacity; idx += 1 {
		stroage_entry := & shape_cache.storage[idx]
		using stroage_entry
		glyphs, error = make( [dynamic]Glyph, len = 0, cap = shape_cache_params.reserve_length )
		assert( error == .None, "VEFontCache.init : Failed to allocate glyphs array for shape cache storage" )

		positions, error = make( [dynamic]Vec2, len = 0, cap = shape_cache_params.reserve_length )
		assert( error == .None, "VEFontCache.init : Failed to allocate positions array for shape cache storage" )

		draw_list.calls, error = make( [dynamic]Draw_Call, len = 0, cap = glyph_draw_params.buffer_batch * 2 )
		assert( error == .None, "VEFontCache.init : Failed to allocate calls for draw_list" )

		draw_list.indices, error = make( [dynamic]u32, len = 0, cap = glyph_draw_params.buffer_batch * 2 * 6 )
		assert( error == .None, "VEFontCache.init : Failed to allocate indices array for draw_list" )

		draw_list.vertices, error = make( [dynamic]Vertex, len = 0, cap = glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error == .None, "VEFontCache.init : Failed to allocate vertices array for draw_list" )
	}

	Glyph_Buffer_Setup:
	{
		using glyph_buffer
		over_sample   = glyph_draw_params.over_sample
		batch         = cast(i32) glyph_draw_params.buffer_batch
		width         = atlas.region_d.width  * i32(over_sample.x) * batch
		height        = atlas.region_d.height * i32(over_sample.y) //* (batch / 2)
		draw_padding  = cast(f32) glyph_draw_params.draw_padding

		draw_list.calls, error = make( [dynamic]Draw_Call, len = 0, cap = glyph_draw_params.buffer_batch * 2 )
		assert( error == .None, "VEFontCache.init : Failed to allocate calls for draw_list" )

		draw_list.indices, error = make( [dynamic]u32, len = 0, cap = glyph_draw_params.buffer_batch * 2 * 6 )
		assert( error == .None, "VEFontCache.init : Failed to allocate indices array for draw_list" )

		draw_list.vertices, error = make( [dynamic]Vertex, len = 0, cap = glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error == .None, "VEFontCache.init : Failed to allocate vertices array for draw_list" )

		clear_draw_list.calls, error = make( [dynamic]Draw_Call, len = 0, cap = glyph_draw_params.buffer_batch * 2 )
		assert( error == .None, "VEFontCache.init : Failed to allocate calls for calls for clear_draw_list" )

		clear_draw_list.indices, error = make( [dynamic]u32, len = 0, cap = glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error == .None, "VEFontCache.init : Failed to allocate calls for indices array for clear_draw_list" )

		clear_draw_list.vertices, error = make( [dynamic]Vertex, len = 0, cap = glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error == .None, "VEFontCache.init : Failed to allocate vertices array for clear_draw_list" )

		shape_gen_scratch, error = make( [dynamic]Vertex, len = 0, cap = glyph_draw_params.buffer_batch_glyph_limit )
		assert(error == .None, "VEFontCache.init : Failed to allocate shape_gen_scratch")

		batch_cache.cap = i32(glyph_draw_params.buffer_batch_glyph_limit)
		batch_cache.num = 0
		batch_cache.table, error = make( map[u32]b8, uint(glyph_draw_params.shape_gen_scratch_reserve) )
		assert(error == .None, "VEFontCache.init : Failed to allocate batch_cache")

		glyph_pack,error = make_soa( #soa[dynamic]Glyph_Pack_Entry, length = 0, capacity = 1 * Kilobyte, allocator = context.temp_allocator )
		oversized, error = make( [dynamic]i32, len = 0, cap = 1 * Kilobyte, allocator = context.temp_allocator )
		to_cache,  error = make( [dynamic]i32, len = 0, cap = 1 * Kilobyte, allocator = context.temp_allocator )
		cached,    error = make( [dynamic]i32, len = 0, cap = 1 * Kilobyte, allocator = context.temp_allocator )
	}

	parser_init( & parser_ctx, parser_kind )
	shaper_init( & shaper_ctx )
}

hot_reload :: proc( ctx : ^Context, allocator : Allocator )
{
	assert( ctx != nil )
	ctx.backing       = allocator
	context.allocator = ctx.backing
	using ctx

	reload_array( & entries, allocator )

	reload_array( & draw_list.vertices, allocator)
	reload_array( & draw_list.indices, allocator )
	reload_array( & draw_list.calls, allocator )

	lru_reload( & atlas.region_a.state, allocator)
	lru_reload( & atlas.region_b.state, allocator)
	lru_reload( & atlas.region_c.state, allocator)
	lru_reload( & atlas.region_d.state, allocator)

	lru_reload( & shape_cache.state, allocator )
	for idx : i32 = 0; idx < i32(len(shape_cache.storage)); idx += 1 {
		stroage_entry := & shape_cache.storage[idx]
		using stroage_entry

		reload_array( & glyphs, allocator )
		reload_array( & positions, allocator )
	}

	reload_array( & glyph_buffer.draw_list.calls, allocator )
	reload_array( & glyph_buffer.draw_list.indices, allocator )
	reload_array( & glyph_buffer.draw_list.vertices, allocator )

	reload_array( & glyph_buffer.clear_draw_list.calls, allocator )
	reload_array( & glyph_buffer.clear_draw_list.indices, allocator )
	reload_array( & glyph_buffer.clear_draw_list.vertices, allocator )

	reload_array_soa( & glyph_buffer.glyph_pack, allocator )
	reload_array( & glyph_buffer.oversized,  allocator )
	reload_array( & glyph_buffer.to_cache,   allocator )
	reload_array( & glyph_buffer.cached,     allocator )

	reload_array( & glyph_buffer.shape_gen_scratch, allocator )
	reload_map( & glyph_buffer.batch_cache.table, allocator )

	reload_array( & shape_cache.storage, allocator )
}

shutdown :: proc( ctx : ^Context )
{
	assert( ctx != nil )
	context.allocator = ctx.backing
	using ctx

	for & entry in entries {
		unload_font( ctx, entry.id )
	}

	delete( entries )

	delete( draw_list.vertices )
	delete( draw_list.indices )
	delete( draw_list.calls )

	lru_free( & atlas.region_a.state )
	lru_free( & atlas.region_b.state )
	lru_free( & atlas.region_c.state )
	lru_free( & atlas.region_d.state )

	for idx : i32 = 0; idx < i32(len(shape_cache.storage)); idx += 1 {
		stroage_entry := & shape_cache.storage[idx]
		using stroage_entry

		delete( glyphs )
		delete( positions )
	}
	lru_free( & shape_cache.state )

	delete( glyph_buffer.draw_list.vertices )
	delete( glyph_buffer.draw_list.indices )
	delete( glyph_buffer.draw_list.calls )

	delete( glyph_buffer.clear_draw_list.vertices )
	delete( glyph_buffer.clear_draw_list.indices )
	delete( glyph_buffer.clear_draw_list.calls )

	delete_soa( glyph_buffer.glyph_pack)
	delete( glyph_buffer.oversized)
	delete( glyph_buffer.to_cache)
	delete( glyph_buffer.cached)

	delete( glyph_buffer.shape_gen_scratch )
	delete( glyph_buffer.batch_cache.table )

	shaper_shutdown( & shaper_ctx )
	parser_shutdown( & parser_ctx )
}

load_font :: proc( ctx : ^Context, label : string, data : []byte, size_px : f32, glyph_curve_quality : u32 = 0 ) -> (font_id : Font_ID)
{
	profile(#procedure)
	assert( ctx != nil )
	assert( len(data) > 0 )
	using ctx
	context.allocator = backing

	id : i32 = -1

	for index : i32 = 0; index < i32(len(entries)); index += 1 {
		if entries[index].used do continue
		id = index
		break
	}
	if id == -1 {
		append_elem( & entries, Entry {})
		id = cast(i32) len(entries) - 1
	}
	assert( id >= 0 && id < i32(len(entries)) )

	entry := & entries[ id ]
	{
		entry.used = true

		profile_begin("calling loaders")
		entry.parser_info = parser_load_font( & parser_ctx, label, data )
		entry.shaper_info = shaper_load_font( & shaper_ctx, label, data )
		profile_end()

		ascent, descent, line_gap := parser_get_font_vertical_metrics(entry.parser_info)
		entry.ascent   = f32(ascent)
		entry.descent  = f32(descent)
		entry.line_gap = f32(line_gap)

		if glyph_curve_quality == 0 {
			entry.curve_quality = f32(ctx.default_curve_quality)
		}
		else {
			entry.curve_quality = f32(glyph_curve_quality)
		}
	}
	entry.id = Font_ID(id)
	ctx.entries[ id ].id = Font_ID(id)

	font_id = Font_ID(id)
	return
}

unload_font :: proc( ctx : ^Context, font : Font_ID )
{
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )
	context.allocator = ctx.backing

	using ctx
	entry     := & ctx.entries[ font ]
	entry.used = false

	parser_unload_font( & entry.parser_info )
	shaper_unload_font( & entry.shaper_info )
}

//#endregion("lifetime")

//#region("drawing")

configure_snap :: #force_inline proc( ctx : ^Context, snap_width, snap_height : u32 ) {
	assert( ctx != nil )
	ctx.snap_width  = f32(snap_width)
	ctx.snap_height = f32(snap_height)
}

get_cursor_pos   :: #force_inline proc( ctx : ^Context                  ) -> Vec2 { assert(ctx != nil); return ctx.cursor_pos     }
set_alpha_scalar :: #force_inline proc( ctx : ^Context, scalar : f32    )         { assert(ctx != nil); ctx.alpha_scalar = scalar }
set_colour       :: #force_inline proc( ctx : ^Context, colour : Colour )         { assert(ctx != nil); ctx.colour       = colour }

draw_text :: #force_inline proc( ctx : ^Context, font : Font_ID, px_size : f32, position, scale : Vec2, text_utf8 : string ) -> b32
{
	profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )
	assert( len(text_utf8) > 0 )

	ctx.cursor_pos = {}

	position := position
	position.x = ceil(position.x * ctx.snap_width ) / ctx.snap_width
	position.y = ceil(position.y * ctx.snap_height) / ctx.snap_height

	colour   := ctx.colour
	colour.a  = 1.0 + ctx.alpha_scalar

	// TODO(Ed): Test this.
	// px_size_scalar :: 2
	// px_size        := px_size * px_size_scalar
	// scale          := scale   / px_size_scalar

	entry := ctx.entries[ font ]
	font_scale    := parser_scale( entry.parser_info, px_size )
	shape         := shaper_shape_text_cached( text_utf8, & ctx.shaper_ctx, & ctx.shape_cache, font, entry, px_size, font_scale, shaper_shape_text_uncached_advanced )
	ctx.cursor_pos = generate_shape_draw_list( & ctx.draw_list, shape, & ctx.atlas, & ctx.glyph_buffer, colour, entry, font_scale, position, scale, ctx.snap_width, ctx.snap_height )

	return true
}

draw_text_no_snap :: #force_inline proc( ctx : ^Context, font : Font_ID, px_size : f32, position, scale : Vec2, text_utf8 : string ) -> b32
{
	profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )
	assert( len(text_utf8) > 0 )

	ctx.cursor_pos = {}

	colour   := ctx.colour
	colour.a  = 1.0 + ctx.alpha_scalar

	entry         := ctx.entries[ font ]
	font_scale    := parser_scale( entry.parser_info, px_size )
	shape         := shaper_shape_text_cached( text_utf8, & ctx.shaper_ctx, & ctx.shape_cache, font, entry, px_size, font_scale, shaper_shape_text_latin )
	ctx.cursor_pos = generate_shape_draw_list( & ctx.draw_list, shape, & ctx.atlas, & ctx.glyph_buffer, colour, entry, font_scale, position, scale, ctx.snap_width, ctx.snap_height )
	return true
}

// Resolve the shape and track it to reduce iteration overhead
draw_text_shape :: #force_inline proc( ctx : ^Context, font : Font_ID, px_size : f32, position, scale : Vec2, shape : Shaped_Text ) -> b32
{
	profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )
	position := position
	position.x = ceil(position.x * ctx.snap_width ) / ctx.snap_width
	position.y = ceil(position.y * ctx.snap_height) / ctx.snap_height

	colour   := ctx.colour
	colour.a  = 1.0 + ctx.alpha_scalar

	entry         := ctx.entries[ font ]
	font_scale    := parser_scale( entry.parser_info, px_size )
	ctx.cursor_pos = generate_shape_draw_list( & ctx.draw_list, shape, & ctx.atlas, & ctx.glyph_buffer, colour, entry, font_scale, position, scale, ctx.snap_width, ctx.snap_height )
	return true
}

// Resolve the shape and track it to reduce iteration overhead
draw_text_shape_no_snap :: #force_inline proc( ctx : ^Context, font : Font_ID, px_size : f32, position, scale : Vec2, shape : Shaped_Text ) -> b32
{
	profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )

	colour   := ctx.colour
	colour.a  = 1.0 + ctx.alpha_scalar

	entry := ctx.entries[ font ]
	font_scale     := parser_scale( entry.parser_info, px_size )
	ctx.cursor_pos  = generate_shape_draw_list( & ctx.draw_list, shape, & ctx.atlas, & ctx.glyph_buffer, colour, entry, font_scale, position, scale, ctx.snap_width, ctx.snap_height )
	return true
}

get_draw_list :: #force_inline proc( ctx : ^Context, optimize_before_returning := true ) -> ^Draw_List {
	assert( ctx != nil )
	if optimize_before_returning do optimize_draw_list( & ctx.draw_list, 0 )
	return & ctx.draw_list
}

get_draw_list_layer :: #force_inline proc( ctx : ^Context, optimize_before_returning := true ) -> (vertices : []Vertex, indices : []u32, calls : []Draw_Call) {
	assert( ctx != nil )
	if optimize_before_returning do optimize_draw_list( & ctx.draw_list, ctx.draw_layer.calls_offset )
	vertices = ctx.draw_list.vertices[ ctx.draw_layer.vertices_offset : ]
	indices  = ctx.draw_list.indices [ ctx.draw_layer.indices_offset  : ]
	calls    = ctx.draw_list.calls   [ ctx.draw_layer.calls_offset    : ]
	return
}

flush_draw_list :: #force_inline proc( ctx : ^Context ) {
	assert( ctx != nil )
	using ctx
	clear_draw_list( & draw_list )
	draw_layer.vertices_offset = 0
	draw_layer.indices_offset  = 0
	draw_layer.calls_offset    = 0
}

flush_draw_list_layer :: #force_inline proc( ctx : ^Context ) {
	assert( ctx != nil )
	using ctx
	draw_layer.vertices_offset = len(draw_list.vertices)
	draw_layer.indices_offset  = len(draw_list.indices)
	draw_layer.calls_offset    = len(draw_list.calls)
}

//#endregion("drawing")

//#region("metrics")

measure_text_size :: #force_inline proc( ctx : ^Context, font : Font_ID, px_size : f32, text_utf8 : string ) -> (measured : Vec2)
{
	// profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )

	entry      := ctx.entries[font]
	font_scale := parser_scale( entry.parser_info, px_size )
	shaped     := shaper_shape_text_cached( text_utf8, & ctx.shaper_ctx, & ctx.shape_cache, font, entry, px_size, font_scale, shaper_shape_text_uncached_advanced )
	return shaped.size
}

get_font_vertical_metrics :: #force_inline proc ( ctx : ^Context, font : Font_ID ) -> ( ascent, descent, line_gap : f32 )
{
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )

	entry  := & ctx.entries[ font ]
	// ascent_i32, descent_i32, line_gap_i32 := parser_get_font_vertical_metrics( entry.parser_info )

	ascent   = entry.ascent
	descent  = entry.descent
	line_gap = entry.line_gap
	return
}

//#endregion("metrics")

//#region("shaping")

shape_text_latin :: #force_inline proc( ctx : ^Context, font : Font_ID, px_size : f32, text_utf8 : string ) -> Shaped_Text
{
	profile(#procedure)
	assert( len(text_utf8) > 0 )
	entry := ctx.entries[ font ]
	font_scale := parser_scale( entry.parser_info, px_size )
	return shaper_shape_text_cached( text_utf8, & ctx.shaper_ctx, & ctx.shape_cache, font, entry, px_size, font_scale, shaper_shape_text_latin )
}

shape_text_advanced :: #force_inline proc( ctx : ^Context, font : Font_ID, px_size : f32, text_utf8 : string ) -> Shaped_Text
{
	profile(#procedure)
	assert( len(text_utf8) > 0 )
	entry := ctx.entries[ font ]
	font_scale := parser_scale( entry.parser_info, px_size )
	return shaper_shape_text_cached( text_utf8, & ctx.shaper_ctx, & ctx.shape_cache, font, entry, px_size, font_scale, shaper_shape_text_uncached_advanced )
}

// User handled shaped text. Will not be cached
shape_text_latin_uncached :: #force_inline proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : ^Entry, allocator := context.allocator ) -> Shaped_Text
{
	return {}
}

// User handled shaped text. Will not be cached
shape_text_advanced_uncahed :: #force_inline proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : ^Entry, allocator := context.allocator ) -> Shaped_Text
{
	return {}
}

//#endregion("shaping")

// Can be used with hot-reload
clear_atlas_region_caches :: proc(ctx : ^Context)
{
	lru_clear(& ctx.atlas.region_a.state)
	lru_clear(& ctx.atlas.region_b.state)
	lru_clear(& ctx.atlas.region_c.state)
	lru_clear(& ctx.atlas.region_d.state)

	ctx.atlas.region_a.next_idx = 0
	ctx.atlas.region_b.next_idx = 0
	ctx.atlas.region_c.next_idx = 0
	ctx.atlas.region_d.next_idx = 0
}

// Can be used with hot-reload
clear_shape_cache :: proc (ctx : ^Context)
{
	using ctx
	lru_clear(& shape_cache.state)
	for idx : i32 = 0; idx < cast(i32) cap(shape_cache.storage); idx += 1
	{
		stroage_entry := & shape_cache.storage[idx]
		using stroage_entry
		end_cursor_pos = {}
		size           = {}
		clear(& glyphs)
		clear(& positions)
		clear(& draw_list.calls)
		clear(& draw_list.indices)
		clear(& draw_list.vertices)
	}
	ctx.shape_cache.next_cache_id = 0
}
