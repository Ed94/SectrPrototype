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

Glyph_Pack_Entry :: struct #packed {
	position           : Vec2,

	index              : Glyph,
	lru_code           : u32,
	atlas_index        : i32,
	in_atlas           : b8,
	should_cache       : b8,
	region_kind        : Atlas_Region_Kind,
	region_pos         : Vec2,
	region_size        : Vec2,

	shape              : Parser_Glyph_Shape,

	bounds               : Range2,
	bounds_scaled        : Range2,
	bounds_size          : Vec2,
	bounds_size_scaled   : Vec2,
	over_sample          : Vec2,
	scale                : Vec2,

	draw_transform    : Transform,

	draw_quad       : Glyph_Draw_Quad,
	draw_atlas_quad : Glyph_Draw_Quad,
	draw_quad_clear : Glyph_Draw_Quad,
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

// TODO(Ed): This was a rough translation of the raw values the orignal was using, need to give better names...
Frame_Buffer_Pass :: enum u32 {
	None            = 0,
	Glyph           = 1,
	Atlas           = 2,
	Target          = 3,
	Target_Uncached = 4,
}

Glyph_Draw_Buffer :: struct {
	over_sample   : Vec2,
	batch         : i32,
	width         : i32,
	height        : i32,
	draw_padding  : f32,

	batch_x         : i32,
	clear_draw_list : Draw_List,
	draw_list       : Draw_List,

	glyph_pack : #soa[dynamic]Glyph_Pack_Entry,
	oversized  : [dynamic]i32,
	to_cache   : [dynamic]i32,
	cached     : [dynamic]i32,
}

