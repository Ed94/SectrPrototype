/*
A port of (https://github.com/hypernewbie/VEFontCache) to Odin.

Status:
This port is heavily tied to the grime package in SectrPrototype.

TODO(Ed): Make an idiomatic port of this for Odin (or just dupe the data structures...)

Changes:
- Support for freetype(WIP)
- Font Parser & Glyph Shaper are abstracted to their own interface
- Font Face parser info stored separately from entries
- ve_fontcache_loadfile not ported (just use odin's core:os or os2), then call load_font
- Macro defines have been made into runtime parameters
*/
package VEFontCache

import "core:math"
import "core:mem"

Advance_Snap_Smallfont_Size :: 12

FontID  :: distinct i64
Glyph   :: distinct i32

Colour :: [4]f32
Vec2   :: [2]f32
Vec2i  :: [2]u32

AtlasRegionKind :: enum u8 {
	None   = 0x00,
	A      = 0x41,
	B      = 0x42,
	C      = 0x43,
	D      = 0x44,
	E      = 0x45,
	Ignore = 0xFF, // ve_fontcache_cache_glyph_to_atlas uses a -1 value in clear draw call
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
	parser_info : ParserFontInfo,
	shaper_info : ShaperInfo,
	id          : FontID,
	used        : b32,
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

	temp_path               : Array(Vec2),
	temp_codepoint_seen     : HMapChained(bool),
	temp_codepoint_seen_num : u32,

	snap_width  : u32,
	snap_height : u32,

	colour     : Colour,
	cursor_pos : Vec2,

	draw_list   : DrawList,
	atlas       : Atlas,
	shape_cache : ShapedTextCache,

	curve_quality  : u32,
	text_shape_adv : b32,

	debug_print         : b32,
	debug_print_verbose : b32,
}

get_cursor_pos :: proc( ctx : ^Context                  ) -> Vec2 { return ctx.cursor_pos }
set_colour     :: proc( ctx : ^Context, colour : Colour )         { ctx.colour = colour }

font_glyph_lru_code :: #force_inline proc( font : FontID, glyph_index : Glyph ) -> (lru_code : u64)
{
	lru_code = u64(glyph_index) + ( ( 0x100000000 * u64(font) ) & 0xFFFFFFFF00000000 )
	return
}

font_key_from_label :: #force_inline proc( label : string ) -> u64 {
	hash : u64
	for str_byte in transmute([]byte) label {
		hash = ((hash << 8) + hash) + u64(str_byte)
	}
	return hash
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

screenspace_x_form :: proc( position, scale : ^Vec2, width, height : f32 ) {
	scale.x    = (scale.x / width ) * 2.0
	scale.y    = (scale.y / height) * 2.0
	position.x = position.x * (2.0 / width) - 1.0
	position.y = position.y * (2.0 / width) - 1.0
}

