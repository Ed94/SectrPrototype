/*
A port of (https://github.com/hypernewbie/VEFontCache) to Odin.

Status:
This port is heavily tied to the grime package in SectrPrototype.

TODO(Ed): Make an idiomatic port of this for Odin (or just dupe the data structures...)

Changes:
- Support for freetype(WIP), only supports processing true type formatted data however
- Font Parser & Glyph Shaper are abstracted to their own interface
- Font Face parser info stored separately from entries
- ve_fontcache_loadfile not ported (just use odin's core:os or os2), then call load_font
*/
package VEFontCache

FontID  :: distinct i64
Glyph   :: distinct i32

Colour :: [4]f32
Vec2   :: [2]f32
Vec2i  :: [2]u32

AtlasRegionKind :: enum {
	A = 0,
	B = 1,
	C = 2,
	D = 3,
	E = 4,
}

Vertex :: struct {
	pos  : Vec2,
	u, v : f32,
}

// GlyphDrawBuffer :: struct {
// 	over_sample : Vec2,

// 	batch   : i32,
// 	width   : i32,
// 	height  : i32,
// 	padding : i32,
// }

ShapedText :: struct {
	glyphs         : Array(Glyph),
	positions      : Array(Vec2),
	end_cursor_pos : Vec2,
}

ShapedTextCache :: struct {
	storage       : Array(ShapedText),
	state         : LRU_Cache,
	next_cache_id : i32,
}

Entry :: struct {
	parser_info : ^ParserFontInfo,
	shaper_info : ^ShaperInfo,
	id          : FontID,
	used        : b32,

	// Note(Ed) : Not sure how I feel about the size specification here
	// I rather have different size glyphs for a font on demand (necessary for the canvas UI)
	// Might be mis-understaning how this cache works...
	size        : f32,
	size_scale  : f32,
}

Entry_Default :: Entry {
	id         = 0,
	used       = false,
	size       = 24.0,
	size_scale = 1.0,
}

Context :: struct {
	backing : Allocator,

	parser_kind : ParserKind,
	parser_ctx  : ParserContext,
	shaper_ctx  : ShaperContext,

	entries : Array(Entry),

	temp_path           : Array(Vec2),
	temp_codepoint_seen : HMapChained(bool),

	snap_width  : u32,
	snap_height : u32,

	colour     : Colour,
	cursor_pos : Vec2,

	draw_list   : DrawList,
	atlas       : Atlas,
	shape_cache : ShapedTextCache,

	text_shape_adv : b32,

	debug_print_verbose : b32
}

font_key_from_label :: proc( label : string ) -> u64 {
	hash : u64
	for str_byte in transmute([]byte) label {
		hash = ((hash << 5) + hash) + u64(str_byte)
	}
	return hash
}

InitAtlasRegionParams :: struct {
	width  : u32,
	height : u32,
}

InitAtlasParams :: struct {
	width           : u32,
	height          : u32,
	glyph_padding   : u32,

	region_a : InitAtlasRegionParams,
	region_b : InitAtlasRegionParams,
	region_c : InitAtlasRegionParams,
	region_d : InitAtlasRegionParams,
}

