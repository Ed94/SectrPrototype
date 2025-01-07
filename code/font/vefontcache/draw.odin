package vefontcache

import "base:runtime"
import "base:intrinsics"
import "core:slice"
import "thirdparty:freetype"

Vertex :: struct {
	pos  : Vec2,
	u, v : f32,
}

Transform :: struct {
	pos   : Vec2,
	scale : Vec2,
}

Range2 :: struct {
	p0, p1 : Vec2,
}

Glyph_Bounds_Mat :: matrix[2, 2] f32

Glyph_Draw_Quad :: struct {
	dst_pos   : Vec2,
	dst_scale : Vec2,
	src_pos   : Vec2, 
	src_scale : Vec2,
}

// This is used by generate_shape_draw_list & batch_generate_glyphs_draw_list 
// to track relevant glyph data in soa format for pipelined processing
Glyph_Pack_Entry :: struct {
	position           : Vec2,

	index              : Glyph,
	lru_code           : Atlas_Region_Key,
	atlas_index        : i32,
	in_atlas           : b8,
	should_cache       : b8,
	region_kind        : Atlas_Region_Kind,
	region_pos         : Vec2,
	region_size        : Vec2,

	bounds               : Range2,
	bounds_scaled        : Range2,
	bounds_size          : Vec2,
	bounds_size_scaled   : Vec2,
	over_sample          : Vec2,
	scale                : Vec2,

	shape             : Parser_Glyph_Shape,
	draw_transform    : Transform,

	draw_quad          : Glyph_Draw_Quad,
	draw_atlas_quad    : Glyph_Draw_Quad,
	draw_quad_clear    : Glyph_Draw_Quad,
	buffer_x           : f32,
	flush_glyph_buffer : b8,
}

Draw_Call :: struct {
	pass              : Frame_Buffer_Pass,
	start_index       : u32,
	end_index         : u32,
	clear_before_draw : b32,
	region            : Atlas_Region_Kind,
	colour            : Colour,
}

Draw_Call_Default :: Draw_Call {
	pass              = .None,
	start_index       = 0,
	end_index         = 0,
	clear_before_draw = false,
	region            = .A,
	colour            = { 1.0, 1.0, 1.0, 1.0 }
}

Draw_List :: struct {
	vertices : [dynamic]Vertex,
	indices  : [dynamic]u32,
	calls    : [dynamic]Draw_Call,
}

Frame_Buffer_Pass :: enum u32 {
	None            = 0,
	Glyph           = 1, // Operations on glyph buffer render target
	Atlas           = 2, // Operations on atlas render target
	Target          = 3, // Operations on user's end-destination render target using atlas
	Target_Uncached = 4, // Operations on user's end-destination render target using glyph buffer
}

Glyph_Batch_Cache :: struct {
	table : map[Atlas_Region_Key]b8,
	num   : i32,
	cap   : i32,
}

Glyph_Draw_Buffer :: struct{
	over_sample   : Vec2,
	size          : Vec2i,
	draw_padding  : f32,

	allocated_x     : i32, // Space used (horizontally) within the glyph buffer
	clear_draw_list : Draw_List,
	draw_list       : Draw_List,

	batch_cache       : Glyph_Batch_Cache,
	shape_gen_scratch : [dynamic]Vertex,

	glyph_pack : #soa[dynamic]Glyph_Pack_Entry,
	oversized  : [dynamic]i32,
	to_cache   : [dynamic]i32,
	cached     : [dynamic]i32,
}

@(optimization_mode="favor_size")
blit_quad :: #force_inline proc ( draw_list : ^Draw_List, p0 : Vec2 = {0, 0}, p1 : Vec2 = {1, 1}, uv0 : Vec2 = {0, 0}, uv1 : Vec2 = {1, 1} )
{
	// profile(#procedure)
	v_offset := cast(u32) len(draw_list.vertices)

	quadv : [4]Vertex = {
		{
			{p0.x, p0.y},
			uv0.x, uv0.y
		},
		{
			{p0.x, p1.y},
			uv0.x, uv1.y
		},
		{
			{p1.x, p0.y},
			uv1.x, uv0.y
		},
		{
			{p1.x, p1.y},
			uv1.x, uv1.y
		}
	}
	append( & draw_list.vertices, ..quadv[:] )

	quad_indices : []u32 = {
		0 + v_offset, 1 + v_offset, 2 + v_offset,
		2 + v_offset, 1 + v_offset, 3 + v_offset
	}
	append( & draw_list.indices, ..quad_indices[:] )
	return
}