blit_quad :: #force_inline proc ( draw_list : ^Draw_List, p0 : Vec2 = {0, 0}, p1 : Vec2 = {1, 1}, uv0 : Vec2 = {0, 0}, uv1 : Vec2 = {1, 1} )
{
	profile(#procedure)
	// logf("Blitting: xy0: %0.2f, %0.2f xy1: %0.2f, %0.2f uv0: %0.2f, %0.2f uv1: %0.2f, %0.2f",
		// p0.x, p0.y, p1.x, p1.y, uv0.x, uv0.y, uv1.x, uv1.y);
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
construct_filled_path :: #force_inline proc( draw_list : ^Draw_List, outside_point : Vec2, path : []Vertex,
	scale     := Vec2 { 1, 1 },
	translate := Vec2 { 0, 0 }
)
{
	profile(#procedure)
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

generate_glyph_pass_draw_list :: proc(draw_list : ^Draw_List, path : ^[dynamic]Vertex,
	glyph_shape      : Parser_Glyph_Shape, 
	curve_quality    : f32, 
	bounds           : Range2, 
	scale, translate : Vec2
)
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
		
		// case:
			// assert(false, "WTF")
	}

	if len(path) > 0 {
		construct_filled_path(draw_list, outside, path[:], scale, translate)
	}

	draw.end_index = u32(len(draw_list.indices))
	if draw.end_index > draw.start_index {
		append( & draw_list.calls, draw)
	}
}

cache_glyph_to_atlas :: #force_no_inline proc (
	#no_alias draw_list, 
	glyph_buf_draw_list, 
	glyph_buf_clear_list : ^Draw_List,
	glyph_buf_Batch_x    : ^i32,

	temp_path          : ^[dynamic]Vertex,
	glyph_shape        : Parser_Glyph_Shape,
	bounds             : Range2,
	bounds_size_scaled : Vec2,
	atlas_size         : Vec2,

	glyph_buffer_size : Vec2,
	over_sample       : Vec2,
	glyph_padding     : f32,
	buf_transform     : Transform,

	region_pos    : Vec2,
	region_size   : Vec2,
	curve_quality : f32,
)
{
	profile(#procedure)

	batch_x               := cast(f32) glyph_buf_Batch_x ^
	buffer_padding_scaled := glyph_padding        * over_sample
	buffer_bounds_scale   := (bounds_size_scaled) * over_sample

	// Allocate a glyph glyph render target region (FBO)
	buffer_x_allocation := buffer_bounds_scale.x + buffer_padding_scaled.x + 2.0

	// If we exceed the region availbe to draw on the buffer, flush the calls to reset the buffer
	if i32(batch_x + buffer_x_allocation) >= i32(glyph_buffer_size.x) {
		flush_glyph_buffer_draw_list( draw_list, glyph_buf_draw_list, glyph_buf_clear_list, glyph_buf_Batch_x )
		batch_x = cast(f32) glyph_buf_Batch_x ^
	}

	region_pos         := region_pos
	dst_glyph_position := region_pos
	dst_glyph_size     := (bounds_size_scaled) + glyph_padding
	dst_size           := region_size
	to_glyph_buffer_space( & dst_glyph_position, & dst_glyph_size, atlas_size )
	to_glyph_buffer_space( & region_pos,         & dst_size,       atlas_size )

	src_position := Vec2 { batch_x, 0 }
	src_size     := (buffer_bounds_scale + buffer_padding_scaled)
	to_target_space( & src_position, & src_size, glyph_buffer_size )

	clear_target_region : Draw_Call
	{
		using clear_target_region
		pass        = .Atlas
		region      = .Ignore
		start_index = cast(u32) len(glyph_buf_clear_list.indices)

		blit_quad( glyph_buf_clear_list,
			region_pos,     region_pos + dst_size,
			{ 1.0, 1.0 },  { 1.0, 1.0 } )

		end_index = cast(u32) len(glyph_buf_clear_list.indices)
	}

	blit_to_atlas : Draw_Call
	{
		using blit_to_atlas
		pass        = .Atlas
		region      = .None
		start_index = cast(u32) len(glyph_buf_draw_list.indices)

		blit_quad( glyph_buf_draw_list,
			dst_glyph_position, region_pos   + dst_glyph_size,
			src_position,       src_position + src_size )

		end_index = cast(u32) len(glyph_buf_draw_list.indices)
	}

	append( & glyph_buf_clear_list.calls, clear_target_region )
	append( & glyph_buf_draw_list.calls, blit_to_atlas )

	// The glyph buffer space transform for generate_glyph_pass_draw_list
	glyph_transform       := buf_transform
	glyph_transform.pos.x += batch_x
	(glyph_buf_Batch_x ^) += i32(buffer_x_allocation)
	to_glyph_buffer_space( & glyph_transform.pos, & glyph_transform.scale, glyph_buffer_size )

	// Render glyph to glyph render target (FBO)
	generate_glyph_pass_draw_list( draw_list, temp_path, glyph_shape, curve_quality, bounds, glyph_transform.scale, glyph_transform.pos )
}

generate_shape_draw_list :: #force_no_inline proc( ctx : ^Context,
	entry                    : Entry,
	shaped                   : Shaped_Text,
	position,   target_scale : Vec2,
	snap_width, snap_height  : f32
) -> (cursor_pos : Vec2) #no_bounds_check
{
	profile(#procedure)

	colour            := ctx.colour
	colour.a           = 1.0 + ctx.alpha_scalar

	atlas             := & ctx.atlas
	glyph_buffer      := & ctx.glyph_buffer
	draw_list         := & ctx.draw_list
	atlas_glyph_pad   := atlas.glyph_padding
	atlas_size        := Vec2 { f32(atlas.width), f32(atlas.height) }
	glyph_buffer_size := Vec2 { f32(glyph_buffer.width), f32(glyph_buffer.height) }

	profile_begin("soa prep")
	// Make sure the packs are large enough for the shape
	glyph_pack := & glyph_buffer.glyph_pack
	oversized  := & glyph_buffer.oversized
	to_cache   := & glyph_buffer.to_cache
	cached     := & glyph_buffer.cached
	non_zero_resize_soa(glyph_pack, len(shaped.glyphs))
	clear(oversized)
	clear(to_cache)
	clear(cached)
	profile_end()

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
		glyph.index    = shaped.glyphs[ index ]
		glyph.lru_code = font_glyph_lru_code(entry.id, glyph.index)
	}
	profile_end()

	profile_begin("translate")
	for & glyph, index in glyph_pack
	{
		glyph.position = position + (shaped.positions[index]) * target_scale
	}
	profile_end()

	profile_begin("bounds")
	for & glyph, index in glyph_pack
	{
		glyph.bounds             = parser_get_bounds( entry.parser_info, glyph.index )
		glyph.bounds_scaled      = { glyph.bounds.p0 * entry.size_scale, glyph.bounds.p1 * entry.size_scale }
		glyph.bounds_size        = glyph.bounds.p1          - glyph.bounds.p0
		glyph.bounds_size_scaled = glyph.bounds_size        * entry.size_scale
		glyph.scale              = glyph.bounds_size_scaled + atlas.glyph_padding
	}
	profile_end()

	glyph_padding_dbl  := atlas.glyph_padding * 2

	profile_begin("region & oversized segregation")
	for & glyph, index in glyph_pack
	{
		glyph.region_kind = atlas_decide_region( atlas ^, glyph_buffer_size, glyph.bounds_size_scaled )
	}
	profile_end()

	profile_begin("atlas slot resolution & to_cache/cached segregation")
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

		to_cache_check:
		{
			if ctx.temp_codepoint_seen_num <= i32(cap(ctx.temp_codepoint_seen))
			{
				if glyph.atlas_index == - 1
				{
					// Check to see if we reached capacity for the atlas
					if region.next_idx > region.state.capacity 
					{
						// We will evict LRU. We must predict which LRU will get evicted, and if it's something we've seen then we need to take slowpath and flush batch.
						next_evict_codepoint := lru_get_next_evicted( region.state )
						found, success := ctx.temp_codepoint_seen[next_evict_codepoint]
						assert(success != false)
						if (found) {
							break to_cache_check
						}
					}

					profile("append to_cache")
					glyph.atlas_index = atlas_reserve_slot(region, glyph.lru_code)
					glyph.region_pos, glyph.region_size = atlas_region_bbox(region ^, glyph.atlas_index)
					append_sub_pack(to_cache, cast(i32) index)
					mark_batch_codepoint_seen(ctx, glyph.lru_code)
					continue
				}
			}
		}

		profile("append cached")
		glyph.region_pos, glyph.region_size = atlas_region_bbox(region ^, glyph.atlas_index)
		append_sub_pack(cached, cast(i32) index)
		mark_batch_codepoint_seen(ctx, glyph.lru_code)
	}
	profile_end()

	profile_begin("transform & quad compute")
	for id, index in sub_slice(cached)
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
	for id, index in sub_slice(to_cache)
	{
		glyph := & glyph_pack[id]

		// Quad to for drawing atlas slot to target
		quad  := & glyph.draw_quad
		quad.dst_pos   = glyph.position + (glyph.bounds_scaled.p0) * target_scale
		quad.dst_scale =                  (glyph.scale)            * target_scale
		quad.src_scale =                  (glyph.scale)
		quad.src_pos   = (glyph.region_pos)
		to_target_space( & quad.src_pos, & quad.src_scale, atlas_size )

		// The glyph buffer space transform for generate_glyph_pass_draw_list
		transform      := & glyph.draw_transform
		transform.scale = entry.size_scale * glyph_buffer.over_sample
		transform.pos   = -1 * (glyph.bounds.p0) * transform.scale + atlas.glyph_padding
		// Unlike with oversized, this cannot be finished here as its final value is dependent on glyph_buffer.batch_x allocation
	}
	for id, index in sub_slice(oversized)
	{
		glyph := & glyph_pack[id]
	
		// The glyph buffer space transform for generate_glyph_pass_draw_list
		transform      := & glyph.draw_transform
		transform.scale = entry.size_scale * glyph.over_sample 
		transform.pos   = -1 * glyph.bounds.p0 * transform.scale + vec2(atlas.glyph_padding)
		to_glyph_buffer_space( & transform.pos, & transform.scale, glyph_buffer_size )
		// Oversized will use a cleared glyph_buffer every time.

		glyph_padding := vec2(glyph_buffer.draw_padding)

		// Quad to draw during target pass, every 
		quad := & glyph.draw_quad
		quad.dst_pos   = glyph.position + glyph.bounds_scaled.p0                    * target_scale - glyph_padding * target_scale
		quad.dst_scale =                 (glyph.bounds_size_scaled + glyph_padding) * target_scale
		quad.src_pos   = {}
		quad.src_scale = glyph.bounds_size_scaled * glyph.over_sample + glyph_padding
		to_target_space( & quad.src_pos, & quad.src_scale, glyph_buffer_size )
	}
	profile_end()

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

	profile_begin("to_cache: caching to atlas")
	for id, index in sub_slice(to_cache) {
		error : Allocator_Error
		glyph_pack[id].shape, error = parser_get_glyph_shape(entry.parser_info, glyph_pack[id].index)
		assert(error == .None)
	}

	for id, index in sub_slice(to_cache)
	{
		profile("glyph")
		when ENABLE_DRAW_TYPE_VIS {
			colour.r = 0.80
			colour.g = 0.25
			colour.b = 0.25
		}

		glyph := glyph_pack[id]
		cache_glyph_to_atlas(
			draw_list, 
			& glyph_buffer.draw_list, 
			& glyph_buffer.clear_draw_list, 
			& glyph_buffer.batch_x, 

			& ctx.temp_path,

			glyph.shape, 
			glyph.bounds_scaled, 
			glyph.bounds_size_scaled,
			atlas_size,

			glyph_buffer_size,
			glyph.over_sample,
			atlas.glyph_padding,
			glyph.draw_transform,

			glyph.region_pos, 
			glyph.region_size, 
			entry.curve_quality,
		)
	}
	flush_glyph_buffer_draw_list(draw_list, & glyph_buffer.draw_list, & glyph_buffer.clear_draw_list, & glyph_buffer.batch_x)

	for id, index in sub_slice(to_cache) do parser_free_shape(entry.parser_info, glyph_pack[id].shape)
	profile_end()

	generate_cached_draw_list( draw_list, glyph_pack[:], sub_slice(to_cache), ctx.colour )

	profile_begin("generate_cached_draw_list: to_cache")

	when ENABLE_DRAW_TYPE_VIS {
		colour.r = 1.0
		colour.g = 1.0
		colour.b = 1.0
	}
	generate_cached_draw_list( draw_list, glyph_pack[:], sub_slice(cached),   ctx.colour )
	reset_batch_codepoint_state( ctx )
	profile_end()

	flush_glyph_buffer_draw_list(draw_list, & glyph_buffer.draw_list, & glyph_buffer.clear_draw_list, & glyph_buffer.batch_x)
	
	profile_begin("generate oversized glyphs draw_list")
	for id, index in sub_slice(oversized) {
		error : Allocator_Error
		glyph_pack[id].shape, error = parser_get_glyph_shape(entry.parser_info, glyph_pack[id].index)
		assert(error == .None)
	}

	for id, index in sub_slice(oversized)
	{
		flush_glyph_buffer_draw_list(draw_list, & glyph_buffer.draw_list, & glyph_buffer.clear_draw_list, & glyph_buffer.batch_x)
		
		generate_glyph_pass_draw_list( draw_list, & ctx.temp_path,
			glyph_pack[id].shape, 
			entry.curve_quality, 
			glyph_pack[id].bounds, 
			glyph_pack[id].draw_transform.scale, 
			glyph_pack[id].draw_transform.pos 
		)

		when ENABLE_DRAW_TYPE_VIS {
			colour.r = 1.0
			colour.g = 1.0
			colour.b = 0.0
		}

		target_quad := glyph_pack[id].draw_quad

		calls : [2]Draw_Call
		draw_to_target := & calls[0]
		{
			using draw_to_target
			pass        = .Target_Uncached
			colour      = ctx.colour
			start_index = u32(len(draw_list.indices))

			blit_quad( draw_list,
				target_quad.dst_pos, target_quad.dst_pos + target_quad.dst_scale,
				target_quad.src_pos, target_quad.src_pos + target_quad.src_scale )

			end_index = u32(len(draw_list.indices))
		}
		clear_glyph_update := & calls[1]
		{
			// Clear glyph render target (FBO)
			clear_glyph_update.pass              = .Glyph
			clear_glyph_update.start_index       = 0
			clear_glyph_update.end_index         = 0
			clear_glyph_update.clear_before_draw = true
		}
		append( & draw_list.calls, ..calls[:] )
	}
	
	profile_begin("font parser shape cleanup")
	for id, index in sub_slice(oversized) do parser_free_shape(entry.parser_info, glyph_pack[id].shape)
	profile_end()

	cursor_pos = position + shaped.end_cursor_pos * target_scale
	return
}