textspace_x_form :: proc( position, scale : ^Vec2, width, height : f32 ) {
	position.x /= width
	position.y /= height
	scale.x    /= width
	scale.y    /= height
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
init :: proc( ctx : ^Context, parser_kind : ParserKind,
	allocator                   := context.allocator,
	atlas_params                := InitAtlasParams_Default,
	glyph_draw_params           := InitGlyphDrawParams_Default,
	shape_cache_params          := InitShapeCacheParams_Default,
	curve_quality               : u32 = 6,
	entires_reserve             : u32 = Kilobyte,
	temp_path_reserve           : u32 = Kilobyte,
	temp_codepoint_seen_reserve : u32 = 512,
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

	shape_cache.storage, error = make( Array(ShapedText), u64(shape_cache_params.reserve_length) )
	assert(error == .None, "VEFontCache.init : Failed to allocate shape_cache.storage")

	for idx : u32 = 0; idx < shape_cache_params.capacity; idx += 1 {
		stroage_entry := & shape_cache.storage.data[idx]
		using stroage_entry
		glyphs, error = make( Array(Glyph), cast(u64) shape_cache_params.reserve_length )
		assert( error == .None, "VEFontCache.init : Failed to allocate glyphs array for shape cache storage" )

		positions, error = make( Array(Vec2), cast(u64) shape_cache_params.reserve_length )
		assert( error == .None, "VEFontCache.init : Failed to allocate positions array for shape cache storage" )
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
		assert( error == .None, "VEFontCache.init : Failed to allocate calls for draw_list" )

		draw_list.indices, error = make( Array(u32), cast(u64) glyph_draw_params.buffer_batch * 2 * 6 )
		assert( error == .None, "VEFontCache.init : Failed to allocate indices array for draw_list" )

		draw_list.vertices, error = make( Array(Vertex), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error == .None, "VEFontCache.init : Failed to allocate vertices array for draw_list" )

		clear_draw_list.calls, error = make( Array(DrawCall), cast(u64) glyph_draw_params.buffer_batch * 2 )
		assert( error == .None, "VEFontCache.init : Failed to allocate calls for calls for clear_draw_list" )

		clear_draw_list.indices, error = make( Array(u32), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error == .None, "VEFontCache.init : Failed to allocate calls for indices array for clear_draw_list" )

		clear_draw_list.vertices, error = make( Array(Vertex), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error == .None, "VEFontCache.init : Failed to allocate vertices array for clear_draw_list" )
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

// ve_fontcache_configure_snap
configure_snap :: proc( ctx : ^Context, snap_width, snap_height : u32 ) {
	assert( ctx != nil )
	ctx.snap_width  = snap_width
	ctx.snap_height = snap_height
}

// ve_fontcache_load
load_font :: proc( ctx : ^Context, label : string, data : []byte, size_px : f32 ) -> FontID
{
	assert( ctx != nil )
	assert( len(data) > 0 )
	using ctx
	context.allocator = backing

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
		parser_info = parser_load_font( & parser_ctx, label, data )
		// assert( parser_info != nil, "VEFontCache.load_font: Failed to load font info from parser" )

		size = size_px
		size_scale = size_px < 0.0 ?                             \
			parser_scale_for_pixel_height( & parser_info, -size_px ) \
		: parser_scale_for_mapping_em_to_pixels( & parser_info, size_px )
		// size_scale = 1.0

		used = true

		shaper_info = shaper_load_font( & shaper_ctx, label, data, transmute(rawptr) id )
		// assert( shaper_info != nil, "VEFontCache.load_font: Failed to load font from shaper")

		return id
	}
}

// ve_fontcache_unload
unload_font :: proc( ctx : ^Context, font : FontID )
{
	assert( ctx != nil )
	assert( font >= 0 && u64(font) < ctx.entries.num )
	context.allocator = ctx.backing

	using ctx
	entry     := & entries.data[ font ]
	entry.used = false

	parser_unload_font( & entry.parser_info )
	shaper_unload_font( & entry.shaper_info )
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
	if parser_is_glyph_empty( & entry.parser_info, glyph_index ) do return true

	// Retrieve the shape definition from the parser.
	shape, error := parser_get_glyph_shape( & entry.parser_info, glyph_index )
	assert( error == .None )
	if len(shape) == 0 {
		return false
	}

	if ctx.debug_print_verbose
	{
		log( "shape:")
		for vertex in shape
		{
			if vertex.type == .Move {
				logf("move_to %d %d", vertex.x, vertex.y )
			}
			else if vertex.type == .Line {
				logf("line_to %d %d", vertex.x, vertex.y )
			}
			else if vertex.type == .Curve {
				logf("curve_to %d %d through %d %d", vertex.x, vertex.y, vertex.contour_x0, vertex.contour_y0 )
			}
			else if vertex.type == .Cubic {
				logf("cubic_to %d %d through %d %d and %d %d",
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
	bounds_0, bounds_1 := parser_get_glyph_box( & entry.parser_info, glyph_index )

	outside := Vec2 {
		f32(bounds_0.x - 21),
		f32(bounds_0.y - 33),
	}

	// Note(Original Author): Figure out scaling so it fits within our box.
	draw := DrawCall_Default
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

	parser_free_shape( & entry.parser_info, shape )
	return false
}

cache_glyph_to_atlas :: proc( ctx : ^Context, font : FontID, glyph_index : Glyph )
{
	assert( ctx != nil )
	assert( font >= 0 && font < FontID(ctx.entries.num) )
	entry := & ctx.entries.data[ font ]

	if glyph_index == 0 do return
	if parser_is_glyph_empty( & entry.parser_info, glyph_index ) do return

	// Get hb_font text metrics. These are unscaled!
	bounds_0, bounds_1 := parser_get_glyph_box( & entry.parser_info, glyph_index )
	bounds_width  := bounds_1.x - bounds_0.x
	bounds_height := bounds_1.y - bounds_0.y

	region_kind, region, over_sample := decide_codepoint_region( ctx, entry, glyph_index )

	// E region is special case and not cached to atlas.
	if region_kind == .None || region_kind == .E do return

	// Grab an atlas LRU cache slot.
	lru_code    := font_glyph_lru_code( font, glyph_index )
	atlas_index := LRU_get( & region.state, lru_code )
	if atlas_index == -1
	{
		if region.next_idx < region.state.capacity
		{
			evicted         := LRU_put( & region.state, lru_code, i32(region.next_idx) )
			atlas_index      = i32(region.next_idx)
			region.next_idx += 1
			assert( evicted == lru_code )
		}
		else
		{
			next_evict_codepoint := LRU_get_next_evicted( & region.state )
			assert( next_evict_codepoint != 0xFFFFFFFFFFFFFFFF )

			atlas_index = LRU_peek( & region.state, next_evict_codepoint )
			assert( atlas_index != -1 )

			evicted := LRU_put( & region.state, lru_code, atlas_index )
			assert( evicted == next_evict_codepoint )
		}

		assert( LRU_get( & region.state, lru_code ) != - 1 )
	}

	atlas         := & ctx.atlas
	glyph_padding := cast(f32) atlas.glyph_padding

	if ctx.debug_print
	{
		@static debug_total_cached : i32 = 0
		logf("glyph %v%v( %v ) caching to atlas region %v at idx %d. %d total glyphs cached.\n", i32(glyph_index), rune(glyph_index), cast(rune) region_kind, atlas_index, debug_total_cached)
		debug_total_cached += 1
	}

	// Draw oversized glyph to update FBO
	glyph_draw_scale       := over_sample * entry.size_scale
	glyph_draw_translate   := Vec2 { f32(bounds_0.x), f32(bounds_0.y) } * glyph_draw_scale + Vec2{ glyph_padding, glyph_padding }
	glyph_draw_translate.x  = cast(f32) (i32(glyph_draw_translate.x + 0.9999999))
	glyph_draw_translate.y  = cast(f32) (i32(glyph_draw_translate.y + 0.9999999))

	// Allocate a glyph_update_FBO region
	gwidth_scaled_px := i32( f32(bounds_width) * f32(glyph_draw_scale.x) + 1.0 ) + i32(2 * over_sample.x * glyph_padding)
  if i32(atlas.update_batch_x + gwidth_scaled_px) >= i32(atlas.buffer_width) {
		flush_glyph_buffer_to_atlas( ctx )
	}

	// Calculate the src and destination regions
	dst_position, dst_width, dst_height := atlas_bbox( atlas, region_kind, u32(atlas_index) )
	dst_glyph_position := dst_position  //+ { glyph_padding, glyph_padding }
	dst_glyph_width    := f32(bounds_width)  * entry.size_scale
	dst_glyph_height   := f32(bounds_height) * entry.size_scale
	// dst_glyph_position -= { glyph_padding, glyph_padding }
	dst_glyph_width  += 2 * glyph_padding
	dst_glyph_height += 2 * glyph_padding

	dst_size       := Vec2 { dst_width, dst_height }
	dst_glyph_size := Vec2 { dst_glyph_width, dst_glyph_height }
	screenspace_x_form( & dst_glyph_position, & dst_glyph_size, f32(atlas.buffer_width), f32(atlas.buffer_height)  )
	screenspace_x_form( & dst_position,       & dst_size,       f32(atlas.buffer_width), f32(atlas.buffer_height) )

	src_position := Vec2 { f32(atlas.update_batch_x), 0 }
	src_size     := Vec2 {
		f32(bounds_width)  * glyph_draw_scale.x,
		f32(bounds_height) * glyph_draw_scale.y,
	}
	src_size += Vec2{1,1} * 2 * over_sample * glyph_padding
	textspace_x_form( & src_position, & src_size, f32(atlas.buffer_width), f32(atlas.buffer_height) )

	// Advance glyph_update_batch_x and calculate final glyph drawing transform
	glyph_draw_translate.x += f32(atlas.update_batch_x)
	atlas.update_batch_x   += gwidth_scaled_px
	screenspace_x_form( & glyph_draw_translate, & glyph_draw_scale, f32(atlas.buffer_width), f32(atlas.buffer_height))

	call : DrawCall
	{
		// Queue up clear on target region on atlas
		using call
		pass   = .Atlas
		region = .Ignore
		start_index = u32(atlas.clear_draw_list.indices.num)
		blit_quad( & atlas.clear_draw_list, dst_position, dst_position + dst_size, { 1.0, 1.0 }, { 1.0, 1.0 } )
		end_index = u32(atlas.clear_draw_list.indices.num)
		append( & atlas.clear_draw_list.calls, call )

		// Queue up a blit from glyph_update_FBO to the atlas
		region      = .None
		start_index = u32(atlas.draw_list.indices.num)
		blit_quad( & atlas.draw_list, dst_glyph_position, dst_glyph_position + dst_glyph_size, src_position, src_position + src_size )
		end_index = u32(atlas.draw_list.indices.num)
		append( & atlas.draw_list.calls, call )
	}

	// Render glyph to glyph_update_FBO
	cache_glyph( ctx, font, glyph_index, glyph_draw_scale, glyph_draw_translate )
}

is_empty :: proc( ctx : ^Context, entry : ^Entry, glyph_index : Glyph ) -> b32
{
	if glyph_index == 0 do return true
	if parser_is_glyph_empty( & entry.parser_info, glyph_index ) do return true
	return false
}

reset_batch_codepoint_state :: proc( ctx : ^Context ) {
	clear( ctx.temp_codepoint_seen )
	ctx.temp_codepoint_seen_num = 0
}

shape_text_cached :: proc( ctx : ^Context, font : FontID, text_utf8 : string ) -> ^ShapedText
{
	ELFhash64 :: proc( hash : ^u64, ptr : ^( $Type), count := 1 )
	{
		x     := u64(0)
		bytes := transmute( [^]byte) ptr
		for index : i32 = 0; index < i32( size_of(Type)); index += 1 {
			(hash^) = ((hash^) << 4 ) + u64(bytes[index])
			x       = (hash^) & 0xF000000000000000
			if x != 0 {
				(hash^) ~= (x >> 24)
			}
			(hash^) &= ~x
		}
	}


	font := font
  hash        := cast(u64) 0x9f8e00d51d263c24;
	ELFhash64( & hash, raw_data(transmute([]u8) text_utf8), len(text_utf8)  )
	ELFhash64( & hash, & font )

	shape_cache := & ctx.shape_cache
	state       := & ctx.shape_cache.state

	shape_cache_idx := LRU_get( state, hash )
	if shape_cache_idx == -1
	{
		if shape_cache.next_cache_id < i32(state.capacity) {
			shape_cache_idx = shape_cache.next_cache_id
			LRU_put( state, hash, shape_cache_idx )
		}
		else
		{
			next_evict_idx := LRU_get_next_evicted( state )
			assert( next_evict_idx != 0xFFFFFFFFFFFFFFFF )

			shape_cache_idx = LRU_peek( state, next_evict_idx )
			assert( shape_cache_idx != - 1 )

			LRU_put( state, hash, shape_cache_idx )
		}

		shape_text_uncached( ctx, font, & shape_cache.storage.data[ shape_cache_idx ], text_utf8 )
	}

	return & shape_cache.storage.data[ shape_cache_idx ]
}

shape_text_uncached :: proc( ctx : ^Context, font : FontID, output : ^ShapedText, text_utf8 : string )
{
	assert( ctx != nil )
	assert( font >= 0 && font < FontID(ctx.entries.num) )

	use_full_text_shape := ctx.text_shape_adv
	entry := & ctx.entries.data[ font ]

	clear( output.glyphs )
	clear( output.positions )

	ascent, descent, line_gap := parser_get_font_vertical_metrics( & entry.parser_info )

	if use_full_text_shape
	{
		// assert( entry.shaper_info != nil )
		shaper_shape_from_text( & ctx.shaper_ctx, & entry.shaper_info, output, text_utf8, ascent, descent, line_gap, entry.size, entry.size_scale )
		return
	}
	else
	{
		ascent   := f32(ascent)
		descent  := f32(descent)
		line_gap := f32(line_gap)

		// Note(Original Author):
		// We use our own fallback dumbass text shaping.
		// WARNING: PLEASE USE HARFBUZZ. GOOD TEXT SHAPING IS IMPORTANT FOR INTERNATIONALISATION.

		position           : Vec2
		advance            : i32 = 0
		to_left_side_glyph : i32 = 0

		prev_codepoint : rune
		for codepoint in text_utf8
		{
			if prev_codepoint > 0 {
				kern       := parser_get_codepoint_kern_advance( & entry.parser_info, prev_codepoint, codepoint )
				position.x += f32(kern) * entry.size_scale
			}
			if codepoint == '\n'
			{
				position.x  = 0.0
				position.y -= (ascent - descent + line_gap) * entry.size_scale
				position.y  = cast(f32) i32( position.y + 0.5 )
				prev_codepoint = rune(0)
				continue
			}
			if math.abs( entry.size ) <= Advance_Snap_Smallfont_Size {
				position.x = math.ceil( position.x )
			}

			append( & output.glyphs, parser_find_glyph_index( & entry.parser_info, codepoint ))
			advance, to_left_side_glyph = parser_get_codepoint_horizontal_metrics( & entry.parser_info, codepoint )

			append( & output.positions, Vec2 {
				cast(f32) i32(position.x + 0.5),
				position.y
			})

			position.x    += f32(advance) * entry.size_scale
			prev_codepoint = codepoint
		}
	}
}