InitAtlasParams_Default :: InitAtlasParams {
	width         = 4 * Kilobyte,
	height        = 2 * Kilobyte,
	glyph_padding = 1,

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

InitGlyphDrawParams :: struct {
	over_sample  : Vec2i,
	buffer_batch : u32,
	padding      : u32,
}

InitGlyphDrawParams_Default :: InitGlyphDrawParams {
	over_sample  = { 4, 4 },
	buffer_batch = 4,
	padding      = InitAtlasParams_Default.glyph_padding,
}

InitShapeCacheParams :: struct {
	capacity       : u32,
	reserve_length : u32,
}

InitShapeCacheParams_Default :: InitShapeCacheParams {
	capacity       = 256,
	reserve_length = 64,
}

// ve_fontcache_init
init :: proc( ctx : ^Context,
	allocator                   := context.allocator,
	atlas_params                := InitAtlasParams_Default,
	glyph_draw_params           := InitGlyphDrawParams_Default,
	shape_cache_params          := InitShapeCacheParams_Default,
	advance_snap_smallfont_size : u32 = 12,
	entires_reserve             : u32 = Kilobyte,
	temp_path_reserve           : u32 = Kilobyte,
	temp_codepoint_seen_reserve : u32 = 4 * Kilobyte,
)
{
	assert( ctx != nil, "Must provide a valid context" )
	using ctx

	ctx.backing       = allocator
	context.allocator = ctx.backing

	error : AllocatorError
	entries, error = make( Array(Entry), u64(entires_reserve) )
	assert(error == .None, "VEFontCache.init : Failed to allocate entries")

	temp_path, error = make( Array(Vec2), u64(temp_path_reserve) )
	assert(error == .None, "VEFontCache.init : Failed to allocate temp_path")

	temp_codepoint_seen, error = make( HMapChained(bool), hmap_closest_prime( uint(temp_codepoint_seen_reserve)) )
	assert(error == .None, "VEFontCache.init : Failed to allocate temp_path")

	draw_list.vertices, error = make( Array(Vertex), 4 * Kilobyte )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.vertices")

	draw_list.indices, error = make( Array(u32), 8 * Kilobyte )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.indices")

	draw_list.calls, error = make( Array(DrawCall), 512 )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.calls")

	init_atlas_region :: proc( region : ^AtlasRegion, params : InitAtlasParams, region_params : InitAtlasRegionParams ) {
		using region

		next_idx = 0;
		width    = region_params.width
		height   = region_params.height
		size = {
			params.width  / 4,
			params.height / 2,
		}
		capacity = {
			size.x / width,
			size.y / height,
		}

		error : AllocatorError
		// state.cache, error = make( HMapChained(LRU_Link), uint(capacity.x * capacity.y) )
		// assert( error == .None, "VEFontCache.init_atlas_region : Failed to allocate state.cache")
		LRU_init( & state, capacity.x * capacity.y )
	}
	init_atlas_region( & atlas.region_a, atlas_params, atlas_params.region_a )
	init_atlas_region( & atlas.region_b, atlas_params, atlas_params.region_b )
	init_atlas_region( & atlas.region_c, atlas_params, atlas_params.region_c )
	init_atlas_region( & atlas.region_d, atlas_params, atlas_params.region_d )

	atlas.region_b.offset.y = atlas.region_a.size.y
	atlas.region_c.offset.x = atlas.region_a.size.x
	atlas.region_d.offset.x = atlas.width / 2

	LRU_init( & shape_cache.state, shape_cache_params.capacity )
	for idx : u32 = 0; idx < shape_cache_params.capacity; idx += 1 {
		stroage_entry := & shape_cache.storage.data[idx]
		using stroage_entry
		glyphs, error = make( Array(Glyph), cast(u64) shape_cache_params.reserve_length )
		assert( error != .None, "VEFontCache.init : Failed to allocate glyphs array for shape cache storage" )

		positions, error = make( Array(Vec2), cast(u64) shape_cache_params.reserve_length )
		assert( error != .None, "VEFontCache.init : Failed to allocate positions array for shape cache storage" )
	}

	// Note(From original author): We can actually go over VE_FONTCACHE_GLYPHDRAW_BUFFER_BATCH batches due to smart packing!
	{
		using atlas
		draw_list.calls, error = make( Array(DrawCall), cast(u64) glyph_draw_params.buffer_batch * 2 )
		assert( error != .None, "VEFontCache.init : Failed to allocate calls for draw_list" )

		draw_list.indices, error = make( Array(u32), cast(u64) glyph_draw_params.buffer_batch * 2 * 6 )
		assert( error != .None, "VEFontCache.init : Failed to allocate indices array for draw_list" )

		draw_list.vertices, error = make( Array(Vertex), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error != .None, "VEFontCache.init : Failed to allocate vertices array for draw_list" )

		clear_draw_list.calls, error = make( Array(DrawCall), cast(u64) glyph_draw_params.buffer_batch * 2 )
		assert( error != .None, "VEFontCache.init : Failed to allocate calls for calls for clear_draw_list" )

		clear_draw_list.indices, error = make( Array(u32), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error != .None, "VEFontCache.init : Failed to allocate calls for indices array for clear_draw_list" )

		clear_draw_list.vertices, error = make( Array(Vertex), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error != .None, "VEFontCache.init : Failed to allocate vertices array for clear_draw_list" )
	}

	parser_init( & parser_ctx )
	shaper_init( & shaper_ctx )
}

// ve_foncache_shutdown
shutdown :: proc( ctx : ^Context )
{
	assert( ctx != nil )
	context.allocator = ctx.backing
	using ctx

	for & entry in array_to_slice(entries) {
		unload_font( ctx, entry.id )
	}

	shaper_shutdown( & shaper_ctx )
}

// ve_fontcache_load
load_font :: proc( ctx : ^Context, label : string, data : []byte, size_px : f32 ) -> FontID
{
	assert( ctx != nil )
	assert( len(data) > 0 )
	using ctx

	id : i32 = -1
	for index : i32 = 0; index < i32(entries.num); index += 1 {
		if entries.data[index].used do continue
		id = index
		break
	}
	if id == -1 {
		append( & entries, Entry {})
		id = cast(i32) entries.num - 1
	}
	assert( id >= 0 && id < i32(entries.num) )

	entry := & entries.data[ id ]
	{
		using entry
		parser_info = parser_load_font( parser_ctx, label, data )
		assert( parser_info != nil, "VEFontCache.load_font: Failed to load font info from parser" )

		size = size_px
		size_scale = size_px < 0.0 ?                             \
			parser_scale_for_pixel_height( parser_info, -size_px ) \
		: parser_scale_for_mapping_em_to_pixels( parser_info, size_px )

		used = true

		shaper_info = shaper_load_font( & shaper_ctx, label, data, transmute(rawptr) id )
		assert( shaper_info != nil, "VEFontCache.load_font: Failed to load font from shaper")

		return id
	}
}

// ve_fontcache_unload
unload_font :: proc( ctx : ^Context, font : FontID )
{
	assert( ctx != nil )
	assert( font >= 0 && u64(font) < ctx.entries.num )

	using ctx
	entry     := & entries.data[ font ]
	entry.used = false

	parser_unload_font( entry.parser_info )
	shaper_unload_font( entry.shaper_info )
}

// ve_fontcache_configure_snap
configure_snap :: proc( ctx : ^Context, snap_width, snap_height : u32 ) {
	assert( ctx != nil )
	ctx.snap_width  = snap_width
	ctx.snap_height = snap_height
}

// ve_fontcache_drawlist
get_draw_list :: proc( ctx : ^Context ) -> ^DrawList {
	assert( ctx != nil )
	return & ctx.draw_list
}

// ve_fontcache_clear_drawlist
clear_draw_list :: proc( draw_list : ^DrawList ) {
	clear( draw_list.calls )
	clear( draw_list.indices )
	clear( draw_list.vertices )
}

// ve_fontcache_merge_drawlist
merge_draw_list :: proc( dst, src : ^DrawList )
{
	error : AllocatorError

	v_offset := cast(u32) dst.vertices.num
	// for index : u32 = 0; index < cast(u32) src.vertices.num; index += 1 {
	// 	error = append( & dst.vertices, src.vertices.data[index] )
	// 	assert( error == .None )
	// }
	error = append( & dst.vertices, src.vertices )
	assert( error == .None )

	i_offset := cast(u32) dst.indices.num
	for index : u32 = 0; index < cast(u32) src.indices.num; index += 1 {
		error = append( & dst.indices, src.indices.data[index] + v_offset )
		assert( error == .None )
	}

	for index : u32 = 0; index < cast(u32) src.calls.num; index += 1 {
		src_call := src.calls.data[ index ]
		src_call.start_index += i_offset
		src_call.end_index   += i_offset
		append( & dst.calls, src_call )
		assert( error == .None )
	}
}

// ve_fontcache_flush_drawlist
flush_draw_list :: proc( ctx : ^Context ) {
	assert( ctx != nil )
	clear_draw_list( & ctx.draw_list )
}

// For a provided alpha value,
// allows the function to calculate the position of a point along the curve at any given fraction of its total length
// ve_fontcache_eval_bezier (quadratic)
eval_point_on_bezier3 :: proc( p0, p1, p2 : Vec2, alpha : f32 ) -> Vec2
{
	starting_point := p0 * (1 - alpha) * (1 - alpha)
	control_point  := p1 * 2.0 * (1 - alpha)
	end_point      := p2 * alpha * alpha

	point := starting_point + control_point + end_point
	return point
}

// For a provided alpha value,
// allows the function to calculate the position of a point along the curve at any given fraction of its total length
// ve_fontcache_eval_bezier (cubic)
eval_point_on_bezier4 :: proc( p0, p1, p2, p3 : Vec2, alpha : f32 ) -> Vec2
{
	start_point := p0 * (1 - alpha) * (1 - alpha) * (1 - alpha)
	control_a   := p1 * 3 * (1 - alpha) * (1 - alpha) * alpha
	control_b   := p2 * 3 * (1 - alpha) * alpha * alpha
	end_point   := p3 * alpha * alpha * alpha

	point := start_point + control_a + control_b + end_point
	return point
}

// Constructs a triangle fan to fill a shape using the provided path
// outside_point represents the center point of the fan.
//
// Note(Original Author):
// WARNING: doesn't actually append drawcall; caller is responsible for actually appending the drawcall.
// ve_fontcache_draw_filled_path
draw_filled_path :: proc( draw_list : ^DrawList, outside_point : Vec2, path : []Vec2,
	scale     := Vec2 { 1, 1 },
	translate := Vec2 { 0, 0 },
	debug_print_verbose : b32 = false
)
{
	if debug_print_verbose
	{
		log("outline_path: \n")
		for point in path {
			logf("    %.2f %.2f\n", point.x * scale )
		}
	}

	v_offset := cast(u32) draw_list.vertices.num
	for point in path {
		vertex := Vertex {
			pos = point * scale + translate,
			u = 0,
			v = 0,
		}
		append( & draw_list.vertices, vertex )
	}

	outside_vertex := cast(u32) draw_list.vertices.num
	{
		vertex := Vertex {
			pos = outside_point * scale + translate,
			u = 0,
			v = 0,
		}
		append( & draw_list.vertices, vertex )
	}

	for index : u32 = 1; index < u32(len(path)); index += 1 {
		indices := & draw_list.indices
		append( indices, outside_vertex )
		append( indices, v_offset + index - 1 )
		append( indices, v_offset + index )
	}
}

blit_quad :: proc( draw_list : ^DrawList, p0, p1 : Vec2, uv0, uv1 : Vec2 )
{
	v_offset := cast(u32) draw_list.vertices.num

	vertex := Vertex {
		{p0.x, p0.y},
		uv0.x,
		uv0.y
	}
	append( & draw_list.vertices, vertex )
	vertex = Vertex {
		{p0.x, p1.y},
		uv0.x,
		uv1.y
	}
	append( & draw_list.vertices, vertex )
	vertex = Vertex {
		{p1.x, p0.y},
		uv1.x,
		uv0.y
	}
	append( & draw_list.vertices, vertex )
	vertex = Vertex {
		{p1.x, p1.y},
		uv1.x,
		uv1.y
	}
	append( & draw_list.vertices, vertex )

	quad_indices : []u32 = {
		0, 1, 2,
		2, 1, 3
	}
	for index : i32 = 0; index < 6; index += 1 {
		append( & draw_list.indices, v_offset + quad_indices[ index ] )
	}
}

cache_glyph :: proc( ctx : ^Context, font : FontID, glyph_index : Glyph, scale, translate : Vec2  ) -> b32
{
	assert( ctx != nil )
	assert( font >= 0 && u64(font) < ctx.entries.num )
	entry := & ctx.entries.data[ font ]
	if glyph_index == Glyph(0) {
		// Note(Original Author): Glyph not in current hb_font
		return false
	}

	// No shpae to retrieve
	if parser_is_glyph_empty( entry.parser_info, glyph_index ) do return true

	// Retrieve the shape definition from the parser.
	shape, error := parser_get_glyph_shape( entry.parser_info, glyph_index )
	assert( error == .None )
	if len(shape) == 0 {
		return false
	}

	if ctx.debug_print_verbose
	{
		log( "shape: \n")
		// for 
	}

	/*
	Note(Original Author):
	We need a random point that is outside our shape. We simply pick something diagonally across from top-left bound corner.
	Note that this outside point is scaled alongside the glyph in ve_fontcache_draw_filled_path, so we don't need to handle that here.
	*/
	bounds_0, bounds_1 := parser_get_glyph_box( entry.parser_info, glyph_index )

	outside := Vec2 {
		f32(bounds_0.x - 21),
		f32(bounds_0.y - 33),
	}

	// Note(Original Author): Figure out scaling so it fits within our box.
	draw : DrawCall
	draw.pass        = FrameBufferPass.Glyph
	draw.start_index = u32(ctx.draw_list.indices.num)

	// Note(Original Author);
	// Draw the path using simplified version of https://medium.com/@evanwallace/easy-scalable-text-rendering-on-the-gpu-c3f4d782c5ac.
	// Instead of involving fragment shader code we simply make use of modern GPU ability to crunch triangles and brute force curve definitions.
	path := ctx.temp_path
	clear(path)
	for vertex in shape {
		
	}

	return false
}

decide_codepoint_region :: proc() -> AtlasRegionKind
{
	return {}
}

flush_glyph_buffer_to_atlas :: proc()
{

}

screenspace_x_form :: proc()
{

}

textspace_x_form :: proc()
{

}

atlas_bbox :: proc()
{

}

cache_glyph_to_atlas :: proc()
{

}

shape_text_uncached :: proc()
{

}

ELFhash64 :: proc()
{

}

shape_text_cached :: proc()
{

}

directly_draw_massive_glyph :: proc()
{

}

empty :: proc()
{

}

draw_cached_glyph :: proc()
{

}

reset_batch_codepoint_state :: proc()
{

}

can_batch_glyph :: proc()
{

}

draw_text_batch :: proc()
{

}

draw_text :: proc()
{

}

get_cursor_pos :: proc()
{

}

optimize_draw_list :: proc()
{

}

set_colour :: proc()
{

}