// Constructs a triangle fan to fill a shape using the provided path outside_point represents the center point of the fan.
@(optimization_mode="favor_size")
construct_filled_path :: proc( draw_list : ^Draw_List, 
	outside_point : Vec2, 
	path          : []Vertex,
	scale         := Vec2 { 1, 1 },
	translate     := Vec2 { 0, 0 }
) #no_bounds_check
{
	// profile(#procedure)
	v_offset := cast(u32) len(draw_list.vertices)
	for point in path {
		point    := point
		point.pos = point.pos * scale + translate
		append( & draw_list.vertices, point )
	}

	outside_vertex := cast(u32) len(draw_list.vertices)
	{
		vertex := Vertex {
			pos = outside_point * scale + translate,
			u = 0,
			v = 0,
		}
		append( & draw_list.vertices, vertex )
	}

	for index : u32 = 1; index < cast(u32) len(path); index += 1 {
		indices := & draw_list.indices
		to_add := [3]u32 {
			outside_vertex,
			v_offset + index - 1,
			v_offset + index
		}
		append( indices, ..to_add[:] )
	}
}

@(optimization_mode="favor_size")
generate_glyph_pass_draw_list :: proc(draw_list : ^Draw_List, path : ^[dynamic]Vertex,
	glyph_shape      : Parser_Glyph_Shape, 
	curve_quality    : f32, 
	bounds           : Range2, 
	translate, scale : Vec2
) #no_bounds_check
{
	profile(#procedure)
	outside := Vec2{bounds.p0.x - 21, bounds.p0.y - 33}

	draw            := Draw_Call_Default
	draw.pass        = Frame_Buffer_Pass.Glyph
	draw.start_index = u32(len(draw_list.indices))

	clear(path)

	step := 1.0 / curve_quality
	for edge, index in glyph_shape do #partial switch edge.type
	{
		case .Move:
			if len(path) > 0 {
				construct_filled_path( draw_list, outside, path[:], scale, translate)
				clear(path)
			}
			fallthrough

		case .Line:
			append( path, Vertex { pos = Vec2 { f32(edge.x), f32(edge.y)} } )

		case .Curve:
			assert(len(path) > 0)
			p0 := path[ len(path) - 1].pos
			p1 := Vec2{ f32(edge.contour_x0), f32(edge.contour_y0) }
			p2 := Vec2{ f32(edge.x), f32(edge.y) }

			for index : f32 = 1; index <= curve_quality; index += 1 {
				alpha := index * step
				append( path, Vertex { pos = eval_point_on_bezier3(p0, p1, p2, alpha) } )
			}

		case .Cubic:
			assert( len(path) > 0)
			p0 := path[ len(path) - 1].pos
			p1 := Vec2{ f32(edge.contour_x0), f32(edge.contour_y0) }
			p2 := Vec2{ f32(edge.contour_x1), f32(edge.contour_y1) }
			p3 := Vec2{ f32(edge.x), f32(edge.y) }

			for index : f32 = 1; index <= curve_quality; index += 1 {
				alpha := index * step
				append( path, Vertex { pos = eval_point_on_bezier4(p0, p1, p2, p3, alpha) } )
			}
	}

	if len(path) > 0 {
		construct_filled_path(draw_list, outside, path[:], scale, translate)
	}

	draw.end_index = u32(len(draw_list.indices))
	if draw.end_index > draw.start_index {
		append( & draw_list.calls, draw)
	}
}

generate_shapes_draw_list :: proc ( ctx : ^Context, font : Font_ID, colour : Colour, entry : Entry, px_size, font_scale : f32, position, scale : Vec2, shapes : []Shaped_Text )
{
	assert(len(shapes) > 0)
	for shape in shapes {
		ctx.cursor_pos = {}
		ctx.cursor_pos = generate_shape_draw_list( & ctx.draw_list, shape, & ctx.atlas, & ctx.glyph_buffer, ctx.px_scalar,
			colour, 
			entry,
			px_size,
			font_scale, 
			position,
			scale, 
			ctx.snap_width, 
			ctx.snap_height
		)
	}
}

@(optimization_mode="favor_size")
generate_shape_draw_list :: proc( draw_list : ^Draw_List, shape : Shaped_Text,
	atlas        : ^Atlas,
	glyph_buffer : ^Glyph_Draw_Buffer,
	px_scalar    : f32,

	colour       : Colour,
	entry        : Entry,
	px_size      : f32,
	font_scale   : f32,

	target_position : Vec2,
	target_scale    : Vec2,
	snap_width      : f32, 
	snap_height     : f32
) -> (cursor_pos : Vec2) #no_bounds_check
{
	profile(#procedure)

	// font_scale   := font_scale   * px_scalar
	// target_scale := target_scale / px_scalar

	mark_glyph_seen :: #force_inline proc "contextless" ( cache : ^Glyph_Batch_Cache, lru_code : Atlas_Region_Key ) {
		cache.table[lru_code] = true
		cache.num            += 1
	}
	reset_batch :: #force_inline proc( cache : ^Glyph_Batch_Cache ) {
		clear_map( & cache.table )
		cache.num = 0
	}

	atlas_glyph_pad   := atlas.glyph_padding
	atlas_size        := vec2(atlas.size)
	glyph_buffer_size := vec2(glyph_buffer.size)

	// Make sure the packs are large enough for the shape
	glyph_pack := & glyph_buffer.glyph_pack
	oversized  := & glyph_buffer.oversized
	to_cache   := & glyph_buffer.to_cache
	cached     := & glyph_buffer.cached
	non_zero_resize_soa(glyph_pack, len(shape.glyphs))

	append_sub_pack :: #force_inline proc ( pack : ^[dynamic]i32, entry : i32 )
	{
			raw := cast(^runtime.Raw_Dynamic_Array) pack
			raw.len            += 1
			pack[len(pack) - 1] = entry
	}
	sub_slice :: #force_inline proc "contextless" ( pack : ^[dynamic]i32) -> []i32 { return pack[:] }

	profile_begin("index")
	for & glyph, index in glyph_pack
	{
		glyph.index    = shape.glyphs[ index ]
		glyph.lru_code = atlas_glyph_lru_code(entry.id, px_size, glyph.index)
	}
	profile_end()

	profile_begin("translate")
	for & glyph, index in glyph_pack
	{
		glyph.position = target_position + (shape.positions[index]) * target_scale
	}
	profile_end()

	profile_begin("bounds")
	for & glyph, index in glyph_pack
	{
		glyph.bounds             = parser_get_bounds( entry.parser_info, glyph.index )
		glyph.bounds_scaled      = { glyph.bounds.p0 * font_scale, glyph.bounds.p1 * font_scale }
		glyph.bounds_size        = glyph.bounds.p1          - glyph.bounds.p0
		glyph.bounds_size_scaled = glyph.bounds_size        * font_scale
		glyph.scale              = glyph.bounds_size_scaled + atlas.glyph_padding
	}
	profile_end()

	glyph_padding_dbl  := atlas.glyph_padding * 2

	profile_begin("region")
	for & glyph, index in glyph_pack
	{
		glyph.region_kind = atlas_decide_region( atlas ^, glyph_buffer_size, glyph.bounds_size_scaled )
	}
	profile_end()

	profile_begin("batching")
	clear(oversized)
	clear(to_cache)
	clear(cached)
	reset_batch( & glyph_buffer.batch_cache)

	for & glyph, index in glyph_pack
	{
		if glyph.region_kind == .None { 
			assert(false, "FAILED TO ASSGIN REGION")
			continue
	 	}
		if glyph.region_kind == .E
		{
			glyph.over_sample = \
				glyph.bounds_size_scaled.x <= glyph_buffer_size.x / 2 &&
				glyph.bounds_size_scaled.y <= glyph_buffer_size.y / 2 ? \
					{2.0, 2.0} \
				: {1.0, 1.0}
			append_sub_pack(oversized, cast(i32) index)
			continue
		}

		glyph.over_sample = glyph_buffer.over_sample
		region           := atlas.regions[glyph.region_kind]
		glyph.atlas_index =  lru_get( & region.state, glyph.lru_code )

		// Glyphs are prepared in batches based on the capacity of the batch cache.
		Prepare_For_Batch:
		{
			// Determine if we hit the limit for this batch.
			if glyph_buffer.batch_cache.num >= glyph_buffer.batch_cache.cap do break Prepare_For_Batch

			if glyph.atlas_index == - 1
			{
				// Check to see if we reached capacity for the atlas
				if region.next_idx > region.state.capacity 
				{
					// We will evict LRU. We must predict which LRU will get evicted, and if it's something we've seen then we need to take slowpath and flush batch.
					next_evict_glyph              := lru_get_next_evicted( region.state )
					found_take_slow_path, success := glyph_buffer.batch_cache.table[next_evict_glyph]
					assert(success != false)
					if (found_take_slow_path) {
						break Prepare_For_Batch
					}
				}

				profile("append to_cache")
				glyph.atlas_index = atlas_reserve_slot(region, glyph.lru_code)
				glyph.region_pos, glyph.region_size = atlas_region_bbox(region ^, glyph.atlas_index)
				append_sub_pack(to_cache, cast(i32) index)
				mark_glyph_seen(& glyph_buffer.batch_cache, glyph.lru_code)
				continue
			}

			profile("append cached")
			glyph.region_pos, glyph.region_size = atlas_region_bbox(region ^, glyph.atlas_index)
			append_sub_pack(cached, cast(i32) index)
			mark_glyph_seen(& glyph_buffer.batch_cache, glyph.lru_code)
			continue
		}

		// Batch has been prepared for a set of glyphs time to generate glyphs.
		batch_generate_glyphs_draw_list( draw_list, glyph_pack, sub_slice(cached), sub_slice(to_cache), sub_slice(oversized),
			atlas, 
			glyph_buffer, 
			atlas_size, 
			glyph_buffer_size, 
			entry, 
			colour, 
			font_scale, 
			target_scale
		)

		reset_batch( & glyph_buffer.batch_cache)
		clear(oversized)
		clear(to_cache)
		clear(cached)
	}
	profile_end()

	if len(oversized) > 0 || glyph_buffer.batch_cache.num > 0
	{
		// Last batch pass
		batch_generate_glyphs_draw_list( draw_list, glyph_pack, sub_slice(cached), sub_slice(to_cache), sub_slice(oversized),
			atlas, 
			glyph_buffer, 
			atlas_size, 
			glyph_buffer_size, 
			entry, 
			colour, 
			font_scale, 
			target_scale
		)
	}

	cursor_pos = target_position + shape.end_cursor_pos * target_scale
	return
}

