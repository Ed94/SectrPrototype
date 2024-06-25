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
	weight_start   := (1 - alpha) * (1 - alpha)
	weight_control := 2.0 * (1 - alpha) * alpha
	weight_end     := alpha * alpha

	starting_point := p0 * weight_start
	control_point  := p1 * weight_control
	end_point      := p2 * weight_end

	point := starting_point + control_point + end_point
	return point
}

// For a provided alpha value,
// allows the function to calculate the position of a point along the curve at any given fraction of its total length
// ve_fontcache_eval_bezier (cubic)
eval_point_on_bezier4 :: proc( p0, p1, p2, p3 : Vec2, alpha : f32 ) -> Vec2
{
	weight_start := (1 - alpha) * (1 - alpha) * (1 - alpha)
	weight_c_a   := 3 * (1 - alpha) * (1 - alpha) * alpha
	weight_c_b   := 3 * (1 - alpha) * alpha * alpha
	weight_end   := alpha * alpha * alpha

	start_point := p0 * weight_start
	control_a   := p1 * weight_c_a
	control_b   := p2 * weight_c_b
	end_point   := p3 * weight_end

	point := start_point + control_a + control_b + end_point
	return point
}

reset_batch_codepoint_state :: proc( ctx : ^Context ) {
	clear( & ctx.temp_codepoint_seen )
	ctx.temp_codepoint_seen_num = 0
}

screenspace_x_form :: proc( position, scale : ^Vec2, width, height : f32 ) {
	quotient    := 1.0 / Vec2 { width, height }
	(position^) = (position^) * quotient * 2.0 - 1.0
	(scale^)    = (scale^)    * quotient * 2.0
}

textspace_x_form :: proc( position, scale : ^Vec2, width, height : f32 ) {
	quotient := 1.0 / Vec2 { width, height }
	(position^) *= quotient
	(scale^)    *= quotient
}