// Flush the content of the glyph_buffers draw lists to the main draw list
flush_glyph_buffer_draw_list :: #force_inline proc( #no_alias draw_list, glyph_buffer_draw_list,  glyph_buffer_clear_draw_list : ^Draw_List, glyph_buffer_batch_x : ^i32 )
{
	profile(#procedure)
	// Flush Draw_Calls to draw list
	merge_draw_list( draw_list, glyph_buffer_clear_draw_list )
	merge_draw_list( draw_list, glyph_buffer_draw_list)
	clear_draw_list( glyph_buffer_draw_list )
	clear_draw_list( glyph_buffer_clear_draw_list )

	// Clear glyph render target (FBO)
	if (glyph_buffer_batch_x ^) != 0
	{
		call := Draw_Call_Default
		call.pass              = .Glyph
		call.start_index       = 0
		call.end_index         = 0
		call.clear_before_draw = true
		append( & draw_list.calls, call )
		(glyph_buffer_batch_x ^) = 0
	}
}

// ve_fontcache_clear_Draw_List
clear_draw_list :: #force_inline proc ( draw_list : ^Draw_List ) {
	clear( & draw_list.calls )
	clear( & draw_list.indices )
	clear( & draw_list.vertices )
}

// ve_fontcache_merge_Draw_List
merge_draw_list :: proc ( #no_alias dst, src : ^Draw_List )
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

optimize_draw_list :: #force_inline proc (draw_list: ^Draw_List, call_offset: int)
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