batch_generate_glyphs_draw_list :: proc ( draw_list : ^Draw_List,
	glyph_pack : ^#soa[dynamic]Glyph_Pack_Entry,
	cached     : []i32, 
	to_cache   : []i32, 
	oversized  : []i32,

	atlas             : ^Atlas,
	glyph_buffer      : ^Glyph_Draw_Buffer,
	atlas_size        : Vec2,
	glyph_buffer_size : Vec2,

	entry             : Entry,
	colour            : Colour,
	font_scale        : Vec2,
	target_scale      : Vec2,
) #no_bounds_check
{
	profile(#procedure)

	when ENABLE_DRAW_TYPE_VIS {
		colour := colour
	}

	profile_begin("glyph buffer transform & draw quads compute")
	for id, index in cached
	{
		// Quad to for drawing atlas slot to target
		glyph := & glyph_pack[id]
		quad  := & glyph.draw_quad
		quad.dst_pos   = glyph.position + (glyph.bounds_scaled.p0) * target_scale
		quad.dst_scale =                  (glyph.scale)            * target_scale
		quad.src_scale =                  (glyph.scale)
		quad.src_pos   = (glyph.region_pos) 
		to_target_space( & quad.src_pos, & quad.src_scale, atlas_size )
	}
	for id, index in to_cache
	{
		glyph := & glyph_pack[id]

		f32_allocated_x := cast(f32) glyph_buffer.allocated_x

		// Resolve how much space this glyph will allocate in the buffer
		buffer_size   := (glyph.bounds_size_scaled + glyph_buffer.draw_padding) * glyph_buffer.over_sample
		// Allocate a glyph glyph render target region (FBO)
		to_allocate_x := buffer_size.x + 2.0

		// If allocation would exceed buffer's bounds the buffer must be flush before this glyph can be rendered.
		glyph.flush_glyph_buffer = i32(f32_allocated_x + to_allocate_x) >= i32(glyph_buffer_size.x)
		glyph.buffer_x           = f32_allocated_x * f32( i32( ! glyph.flush_glyph_buffer ) )

		// The glyph buffer space transform for generate_glyph_pass_draw_list
		draw_transform       := & glyph.draw_transform
		draw_transform.scale  = font_scale * glyph_buffer.over_sample
		draw_transform.pos    = -1 * (glyph.bounds.p0) * draw_transform.scale + glyph_buffer.draw_padding
		draw_transform.pos.x += glyph.buffer_x
		to_glyph_buffer_space( & draw_transform.pos, & draw_transform.scale, glyph_buffer_size )

		// Allocate the space
		glyph_buffer.allocated_x += i32(to_allocate_x)

		// Quad to for drawing atlas slot to target (used in generate_cached_draw_list)
		draw_quad := & glyph.draw_quad

		// Destination  (draw_list's target image)
		draw_quad.dst_pos   = glyph.position + (glyph.bounds_scaled.p0) * target_scale
		draw_quad.dst_scale =                  (glyph.scale)            * target_scale

		// UV Coordinates for sampling the atlas
		draw_quad.src_scale = (glyph.scale)
		draw_quad.src_pos   = (glyph.region_pos)
		to_target_space( & draw_quad.src_pos, & draw_quad.src_scale, atlas_size )
	}
	for id, index in oversized
	{
		glyph := & glyph_pack[id]

		f32_allocated_x := cast(f32) glyph_buffer.allocated_x
		// Resolve how much space this glyph will allocate in the buffer
		buffer_size   := (glyph.bounds_size_scaled + glyph_buffer.draw_padding) * glyph.over_sample

		// Allocate a glyph glyph render target region (FBO)
		to_allocate_x            := buffer_size.x + 2.0
		glyph_buffer.allocated_x += i32(to_allocate_x)

		// If allocation would exceed buffer's bounds the buffer must be flush before this glyph can be rendered.
		glyph.flush_glyph_buffer = i32(f32_allocated_x + to_allocate_x) >= i32(glyph_buffer_size.x)
		glyph.buffer_x           = f32_allocated_x * f32( i32( ! glyph.flush_glyph_buffer ) )

		// Quad to for drawing atlas slot to target
		draw_quad := & glyph.draw_quad

		glyph_padding := vec2(glyph_buffer.draw_padding)

		// Target position (draw_list's target image)
		draw_quad.dst_pos   = glyph.position + (glyph.bounds_scaled.p0   - glyph_padding) * target_scale
		draw_quad.dst_scale =                  (glyph.bounds_size_scaled + glyph_padding) * target_scale
		
		// The glyph buffer space transform for generate_glyph_pass_draw_list
		draw_transform       := & glyph.draw_transform
		draw_transform.scale  = font_scale * glyph.over_sample 
		draw_transform.pos    = -1 * glyph.bounds.p0 * draw_transform.scale + vec2(atlas.glyph_padding)
		draw_transform.pos.x += glyph.buffer_x
		to_glyph_buffer_space( & draw_transform.pos, & draw_transform.scale, glyph_buffer_size )


		draw_quad.src_pos   = Vec2 { glyph.buffer_x, 0 }
		draw_quad.src_scale = glyph.bounds_size_scaled * glyph.over_sample + glyph_padding
		to_target_space( & draw_quad.src_pos, & draw_quad.src_scale, glyph_buffer_size )
	}
	profile_end()

	profile_begin("generate oversized glyphs draw_list")
	{
		when ENABLE_DRAW_TYPE_VIS {
			colour.r = 1.0
			colour.g = 1.0
			colour.b = 0.0
		}
		for id, index in oversized {
			error : Allocator_Error
			glyph_pack[id].shape, error = parser_get_glyph_shape(entry.parser_info, glyph_pack[id].index)
			assert(error == .None)
		}
		for id, index in oversized
		{
			glyph := & glyph_pack[id]
			if glyph.flush_glyph_buffer do flush_glyph_buffer_draw_list(draw_list, 
				& glyph_buffer.draw_list, 
				& glyph_buffer.clear_draw_list, 
				& glyph_buffer.allocated_x
			)
			
			generate_glyph_pass_draw_list( draw_list, & glyph_buffer.shape_gen_scratch,
				glyph_pack[id].shape, 
				entry.curve_quality, 
				glyph_pack[id].bounds, 
				glyph_pack[id].draw_transform.pos,
				glyph_pack[id].draw_transform.scale
			)

			target_quad := & glyph_pack[id].draw_quad

			draw_to_target : Draw_Call
			{
				draw_to_target.pass        = .Target_Uncached
				draw_to_target.colour      = colour
				draw_to_target.start_index = u32(len(draw_list.indices))

				blit_quad( draw_list,
					target_quad.dst_pos, target_quad.dst_pos + target_quad.dst_scale,
					target_quad.src_pos, target_quad.src_pos + target_quad.src_scale )

				draw_to_target.end_index = u32(len(draw_list.indices))
			}
			append( & draw_list.calls, draw_to_target )
		}

		if len(oversized) > 0 do flush_glyph_buffer_draw_list(draw_list, & glyph_buffer.draw_list, & glyph_buffer.clear_draw_list, & glyph_buffer.allocated_x)
		for id, index in oversized do parser_free_shape(entry.parser_info, glyph_pack[id].shape)
	}
	profile_end()

	profile_begin("to_cache: caching to atlas")
	{
		for id, index in to_cache {
			error : Allocator_Error
			glyph_pack[id].shape, error = parser_get_glyph_shape(entry.parser_info, glyph_pack[id].index)
			assert(error == .None)
		}

		for id, index in to_cache
		{
			profile("glyph")
			glyph := & glyph_pack[id]

			if glyph.flush_glyph_buffer do flush_glyph_buffer_draw_list( draw_list, 
				& glyph_buffer.draw_list,
				& glyph_buffer.clear_draw_list,
				& glyph_buffer.allocated_x
			)
	
			dst_region_pos    := glyph.region_pos
			dst_region_size   := glyph.region_size
			to_glyph_buffer_space( & dst_region_pos, & dst_region_size, atlas_size )
		
			clear_target_region : Draw_Call
			clear_target_region.pass        = .Atlas
			clear_target_region.region      = .Ignore
			clear_target_region.start_index = cast(u32) len(glyph_buffer.clear_draw_list.indices)
			blit_quad( & glyph_buffer.clear_draw_list,
				dst_region_pos, dst_region_pos + dst_region_size,
				{ 1.0, 1.0 },  { 1.0, 1.0 }
			)
			clear_target_region.end_index = cast(u32) len(glyph_buffer.clear_draw_list.indices)
			
			dst_glyph_pos    := glyph.region_pos
			dst_glyph_size   := glyph.bounds_size_scaled + atlas.glyph_padding
			// dst_glyph_size.y  = ceil(dst_glyph_size.y) // Note(Ed): Seems to improve hinting
			to_glyph_buffer_space( & dst_glyph_pos, & dst_glyph_size, atlas_size )
	
			src_position  := Vec2 { glyph.buffer_x, 0 }
			src_size      := (glyph.bounds_size_scaled + atlas.glyph_padding) * glyph_buffer.over_sample
			// src_size.y     = ceil(src_size.y) // Note(Ed): Seems to improve hinting
			to_target_space( & src_position, & src_size, glyph_buffer_size )
			
			blit_to_atlas : Draw_Call
			blit_to_atlas.pass        = .Atlas
			blit_to_atlas.region      = .None
			blit_to_atlas.start_index = cast(u32) len(glyph_buffer.draw_list.indices)
			blit_quad( & glyph_buffer.draw_list,
				dst_glyph_pos, dst_glyph_pos + dst_glyph_size,
				src_position,  src_position  + src_size )
			blit_to_atlas.end_index = cast(u32) len(glyph_buffer.draw_list.indices)
	
			append( & glyph_buffer.clear_draw_list.calls, clear_target_region )
			append( & glyph_buffer.draw_list.calls,       blit_to_atlas )
	
			// Render glyph to glyph render target (FBO)
			generate_glyph_pass_draw_list( draw_list, & glyph_buffer.shape_gen_scratch, 
				glyph.shape, 
				entry.curve_quality, 
				glyph.bounds, 
				glyph.draw_transform.pos, 
				glyph.draw_transform.scale 
			)
		}

		if len(to_cache) > 0 do flush_glyph_buffer_draw_list(draw_list, & glyph_buffer.draw_list, & glyph_buffer.clear_draw_list, & glyph_buffer.allocated_x)
		for id, index in to_cache do parser_free_shape(entry.parser_info, glyph_pack[id].shape)
	}
	profile_end()

	generate_cached_draw_list :: #force_inline proc  (draw_list : ^Draw_List, glyph_pack : #soa[]Glyph_Pack_Entry, sub_pack : []i32, colour : Colour )
	{
		profile(#procedure)
		call             := Draw_Call_Default
		call.pass         = .Target
		call.colour       = colour
		for id, index in sub_pack
		{
			profile("glyph")
			call.start_index = u32(len(draw_list.indices))

			quad := glyph_pack[id].draw_quad
			blit_quad(draw_list,
				quad.dst_pos, quad.dst_pos + quad.dst_scale,
				quad.src_pos, quad.src_pos + quad.src_scale
			)
			call.end_index = u32(len(draw_list.indices))
			append(& draw_list.calls, call)
		}
	}

	profile_begin("generate_cached_draw_list: to_cache")
	when ENABLE_DRAW_TYPE_VIS {
		colour.r = 0.80
		colour.g = 0.25
		colour.b = 0.25
	}
	generate_cached_draw_list( draw_list, glyph_pack[:], to_cache, colour )
	profile_end()

	profile_begin("generate_cached_draw_list: to_cache")
	when ENABLE_DRAW_TYPE_VIS {
		colour.r = 1.0
		colour.g = 1.0
		colour.b = 1.0
	}
	generate_cached_draw_list( draw_list, glyph_pack[:], cached, colour )
	profile_end()
}

// Flush the content of the glyph_buffers draw lists to the main draw list
flush_glyph_buffer_draw_list :: proc( #no_alias draw_list, glyph_buffer_draw_list,  glyph_buffer_clear_draw_list : ^Draw_List, allocated_x : ^i32 )
{
	profile(#procedure)
	// if len(glyph_buffer_clear_draw_list.calls) == 0 || len(glyph_buffer_draw_list.calls) == 0 do return

	// Flush Draw_Calls to draw list
	merge_draw_list( draw_list, glyph_buffer_clear_draw_list )
	merge_draw_list( draw_list, glyph_buffer_draw_list)
	clear_draw_list( glyph_buffer_draw_list )
	clear_draw_list( glyph_buffer_clear_draw_list )

	call := Draw_Call_Default
	call.pass              = .Glyph
	call.start_index       = 0
	call.end_index         = 0
	call.clear_before_draw = true
	append( & draw_list.calls, call )
	(allocated_x ^) = 0
}

// ve_fontcache_clear_Draw_List
@(optimization_mode="favor_size")
clear_draw_list :: #force_inline proc ( draw_list : ^Draw_List ) {
	clear( & draw_list.calls )
	clear( & draw_list.indices )
	clear( & draw_list.vertices )
}

// ve_fontcache_merge_Draw_List
@(optimization_mode="favor_size")
merge_draw_list :: proc ( #no_alias dst, src : ^Draw_List ) #no_bounds_check
{
	profile(#procedure)
	error : Allocator_Error

	v_offset := cast(u32) len( dst.vertices )
	num_appended : int
	num_appended, error = append( & dst.vertices, ..src.vertices[:] )
	assert( error == .None )

	i_offset := cast(u32) len(dst.indices)
	for index : i32 = 0; index < cast(i32) len(src.indices); index += 1 {
		ignored : int
		ignored, error = append( & dst.indices, src.indices[index] + v_offset )
		assert( error == .None )
	}

	for index : i32 = 0; index < cast(i32) len(src.calls); index += 1 {
		src_call             := src.calls[ index ]
		src_call.start_index += i_offset
		src_call.end_index   += i_offset
		append( & dst.calls, src_call )
		assert( error == .None )
	}
}

optimize_draw_list :: proc (draw_list: ^Draw_List, call_offset: int)  #no_bounds_check
{
	profile(#procedure)
	assert(draw_list != nil)

	can_merge_draw_calls :: #force_inline proc "contextless" ( a, b : ^Draw_Call ) -> bool {
		result := \
		a.pass      == b.pass        &&
		a.end_index == b.start_index &&
		a.region    == b.region      &&
		a.colour    == b.colour      &&
		! b.clear_before_draw
		return result
	}

	write_index := call_offset
	for read_index := call_offset + 1; read_index < len(draw_list.calls); read_index += 1
	{
		draw_current := & draw_list.calls[write_index]
		draw_next    := & draw_list.calls[read_index]

		if can_merge_draw_calls(draw_current, draw_next) {
			draw_current.end_index = draw_next.end_index
		}
		else {
			// Move to the next write position and copy the draw call
			write_index += 1
			if write_index != read_index {
				draw_list.calls[write_index] = (draw_next^)
			}
		}
	}

	resize( & draw_list.calls, write_index + 1)
}
