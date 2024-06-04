package VEFontCache

FrameBufferPass :: enum u32 {
	None             = 0,
	Glyph            = 1,
	Atlas            = 2,
	Target           = 3,
	Target_Unchanged = 4,
}

DrawCall :: struct {
	pass              : FrameBufferPass,
	start_index       : u32,
	end_index         : u32,
	clear_before_draw : b32,
	region            : AtlasRegionKind,
	colour            : [4]f32,
}

DrawCall_Default :: DrawCall {
	pass              = .None,
	start_index       = 0,
	end_index         = 0,
	clear_before_draw = false,
	region            = .A,
	colour            = { 1.0, 1.0, 1.0, 1.0 }
}

DrawList :: struct {
	vertices : Array(Vertex),
	indices  : Array(u32),
	calls    : Array(DrawCall),
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

// ve_fontcache_clear_drawlist
clear_draw_list :: proc( draw_list : ^DrawList ) {
	clear( draw_list.calls )
	clear( draw_list.indices )
	clear( draw_list.vertices )
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

// ve_fontcache_flush_drawlist
flush_draw_list :: proc( ctx : ^Context ) {
	assert( ctx != nil )
	clear_draw_list( & ctx.draw_list )
}

// ve_fontcache_drawlist
get_draw_list :: proc( ctx : ^Context ) -> ^DrawList {
	assert( ctx != nil )
	return & ctx.draw_list
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
