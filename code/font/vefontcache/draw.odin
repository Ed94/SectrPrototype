package vefontcache

import "thirdparty:freetype"
import "core:slice"

Vertex :: struct {
	pos  : Vec2,
	u, v : f32,
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
	draw_padding  : i32,

	batch_x         : i32,
	clear_draw_list : Draw_List,
	draw_list       : Draw_List,
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

// TODO(Ed): glyph caching cannot be handled in a 'font parser' abstraction. Just going to have explicit procedures to grab info neatly...
// cache_glyph_freetype :: proc(ctx: ^Context, font: Font_ID, glyph_index: Glyph, entry: ^Entry, bounds_0, bounds_1: Vec2, scale, translate: Vec2) -> b32
// {
// 	draw_filled_path_freetype :: proc( draw_list : ^Draw_List, outside_point : Vec2, path : []Vertex,
// 		scale     := Vec2 { 1, 1 },
// 		translate := Vec2 { 0, 0 },
// 		debug_print_verbose : b32 = false
// 	)
// 	{
// 		if debug_print_verbose {
// 			log("outline_path:")
// 			for point in path {
// 				vec := point.pos * scale + translate
// 				logf(" %0.2f %0.2f", vec.x, vec.y )
// 			}
// 		}

// 		v_offset := cast(u32) len(draw_list.vertices)
// 		for point in path
// 		{
// 			transformed_point := Vertex {
// 				pos = point.pos * scale + translate,
// 				u = 0,
// 				v = 0
// 			}
// 			append( & draw_list.vertices, transformed_point )
// 		}

// 		if len(path) > 2
// 		{
// 			indices := & draw_list.indices
// 			for index : u32 = 1; index < cast(u32) len(path) - 1; index += 1 {
// 				to_add := [3]u32 {
// 					v_offset,
// 					v_offset + index,
// 					v_offset + index + 1
// 				}
// 				append( indices, ..to_add[:] )
// 			}

// 			// Close the path by connecting the last vertex to the first two
// 			to_add := [3]u32 {
// 				v_offset,
// 				v_offset + cast(u32)(len(path) - 1),
// 				v_offset + 1
// 			}
// 			append( indices, ..to_add[:] )
// 		}
// 	}

// 	if glyph_index == Glyph(0) {
// 		return false
// 	}

// 	face := entry.parser_info.freetype_info
// 	error := freetype.load_glyph(face, u32(glyph_index), {.No_Bitmap, .No_Scale})
// 	if error != .Ok {
// 		return false
// 	}

// 	glyph := face.glyph
// 	if glyph.format != .Outline {
// 		return false
// 	}

// 	outline := &glyph.outline
// 	if outline.n_points == 0 {
// 		return false
// 	}

// 	draw            := Draw_Call_Default
// 	draw.pass        = Frame_Buffer_Pass.Glyph
// 	draw.start_index = cast(u32) len(ctx.draw_list.indices)

// 	contours := slice.from_ptr(cast( [^]i16)             outline.contours, int(outline.n_contours))
// 	points   := slice.from_ptr(cast( [^]freetype.Vector) outline.points,   int(outline.n_points))
// 	tags     := slice.from_ptr(cast( [^]u8)              outline.tags,     int(outline.n_points))

// 	path := &ctx.temp_path
// 	clear(path)

// 	outside := Vec2{ bounds_0.x - 21, bounds_0.y - 33 }

// 	start_index: int = 0
// 	for contour_index in 0 ..< int(outline.n_contours)
// 	{
// 		end_index   := int(contours[contour_index]) + 1
// 		prev_point  : Vec2
// 		first_point : Vec2

// 		for idx := start_index; idx < end_index; idx += 1
// 		{
// 			current_pos := Vec2 { f32( points[idx].x ), f32( points[idx].y ) }
// 			if ( tags[idx] & 1 ) == 0
// 			{
// 				// If current point is off-curve
// 				if (idx == start_index || (tags[ idx - 1 ] & 1) != 0)
// 				{
// 					// current is the first or following an on-curve point
// 					prev_point = current_pos
// 				}
// 				else
// 				{
// 					// current and previous are off-curve, calculate midpoint
// 					midpoint := (prev_point + current_pos) * 0.5
// 					append( path, Vertex { pos = midpoint } )  // Add midpoint as on-curve point
// 					if idx < end_index - 1
// 					{
// 						// perform interp from prev_point to current_pos via midpoint
// 						step := 1.0 / entry.curve_quality
// 						for alpha : f32 = 0.0; alpha <= 1.0; alpha += step
// 						{
// 							bezier_point := eval_point_on_bezier3( prev_point, midpoint, current_pos, alpha )
// 							append( path, Vertex{ pos = bezier_point } )
// 						}
// 					}

// 					prev_point = current_pos
// 				}
// 			}
// 			else
// 			{
// 				if idx == start_index {
// 					first_point = current_pos
// 				}
// 				if prev_point != (Vec2{}) {
// 					// there was an off-curve point before this
// 					append(path, Vertex{ pos = prev_point}) // Ensure previous off-curve is handled
// 				}
// 				append(path, Vertex{ pos = current_pos})
// 				prev_point = {}
// 			}
// 		}

// 		// ensure the contour is closed
// 		if path[0].pos != path[ len(path) - 1 ].pos {
// 			append(path, Vertex{pos = path[0].pos})
// 		}
// 		draw_filled_path(&ctx.draw_list, bounds_0, path[:], scale, translate)
// 		// draw_filled_path(&ctx.draw_list, bounds_0, path[:], scale, translate, ctx.debug_print_verbose)
// 		clear(path)
// 		start_index = end_index
// 	}

// 	if len(path) > 0 {
// 		// draw_filled_path(&ctx.draw_list, outside, path[:], scale, translate, ctx.debug_print_verbose)
// 		draw_filled_path(&ctx.draw_list, outside, path[:], scale, translate)
// 	}

// 	draw.end_index = cast(u32) len(ctx.draw_list.indices)
// 	if draw.end_index > draw.start_index {
// 		append( & ctx.draw_list.calls, draw)
// 	}

// 	return true
// }

// TODO(Ed): Is it better to cache the glyph vertices for when it must be re-drawn (directly or two atlas)?
cache_glyph :: proc(ctx : ^Context, font : Font_ID, glyph_index : Glyph, entry : ^Entry, bounds_0, bounds_1 : Vec2, scale, translate : Vec2) -> b32
{
	profile(#procedure)
	if glyph_index == Glyph(0) {
		return false
	}

	// Glyph shape handling are not abstractable between freetype and stb_truetype
	// if entry.parser_info.kind == .Freetype {
	// 	result := cache_glyph_freetype( ctx, font, glyph_index, entry, bounds_0, bounds_1, scale, translate )
	// 	return result
	// }

	shape, error := parser_get_glyph_shape(&entry.parser_info, glyph_index)
	assert(error == .None)
	if len(shape) == 0 {
		return false
	}

	outside := Vec2{bounds_0.x - 21, bounds_0.y - 33}

	draw            := Draw_Call_Default
	draw.pass        = Frame_Buffer_Pass.Glyph
	draw.start_index = u32(len(ctx.draw_list.indices))

	path := &ctx.temp_path
	clear(path)

	step := 1.0 / entry.curve_quality
	for edge in shape do #partial switch edge.type
	{
		case .Move:
			if len(path) > 0 {
				// draw_filled_path(&ctx.draw_list, outside, path[:], scale, translate, ctx.debug_print_verbose)
				draw_filled_path(&ctx.draw_list, outside, path[:], scale, translate)
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

			for index : f32 = 1; index <= entry.curve_quality; index += 1 {
				alpha := index * step
				append( path, Vertex { pos = eval_point_on_bezier3(p0, p1, p2, alpha) } )
			}

		case .Cubic:
			assert( len(path) > 0)
			p0 := path[ len(path) - 1].pos
			p1 := Vec2{ f32(edge.contour_x0), f32(edge.contour_y0) }
			p2 := Vec2{ f32(edge.contour_x1), f32(edge.contour_y1) }
			p3 := Vec2{ f32(edge.x), f32(edge.y) }

			for index : f32 = 1; index <= entry.curve_quality; index += 1 {
				alpha := index * step
				append( path, Vertex { pos = eval_point_on_bezier4(p0, p1, p2, p3, alpha) } )
			}
	}

	if len(path) > 0 {
		// draw_filled_path(&ctx.draw_list, outside, path[:], scale, translate, ctx.debug_print_verbose)
		draw_filled_path(&ctx.draw_list, outside, path[:], scale, translate)
	}

	draw.end_index = u32(len(ctx.draw_list.indices))
	if draw.end_index > draw.start_index {
		append( & ctx.draw_list.calls, draw)
	}

	parser_free_shape(&entry.parser_info, shape)
	return true
}

/*
	Called by:
	* can_batch_glyph : If it determines that the glyph was not detected and we haven't reached capacity in the atlas
	* draw_text_shape : Glyph
*/
cache_glyph_to_atlas :: proc ( ctx : ^Context,
	font        : Font_ID,
	glyph_index : Glyph,
	bounds      : GlyphBounds,
	bounds_size : Vec2,
	region_pos  : Vec2,
	region_size : Vec2,
	lru_code    : u64,
	atlas_index : i32,
	entry       : ^Entry,
	// region_kind : Atlas_Region_Kind,
	// region      : ^Atlas_Region,
	over_sample : Vec2 
)
{
	profile(#procedure)

	atlas             := & ctx.atlas
	glyph_buffer      := & ctx.glyph_buffer
	atlas_size        := Vec2 { f32(atlas.width), f32(atlas.height) }
	glyph_buffer_size := Vec2 { f32(glyph_buffer.width), f32(glyph_buffer.height) }
	glyph_padding     := cast(f32) atlas.glyph_padding

	// Draw oversized glyph to glyph render target (FBO)
	glyph_draw_scale       := over_sample * entry.size_scale
	glyph_draw_translate   := -1 * bounds.p0 * glyph_draw_scale + vec2( glyph_padding )

	// Allocate a glyph glyph render target region (FBO)
	gwidth_scaled_px := bounds_size.x * glyph_draw_scale.x + over_sample.x * glyph_padding + 1.0
	if i32(f32(glyph_buffer.batch_x) + gwidth_scaled_px) >= i32(glyph_buffer.width) {
		flush_glyph_buffer_to_atlas( ctx )
	}

	region_pos := region_pos

	dst_glyph_position := region_pos
	dst_glyph_size     := ceil(bounds_size * entry.size_scale + glyph_padding)
	dst_size           := (region_size)
	screenspace_x_form( & dst_glyph_position, & dst_glyph_size, atlas_size )
	screenspace_x_form( & region_pos,         & dst_size,       atlas_size )

	src_position := Vec2 { f32(glyph_buffer.batch_x), 0 }
	src_size     := (bounds_size * glyph_draw_scale + over_sample * glyph_padding)
	textspace_x_form( & src_position, & src_size, glyph_buffer_size )

	// Advance glyph_update_batch_x and calculate final glyph drawing transform
	glyph_draw_translate.x  = (glyph_draw_translate.x + f32(glyph_buffer.batch_x))
	glyph_buffer.batch_x   += i32(gwidth_scaled_px)
	screenspace_x_form( & glyph_draw_translate, & glyph_draw_scale, glyph_buffer_size )

	clear_target_region : Draw_Call
	{
		using clear_target_region
		pass        = .Atlas
		region      = .Ignore
		start_index = cast(u32) len(glyph_buffer.clear_draw_list.indices)

		blit_quad( & glyph_buffer.clear_draw_list,
			region_pos, region_pos + dst_size,
			{ 1.0, 1.0 },  { 1.0, 1.0 } )

		end_index = cast(u32) len(glyph_buffer.clear_draw_list.indices)
	}

	blit_to_atlas : Draw_Call
	{
		using blit_to_atlas
		pass        = .Atlas
		region      = .None
		start_index = cast(u32) len(glyph_buffer.draw_list.indices)

		blit_quad( & glyph_buffer.draw_list,
			dst_glyph_position, region_pos + dst_glyph_size,
			src_position,       src_position  + src_size )

		end_index = cast(u32) len(glyph_buffer.draw_list.indices)
	}

	append( & glyph_buffer.clear_draw_list.calls, clear_target_region )
	append( & glyph_buffer.draw_list.calls, blit_to_atlas )

	// Render glyph to glyph render target (FBO)
	cache_glyph( ctx, font, glyph_index, entry, bounds.p0, bounds.p1, glyph_draw_scale, glyph_draw_translate )
}

// ve_fontcache_clear_Draw_List
clear_draw_list :: #force_inline proc ( draw_list : ^Draw_List ) {
	clear( & draw_list.calls )
	clear( & draw_list.indices )
	clear( & draw_list.vertices )
}

directly_draw_massive_glyph :: proc( ctx : ^Context,
	entry : ^Entry,
	glyph : Glyph,
	bounds                       : GlyphBounds,
	bounds_size                  : Vec2,
	over_sample, position, scale : Vec2 )
{
	profile(#procedure)
	flush_glyph_buffer_to_atlas( ctx )

	glyph_padding     := f32(ctx.atlas.glyph_padding)
	glyph_buffer_size := Vec2 { f32(ctx.glyph_buffer.width), f32(ctx.glyph_buffer.height) }

	// Draw un-antialiased glyph to draw_buffer
	glyph_draw_scale     := over_sample * entry.size_scale
	glyph_draw_translate := -1 * bounds.p0 * glyph_draw_scale + vec2_from_scalar(glyph_padding)
	screenspace_x_form( & glyph_draw_translate, & glyph_draw_scale, glyph_buffer_size )

	cache_glyph( ctx, entry.id, glyph, entry, bounds.p0, bounds.p1, glyph_draw_scale, glyph_draw_translate )

	bounds_scaled := bounds_size * entry.size_scale

	// Figure out the source rect.
	glyph_position := Vec2 {}
	glyph_size     := glyph_padding + bounds_scaled * over_sample
	glyph_dst_size := glyph_padding + bounds_scaled

	// Figure out the destination rect.
	bounds_0_scaled := (bounds.p0 * entry.size_scale)
	dst             := position + scale * bounds_0_scaled - glyph_padding * scale
	dst_size        := glyph_dst_size * scale
	textspace_x_form( & glyph_position, & glyph_size, glyph_buffer_size )

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

// Constructs a triangle fan to fill a shape using the provided path
// outside_point represents the center point of the fan.
//
// Note(Original Author):
// WARNING: doesn't actually append Draw_Call; caller is responsible for actually appending the Draw_Call.
// ve_fontcache_draw_filled_path
draw_filled_path :: proc( draw_list : ^Draw_List, outside_point : Vec2, path : []Vertex,
	scale     := Vec2 { 1, 1 },
	translate := Vec2 { 0, 0 }
	// debug_print_verbose : b32 = false
) #no_bounds_check
{
	profile(#procedure)
	// if debug_print_verbose
	// {
	// 	log("outline_path:")
	// 	for point in path {
	// 		vec := point.pos * scale + translate
	// 		logf(" %0.2f %0.2f", vec.x, vec.y )
	// 	}
	// }

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

draw_text_batch :: #force_inline proc (ctx: ^Context, entry: ^Entry, shaped: ^Shaped_Text,
	// batch_start_idx, batch_end_idx : i32,
	glyph_pack : #soa[]GlyphPackEntry,
	position, scale                : Vec2,
	snap_width, snap_height        : f32 )
{
	profile(#procedure)
	flush_glyph_buffer_to_atlas(ctx)

	atlas         := & ctx.atlas
	atlas_size    := Vec2{ f32(atlas.width), f32(atlas.height) }
	glyph_padding := atlas.glyph_padding

	call             := Draw_Call_Default
	call.pass         = .Target
	call.colour       = ctx.colour

	for glyph, index in glyph_pack
	{
		profile("cached")

		glyph_scale      := glyph.bounds_size * entry.size_scale + glyph_padding
		bounds_0_scaled  := ceil(glyph.bounds.p0 * entry.size_scale - 0.5 )
		dst_pos          := glyph.translate + bounds_0_scaled * scale
		dst_scale        := glyph_scale * scale
		src_pos          := glyph.region_pos

		textspace_x_form( & src_pos, & glyph_scale, atlas_size )

		call.start_index  = u32(len(ctx.draw_list.indices))

		blit_quad(& ctx.draw_list,
			dst_pos, dst_pos + dst_scale,
			src_pos, src_pos + glyph_scale )

		call.end_index = u32(len(ctx.draw_list.indices))

		append(&ctx.draw_list.calls, call)
	}
}

GlyphBounds :: struct {
	p0, p1 : Vec2
}

GlyphPackEntry :: struct {
	bounds       : GlyphBounds,
	bounds_size  : Vec2,
	over_sample  : Vec2,
	translate    : Vec2,
	region_pos   : Vec2,
	region_size  : Vec2,
	lru_code     : u64,
	atlas_index  : i32,
	index        : Glyph,
	shape_id     : i32,
	region_kind  : Atlas_Region_Kind, 
	in_atlas     : b8,
	should_cache : b8,
}

Glyph_Sub_Pack :: struct {
	pack : #soa[]GlyphPackEntry,
	num  : i32
}

// Helper for draw_text, all raw text content should be confirmed to be either formatting or visible shapes before getting cached.
draw_text_shape :: #force_inline proc( ctx : ^Context,
	font                    : Font_ID,
	entry                   : ^Entry,
	shaped                  : ^Shaped_Text,
	position,   scale       : Vec2,
	snap_width, snap_height : f32
) -> (cursor_pos : Vec2) #no_bounds_check
{
	profile(#procedure)

	oversized : Glyph_Sub_Pack = {}
	to_cache  : Glyph_Sub_Pack = {}
	cached    : Glyph_Sub_Pack = {}

	profile_begin("soa allocation")
	glyph_pack, glyph_pack_alloc_error := make_soa( #soa[]GlyphPackEntry, len(shaped.glyphs), allocator = context.temp_allocator )

	alloc_error : Allocator_Error
	oversized.pack, alloc_error = make_soa( #soa[]GlyphPackEntry, len(shaped.glyphs), allocator = context.temp_allocator )
	to_cache.pack,  alloc_error = make_soa( #soa[]GlyphPackEntry, len(shaped.glyphs), allocator = context.temp_allocator )
	cached.pack,    alloc_error = make_soa( #soa[]GlyphPackEntry, len(shaped.glyphs), allocator = context.temp_allocator )
	profile_end()

	append_sub_pack :: #force_inline proc "contextless" ( sub : ^Glyph_Sub_Pack, entry : GlyphPackEntry )
	{
		sub.pack[sub.num] = entry
		sub.num += 1
	}
	sub_slice :: #force_inline proc "contextless" ( sub : Glyph_Sub_Pack) -> #soa[]GlyphPackEntry { return sub.pack[: sub.num] }

	atlas := & ctx.atlas

	SOA_Setup:
	{
		profile("SOA setup")

		profile_begin("index & translate")
		for & glyph, index in glyph_pack
		{
			glyph.shape_id = cast(i32) index
			glyph.index    = shaped.glyphs[ index ]
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
			glyph.lru_code    = font_glyph_lru_code(entry.id, glyph.index)
			glyph.bounds      = parser_get_bounds( & entry.parser_info, glyph.index )
			glyph.bounds_size = glyph.bounds.p1 - glyph.bounds.p0
		}
		profile_end()

		profile_begin("region & oversized segregation")
		for & glyph, index in glyph_pack
		{
			glyph.region_kind, 
			glyph.over_sample = decide_codepoint_region( ctx.atlas, ctx.glyph_buffer, entry.size_scale, glyph.index, glyph.bounds_size )
		}
		profile_end()

		profile_begin("caching setup")
		for & glyph, index in glyph_pack
		{
			region := atlas.regions[glyph.region_kind]
			if glyph.region_kind == .E {
				append_sub_pack(& oversized, glyph)
				continue
			}

			glyph.atlas_index =  lru_get( & region.state, glyph.lru_code )
			glyph.in_atlas, glyph.should_cache  = check_and_reserve_slot_in_atlas( ctx, glyph.index, glyph.lru_code, & glyph.atlas_index, region )
			glyph.region_pos, glyph.region_size = atlas_region_bbox(region ^, glyph.atlas_index)

			if glyph.should_cache {
				profile("append to_cache")
				append_sub_pack(& to_cache, glyph)
				mark_batch_codepoint_seen(ctx, glyph.lru_code)
				cache_glyph_to_atlas( ctx, font, glyph.index, glyph.bounds, glyph.bounds_size, glyph.region_pos, glyph.region_size, glyph.lru_code, glyph.atlas_index, entry, glyph.over_sample  )
				continue
			}
			else {
				profile("append cached")
				append_sub_pack(& cached, glyph)
				mark_batch_codepoint_seen(ctx, glyph.lru_code)
			}
		}
		profile_end()
	}
	
	draw_text_batch( ctx, entry, shaped, sub_slice(to_cache), position, scale, snap_width, snap_height )
	reset_batch_codepoint_state( ctx )

	draw_text_batch( ctx, entry, shaped, sub_slice(cached), position, scale, snap_width , snap_height )
	reset_batch_codepoint_state( ctx )

	profile_begin("generate oversized glyphs draw_list")
	flush_glyph_buffer_to_atlas(ctx)

	for & glyph, index in sub_slice(oversized)
	{
		directly_draw_massive_glyph(ctx, entry, glyph.index,
			glyph.bounds,
			glyph.bounds_size,
			glyph.over_sample, glyph.translate, scale )
	}
	reset_batch_codepoint_state( ctx )

	profile_end()
	
	cursor_pos = position + shaped.end_cursor_pos * scale
	return
}

flush_glyph_buffer_to_atlas :: #force_inline proc( ctx : ^Context )
{
	profile(#procedure)
	// Flush Draw_Calls to draw list
	merge_draw_list( & ctx.draw_list, & ctx.glyph_buffer.clear_draw_list )
	merge_draw_list( & ctx.draw_list, & ctx.glyph_buffer.draw_list)
	clear_draw_list( & ctx.glyph_buffer.draw_list )
	clear_draw_list( & ctx.glyph_buffer.clear_draw_list )

	// Clear glyph render target (FBO)
	if ctx.glyph_buffer.batch_x != 0
	{
		call := Draw_Call_Default
		call.pass              = .Glyph
		call.start_index       = 0
		call.end_index         = 0
		call.clear_before_draw = true
		append( & ctx.draw_list.calls, call )
		ctx.glyph_buffer.batch_x = 0
	}
}

// ve_fontcache_merge_Draw_List
merge_draw_list :: #force_inline proc ( #no_alias dst, src : ^Draw_List )
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

optimize_draw_list :: proc (draw_list: ^Draw_List, call_offset: int)
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
