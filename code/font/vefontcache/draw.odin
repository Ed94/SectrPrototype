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
	translate : Vec2,
	scale     : Vec2,
}

Glyph_Bounds :: struct {
	p0, p1 : Vec2,
}

Glyph_Bounds_Mat :: matrix[2, 2] f32

Glyph_Pack_Entry :: struct #packed {
	translate          : Vec2,

	index              : Glyph,
	lru_code           : u64,
	atlas_index        : i32,
	in_atlas           : b8,
	should_cache       : b8,
	region_kind        : Atlas_Region_Kind,
	region_pos         : Vec2,
	region_size        : Vec2,

	shape              : Parser_Glyph_Shape,

	bounds             : Glyph_Bounds,
	bounds_size        : Vec2,
	bounds_size_scaled : Vec2,
	over_sample        : Vec2,
	scale              : Vec2,

	draw_transform : Transform,
	// cache_draw_scale     : Vec2,
	// cache_draw_translate : Vec2,

	// shape_id     : i32,
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

generate_glyph_pass_draw_list :: #force_inline proc(ctx : ^Context, 
	glyph_shape : Parser_Glyph_Shape, 
	curve_quality : f32, 
	bounds : Glyph_Bounds, 
	scale, translate : Vec2
) -> b32
{
	profile(#procedure)

	outside := Vec2{bounds.p0.x - 21, bounds.p0.y - 33}

	draw            := Draw_Call_Default
	draw.pass        = Frame_Buffer_Pass.Glyph
	draw.start_index = u32(len(ctx.draw_list.indices))

	path := &ctx.temp_path
	clear(path)

	step := 1.0 / curve_quality
	for edge in glyph_shape do #partial switch edge.type
	{
		case .Move:
			if len(path) > 0 {
				construct_filled_path(&ctx.draw_list, outside, path[:], scale, translate)
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
		construct_filled_path(&ctx.draw_list, outside, path[:], scale, translate)
	}

	draw.end_index = u32(len(ctx.draw_list.indices))
	if draw.end_index > draw.start_index {
		append( & ctx.draw_list.calls, draw)
	}
	return true
}

cache_glyph_to_atlas :: #force_no_inline proc ( ctx : ^Context,
	#no_alias draw_list, 
	glyph_buf_draw_list, glyph_buf_clear_list : ^Draw_List,
	glyph_buf_Batch_x : ^i32,

	glyph_padding : f32,
	glyph_buffer_size : Vec2,

	atlas_size : Vec2,

	buf_transform : Transform,

	glyph_shape : Parser_Glyph_Shape,

	bounds      : Glyph_Bounds, // -> generate_glyph_pass_draw_list
	bounds_size : Vec2,


	region_pos  : Vec2,
	region_size : Vec2,
	lru_code    : u64,
	atlas_index : i32,
	entry       : Entry,
	// region_kind : Atlas_Region_Kind,
	// region      : ^Atlas_Region,
	over_sample : Vec2 
)
{
	profile(#procedure)

	batch_x := cast(f32) glyph_buf_Batch_x ^

	glyph_buffer_pad := over_sample.x * glyph_padding

	// Allocate a glyph glyph render target region (FBO)
	buffer_x_allocation := bounds_size.x * buf_transform.scale.x + glyph_buffer_pad + 2.0

	// If we exceed the region availbe to draw on the buffer, flush the calls to reset the buffer
	if i32(batch_x + buffer_x_allocation) >= i32(glyph_buffer_size.x) {
		flush_glyph_buffer_draw_list( draw_list, glyph_buf_draw_list, glyph_buf_clear_list, glyph_buf_Batch_x )
		batch_x = cast(f32) glyph_buf_Batch_x ^
	}

	region_pos := region_pos

	dst_glyph_position := region_pos
	dst_glyph_size     := ceil(bounds_size * entry.size_scale) + glyph_padding
	dst_size           := (region_size)
	to_screen_space( & dst_glyph_position, & dst_glyph_size, atlas_size )
	to_screen_space( & region_pos,         & dst_size,       atlas_size )

	src_position := Vec2 { batch_x, 0 }
	src_size     := (bounds_size * buf_transform.scale + over_sample * glyph_padding)
	to_text_space( & src_position, & src_size, glyph_buffer_size )

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

	

	screen_space_translate := buf_transform.translate
	screen_space_scale     := buf_transform.scale

	screen_space_translate.x  = (buf_transform.translate.x + batch_x)
	glyph_buf_Batch_x^       += i32(buffer_x_allocation)

	to_screen_space( & screen_space_translate, & screen_space_scale, glyph_buffer_size )

	// Render glyph to glyph render target (FBO)
	generate_glyph_pass_draw_list( ctx, glyph_shape, entry.curve_quality, bounds, screen_space_scale, screen_space_translate )
}

generate_oversized_draw_list :: #force_no_inline proc( ctx : ^Context, 
	glyph_padding : f32,
	glyph_buffer_size : Vec2,
	entry : Entry,
	glyph : Glyph,
	glyph_shape : Parser_Glyph_Shape,
	bounds                       : Glyph_Bounds, // -> generate_glyph_pass_draw_list
	bounds_size                  : Vec2,
	over_sample, position, scale : Vec2 )
{
	profile(#procedure)
	// Draw un-antialiased glyph to draw_buffer
	glyph_draw_scale     := over_sample * entry.size_scale
	glyph_draw_translate := -1 * bounds.p0 * glyph_draw_scale + glyph_padding
	to_screen_space( & glyph_draw_translate, & glyph_draw_scale, glyph_buffer_size )

	generate_glyph_pass_draw_list( ctx, glyph_shape, entry.curve_quality, bounds, glyph_draw_scale, glyph_draw_translate )

	bounds_scaled := bounds_size * entry.size_scale

	// Figure out the source rect.
	glyph_position := Vec2 {}
	glyph_size     := glyph_padding + bounds_scaled * over_sample
	glyph_dst_size := glyph_padding + bounds_scaled

	// Figure out the destination rect.
	bounds_0_scaled := (bounds.p0 * entry.size_scale)
	dst             := position + scale * bounds_0_scaled - glyph_padding * scale
	dst_size        := glyph_dst_size * scale
	to_text_space( & glyph_position, & glyph_size, glyph_buffer_size )

	// Add the glyph Draw_Call.
	calls : [2]Draw_Call

	draw_to_target := & calls[0]
	{
		using draw_to_target
		pass        = .Target_Uncached
		colour      = ctx.colour
		start_index = u32(len(ctx.draw_list.indices))

		blit_quad( & ctx.draw_list,
			dst,            dst            + dst_size,
			glyph_position, glyph_position + glyph_size )

		end_index = u32(len(ctx.draw_list.indices))
	}

	clear_glyph_update := & calls[1]
	{
		// Clear glyph render target (FBO)
		clear_glyph_update.pass              = .Glyph
		clear_glyph_update.start_index       = 0
		clear_glyph_update.end_index         = 0
		clear_glyph_update.clear_before_draw = true
	}
	append( & ctx.draw_list.calls, ..calls[:] )
}

generate_cached_draw_list :: proc (draw_list : ^Draw_List, glyph_pack : #soa[]Glyph_Pack_Entry, sub_pack : []i32,
	atlas_size       : Vec2,
	glyph_size_scale : f32,
	colour           : Colour,
	position         : Vec2,
	scale            : Vec2
)
{
	profile(#procedure)

	call             := Draw_Call_Default
	call.pass         = .Target
	call.colour       = colour

	for id, index in sub_pack
	{
		glyph := glyph_pack[id]
		profile("cached")

		bounds_0_scaled  := ceil(glyph.bounds.p0 * glyph_size_scale - 0.5 )
		dst_pos          := glyph.translate + bounds_0_scaled * scale
		dst_scale        := glyph.scale * scale
		src_pos          := glyph.region_pos

		to_text_space( & src_pos, & glyph.scale, atlas_size )

		call.start_index  = u32(len(draw_list.indices))

		blit_quad(draw_list,
			dst_pos, dst_pos + dst_scale,
			src_pos, src_pos + glyph.scale )

		call.end_index = u32(len(draw_list.indices))

		append(& draw_list.calls, call)
	}
}

// @(require_results)
append_no_bounds_check :: proc "contextless" (array: ^[dynamic]i32, value: i32) -> (n: int) {
	raw := transmute(^runtime.Raw_Dynamic_Array)array
	if raw.len >= raw.cap {
			return 0
	}
	array[raw.len] = value
	raw.len += 1
	return raw.len
}

generate_shape_draw_list :: #force_no_inline proc( ctx : ^Context,
	entry                   : Entry,
	shaped                  : Shaped_Text,
	position,   scale       : Vec2,
	snap_width, snap_height : f32
) -> (cursor_pos : Vec2) #no_bounds_check
{
	profile(#procedure)

	atlas             := & ctx.atlas
	glyph_buffer      := & ctx.glyph_buffer
	draw_list         := & ctx.draw_list
	colour            := ctx.colour
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
		// glyph.shape_id = cast(i32) index
		glyph.index = shaped.glyphs[ index ]
	}
	profile_end()

	profile_begin("translate")
	for & glyph, index in glyph_pack
	{
		glyph.translate = position + (shaped.positions[index]) * scale
	}
	profile_end()

	profile_begin("bounds")
	for & glyph, index in glyph_pack
	{
		glyph.lru_code = font_glyph_lru_code(entry.id, glyph.index)
	}
	for & glyph, index in glyph_pack
	{
		glyph.bounds      = parser_get_bounds( entry.parser_info, glyph.index )
		glyph.bounds_size = glyph.bounds.p1 - glyph.bounds.p0
	}
	for & glyph, index in glyph_pack
	{
		glyph.bounds_size_scaled = glyph.bounds_size        * entry.size_scale
		glyph.scale              = glyph.bounds_size_scaled + atlas.glyph_padding
	}
	profile_end()

	glyph_padding_dbl  := atlas.glyph_padding * 2

	profile_begin("region & oversized segregation")
	for & glyph, index in glyph_pack
	{
		glyph.region_kind = atlas_decide_region( atlas ^, glyph_buffer_size, glyph.bounds_size_scaled )
		glyph.over_sample = glyph_buffer.over_sample
	}
	profile_end()

	profile_begin("atlas slot resolution & to_cache/cached segregation")
	for & glyph, index in glyph_pack
	{
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

		region := atlas.regions[glyph.region_kind]
		glyph.atlas_index =  lru_get( & region.state, glyph.lru_code )

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
						continue
					}
				}

				profile("append to_cache")
				glyph.atlas_index = atlas_reserve_slot(region, glyph.lru_code)
				glyph.region_pos, glyph.region_size = atlas_region_bbox(region ^, glyph.atlas_index)
				append_sub_pack(to_cache, cast(i32) index)
				continue
			}
		}

		profile("append cached")
		glyph.region_pos, glyph.region_size = atlas_region_bbox(region ^, glyph.atlas_index)
		append_sub_pack(cached, cast(i32) index)
		mark_batch_codepoint_seen(ctx, glyph.lru_code)
	}
	profile_end()

	profile_begin("to_cache: font parser shape generation")
	for id, index in sub_slice(to_cache) {
		error : Allocator_Error
		glyph_pack[id].shape, error = parser_get_glyph_shape(entry.parser_info, glyph_pack[id].index)
		// assert(error == .None)
	}
	profile_end()

	profile_begin("transform math")
	for id, index in sub_slice(to_cache)
	{
		transform := & glyph_pack[id].draw_transform
		transform.scale     = glyph_buffer.over_sample * entry.size_scale
		transform.translate = -1 * glyph_pack[id].bounds.p0 * transform.scale + atlas.glyph_padding
	}
	for id, index in sub_slice(oversized)
	{
		transform := & glyph_pack[id].draw_transform
		transform.scale     = glyph_buffer.over_sample * entry.size_scale
		transform.translate = -1 * glyph_pack[id].bounds.p0 * transform.scale + atlas.glyph_padding
	}
	profile_end()

	profile_begin("to_cache: caching to atlas")
	for id, index in sub_slice(to_cache)
	{
		glyph := glyph_pack[id]
		cache_glyph_to_atlas( ctx, 
			draw_list, 
			& glyph_buffer.draw_list, 
			& glyph_buffer.clear_draw_list, 
			& glyph_buffer.batch_x, 

			atlas.glyph_padding,
			glyph_buffer_size,
			atlas_size,

			glyph.draw_transform,

			glyph.shape, 
			glyph.bounds, 
			glyph.bounds_size, 
			glyph.region_pos, 
			glyph.region_size, 
			glyph.lru_code, 
			glyph.atlas_index, 
			entry, 
			glyph.over_sample
		)
		mark_batch_codepoint_seen(ctx, glyph.lru_code)
	}
	reset_batch_codepoint_state( ctx )
	flush_glyph_buffer_draw_list(draw_list, & glyph_buffer.draw_list, & glyph_buffer.clear_draw_list, & glyph_buffer.batch_x)
	profile_end()
		
	for id, index in sub_slice(to_cache)
	{
		parser_free_shape(entry.parser_info, glyph_pack[id].shape)
	}
	
	generate_cached_draw_list( draw_list, glyph_pack[:], sub_slice(to_cache), atlas_size, entry.size_scale, ctx.colour, position, scale )
	generate_cached_draw_list( draw_list, glyph_pack[:], sub_slice(cached),   atlas_size, entry.size_scale, ctx.colour, position, scale )

	profile_begin("generate oversized glyphs draw_list")
	for id, index in sub_slice(oversized)
	{
		glyph := glyph_pack[id]
		generate_oversized_draw_list(ctx, 
			glyph_buffer.draw_padding,
			glyph_buffer_size,
			entry, glyph.index, glyph.shape,
			glyph.bounds,
			glyph.bounds_size,
			glyph.over_sample, glyph.translate, scale
		)
	}
	reset_batch_codepoint_state( ctx )
	profile_end()

	cursor_pos = position + shaped.end_cursor_pos * scale
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
