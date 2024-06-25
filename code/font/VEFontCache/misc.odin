package VEFontCache

font_glyph_lru_code :: #force_inline proc( font : FontID, glyph_index : Glyph ) -> (lru_code : u64)
{
	// font        := font
	// glyph_index := glyph_index

	// font_bytes  := slice_ptr( transmute(^byte) & font,        size_of(FontID) )
	// glyph_bytes := slice_ptr( transmute(^byte) & glyph_index, size_of(Glyph) )

	// buffer : [32]byte
	// copy( buffer[:], font_bytes )
	// copy( buffer[ len(font_bytes) :], glyph_bytes )
	// hash := fnv64a( transmute([]byte) buffer[: size_of(FontID) + size_of(Glyph) ] )
	// lru_code = hash
	lru_code = u64(glyph_index) + ( ( 0x100000000 * u64(font) ) & 0xFFFFFFFF00000000 )
	return
}

shape_lru_hash :: #force_inline proc( label : string ) -> u64 {
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
	// p0    := vec2_64_from_vec2(p0)
	// p1    := vec2_64_from_vec2(p1)
	// p2    := vec2_64_from_vec2(p2)
	// alpha := f64(alpha)

	weight_start   := (1 - alpha) * (1 - alpha)
	weight_control := 2.0 * (1 - alpha) * alpha
	weight_end     := alpha * alpha

	starting_point := p0 * weight_start
	control_point  := p1 * weight_control
	end_point      := p2 * weight_end

	point := starting_point + control_point + end_point
	return { f32(point.x), f32(point.y) }
}

// For a provided alpha value,
// allows the function to calculate the position of a point along the curve at any given fraction of its total length
// ve_fontcache_eval_bezier (cubic)
eval_point_on_bezier4 :: proc( p0, p1, p2, p3 : Vec2, alpha : f32 ) -> Vec2
{
	// p0    := vec2_64_from_vec2(p0)
	// p1    := vec2_64_from_vec2(p1)
	// p2    := vec2_64_from_vec2(p2)
	// p3    := vec2_64_from_vec2(p3)
	// alpha := f64(alpha)

	weight_start := (1 - alpha) * (1 - alpha) * (1 - alpha)
	weight_c_a   := 3 * (1 - alpha) * (1 - alpha) * alpha
	weight_c_b   := 3 * (1 - alpha) * alpha * alpha
	weight_end   := alpha * alpha * alpha

	start_point := p0 * weight_start
	control_a   := p1 * weight_c_a
	control_b   := p2 * weight_c_b
	end_point   := p3 * weight_end

	point := start_point + control_a + control_b + end_point
	return { f32(point.x), f32(point.y) }
}

reset_batch_codepoint_state :: proc( ctx : ^Context ) {
	clear_map( & ctx.temp_codepoint_seen )
	ctx.temp_codepoint_seen_num = 0
}

screenspace_x_form :: proc( position, scale : ^Vec2, width, height : f32 ) {
	pos_64   := vec2_64_from_vec2(position^)
	scale_64 := vec2_64_from_vec2(scale^)
	width    := f64(width)
	height   := f64(height)

	quotient : Vec2_64 = 1.0 / { width, height }
	// quotient : Vec2 = 1.0 / { width, height }
	pos_64      = pos_64   * quotient * 2.0 - 1.0
	scale_64    = scale_64 * quotient * 2.0

	(position^) = { f32(pos_64.x), f32(pos_64.y) }
	(scale^)    = { f32(scale_64.x), f32(scale_64.y) }
}

textspace_x_form :: proc( position, scale : ^Vec2, width, height : f32 ) {
	pos_64   := vec2_64_from_vec2(position^)
	scale_64 := vec2_64_from_vec2(scale^)
	width    := f64(width)
	height   := f64(height)

	quotient : Vec2_64 = 1.0 / { width, height }
	// quotient : Vec2 = 1.0 / { width, height }
	pos_64   *= quotient
	scale_64 *= quotient

	(position^) = { f32(pos_64.x), f32(pos_64.y) }
	(scale^)    = { f32(scale_64.x), f32(scale_64.y) }
}
