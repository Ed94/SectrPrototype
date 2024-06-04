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
- Macro defines have been made into runtime parameters
*/
package VEFontCache

FontID  :: distinct i64
Glyph   :: distinct i32

Colour :: [4]f32
Vec2   :: [2]f32
Vec2i  :: [2]u32

AtlasRegionKind :: enum u8 {
	None = 0x00,
	A    = 0x41,
	B    = 0x42,
	C    = 0x43,
	D    = 0x44,
	E    = 0x45,
}

Vertex :: struct {
	pos  : Vec2,
	u, v : f32,
}

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

	curve_quality  : u32,
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
	over_sample   : Vec2,
	buffer_batch  : u32,
	draw_padding  : u32,
}

InitGlyphDrawParams_Default :: InitGlyphDrawParams {
	over_sample   = { 4, 4 },
	buffer_batch  = 4,
	draw_padding  = InitAtlasParams_Default.glyph_padding,
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
	curve_quality               : u32 = 6,
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

	ctx.curve_quality = curve_quality

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

	atlas.width         = atlas_params.width
	atlas.height        = atlas_params.height
	atlas.glyph_padding = atlas_params.glyph_padding

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
		over_sample   = glyph_draw_params.over_sample
		buffer_batch  = glyph_draw_params.buffer_batch
		buffer_width  = region_d.width  * u32(over_sample.x) * buffer_batch
		buffer_height = region_d.height * u32(over_sample.y)
		draw_padding  = glyph_draw_params.draw_padding

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
		for vertex in shape
		{
			if vertex.type == .Move {
				logf("move_to %d %d\n", vertex.x, vertex.y )
			}
			else if vertex.type == .Line {
				logf("line_to %d %d\n", vertex.x, vertex.y )
			}
			else if vertex.type == .Curve {
				logf("curve_to %d %d through %d %d\n", vertex.x, vertex.y, vertex.contour_x0, vertex.contour_y0 )
			}
			else if vertex.type == .Cubic {
				logf("cubic_to %d %d through %d %d and %d %d\n",
					vertex.x, vertex.y,
					vertex.contour_x0, vertex.contour_y0,
					vertex.contour_x1, vertex.contour_y1 )
			}
		}
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
	for edge in shape	do switch edge.type
	{
		case .Move:
			if path.num > 0 {
				draw_filled_path( & ctx.draw_list, outside, array_to_slice(path), scale, translate )
			}
			clear(path)
			fallthrough

		case .Line:
			append( & path, Vec2{ f32(edge.x), f32(edge.y) })

		case .Curve:
			assert( path.num > 0 )
			p0 := path.data[ path.num - 1 ]
			p1 := Vec2{ f32(edge.contour_x0), f32(edge.contour_y0) }
			p2 := Vec2{ f32(edge.x), f32(edge.y) }

			step  := 1.0 / f32(ctx.curve_quality)
			alpha := step
			for index := i32(0); index < i32(ctx.curve_quality); index += 1 {
				append( & path, eval_point_on_bezier3( p0, p1, p2, alpha ))
				alpha += step
			}

		case .Cubic:
			assert( path.num > 0 )
			p0 := path.data[ path.num - 1]
			p1 := Vec2{ f32(edge.contour_x0), f32(edge.contour_y0) }
			p2 := Vec2{ f32(edge.contour_x1), f32(edge.contour_y1) }
			p3 := Vec2{ f32(edge.x), f32(edge.y) }

			step  := 1.0 / f32(ctx.curve_quality)
			alpha := step
			for index := i32(0); index < i32(ctx.curve_quality); index += 1 {
				append( & path, eval_point_on_bezier4( p0, p1, p2, p3, alpha ))
				alpha += step
			}

		case .None:
			assert(false, "Unknown edge type or invalid")
	}
	if path.num > 0 {
		draw_filled_path( & ctx.draw_list, outside, array_to_slice(path), scale, translate )
	}

	// Note(Original Author): Apend the draw call
	draw.end_index = cast(u32) ctx.draw_list.indices.num
	if draw.end_index > draw.start_index {
		append(& ctx.draw_list.calls, draw)
	}

	parser_free_shape( entry.parser_info, shape )
	return false
}

decide_codepoint_region :: proc( ctx : ^Context, entry : ^Entry, glyph_index : Glyph
) -> (region : AtlasRegionKind, state : ^LRU_Cache, next_idx : ^u32, over_sample : ^Vec2)
{
	if parser_is_glyph_empty( entry.parser_info, glyph_index ) {
		region = .None
	}

	bounds_0, bounds_1 := parser_get_glyph_box( entry.parser_info, glyph_index )
	bounds_width  := bounds_1.x - bounds_0.x
	bounds_height := bounds_1.y - bounds_0.y

	atlas := & ctx.atlas

	bounds_width_scaled  := cast(u32) (f32(bounds_width)  * entry.size_scale + 2.0 * f32(atlas.glyph_padding))
	bounds_height_scaled := cast(u32) (f32(bounds_height) * entry.size_scale + 2.0 * f32(atlas.glyph_padding))

	if bounds_width_scaled <= atlas.region_a.width && bounds_height_scaled <= atlas.region_a.height
	{
		// Region A for small glyphs. These are good for things such as punctuation.
		region   = .A
		state    = & atlas.region_a.state
		next_idx = & atlas.region_a.next_idx
	}
	else if bounds_width_scaled <= atlas.region_b.width && bounds_height_scaled <= atlas.region_b.height
	{
		// Region B for tall glyphs. These are good for things such as european alphabets.
		region   = .B
		state    = & atlas.region_b.state
		next_idx = & atlas.region_b.next_idx
	}
	else if bounds_width_scaled <= atlas.region_c.width && bounds_height_scaled <= atlas.region_c.height
	{
		// Region C for big glyphs. These are good for things such as asian typography.
		region   = .C
		state    = & atlas.region_c.state
		next_idx = & atlas.region_c.next_idx
	}
	else if bounds_width_scaled <= atlas.region_d.width && bounds_height_scaled <= atlas.region_d.height
	{
		// Region D for huge glyphs. These are good for things such as titles and 4k.
		region   = .D
		state    = & atlas.region_d.state
		next_idx = & atlas.region_d.next_idx
	}
	else if bounds_width_scaled <= atlas.buffer_width && bounds_height_scaled <= atlas.buffer_height
	{
		// Region 'E' for massive glyphs. These are rendered uncached and un-oversampled.
		region   = .E
		state    = nil
		next_idx = nil
		if bounds_width_scaled <= atlas.buffer_width / 2 && bounds_height_scaled <= atlas.buffer_height / 2
		{
			(over_sample^) = { 2.0, 2.0 }
		}
		else
		{
			(over_sample^) = { 1.0, 1.0 }
		}
		return
	}
	else {
		region = .None
		return
	}

	assert(state    != nil)
	assert(next_idx != nil)
	return
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
