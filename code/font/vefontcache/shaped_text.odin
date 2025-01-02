package vefontcache

Shaped_Text :: struct {
	font               : Font_ID,
	entry              : ^Entry,

	glyphs             : [dynamic]Glyph,
	positions          : [dynamic]Vec2,
	end_cursor_pos     : Vec2,
	size               : Vec2,
}

Shaped_Text_Cache :: struct {
	storage       : [dynamic]Shaped_Text,
	state         : LRU_Cache,
	next_cache_id : i32,
}

shape_lru_hash :: #force_inline proc "contextless" ( hash : ^u64, bytes : []byte ) {
	for value in bytes {
		(hash^) = (( (hash^) << 8) + (hash^) ) + u64(value)
	}
}

ShapedTextUncachedProc :: #type proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : Entry, output : ^Shaped_Text )

shaper_shape_text_cached :: #force_inline proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : Entry, shape_text_uncached : $ShapedTextUncachedProc ) -> (shaped_text : Shaped_Text)
{
	profile(#procedure)
	font        := font
	font_bytes  := slice_ptr( transmute(^byte) & font,  size_of(Font_ID) )
	text_bytes  := transmute( []byte) text_utf8

	lru_code : u64
	shape_lru_hash( & lru_code, font_bytes )
	shape_lru_hash( & lru_code, text_bytes )

	shape_cache := & ctx.shape_cache
	state       := & ctx.shape_cache.state

	shape_cache_idx := lru_get( state, lru_code )
	if shape_cache_idx == -1
	{
		if shape_cache.next_cache_id < i32(state.capacity) {
			shape_cache_idx            = shape_cache.next_cache_id
			shape_cache.next_cache_id += 1
			evicted := lru_put( state, lru_code, shape_cache_idx )
		}
		else
		{
			next_evict_idx := lru_get_next_evicted( state ^ )
			// assert( next_evict_idx != 0xFFFFFFFFFFFFFFFF )

			shape_cache_idx = lru_peek( state ^, next_evict_idx, must_find = true )
			// assert( shape_cache_idx != - 1 )

			lru_put( state, lru_code, shape_cache_idx )
		}

		storage_entry := & shape_cache.storage[ shape_cache_idx ]
		shape_text_uncached( ctx, font, text_utf8, entry, storage_entry )

		shaped_text = storage_entry ^
		return
	}

	shaped_text = shape_cache.storage[ shape_cache_idx ]
	return
}

shaper_shape_text_uncached_advanced :: #force_inline proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : Entry, output : ^Shaped_Text )
{
	profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )

	clear( & output.glyphs )
	clear( & output.positions )

	ascent_i32, descent_i32, line_gap_i32 := parser_get_font_vertical_metrics( entry.parser_info )
	ascent      := f32(ascent_i32)
	descent     := f32(descent_i32)
	line_gap    := f32(line_gap_i32)
	line_height := (ascent - descent + line_gap) * entry.size_scale

	shaper_shape_from_text( & ctx.shaper_ctx, entry.parser_info, entry.shaper_info, output, text_utf8, ascent_i32, descent_i32, line_gap_i32, entry.size, entry.size_scale )
}

shaper_shape_from_text_latin :: #force_inline proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : Entry, output : ^Shaped_Text )
{	
	profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )

	clear( & output.glyphs )
	clear( & output.positions )

	ascent_i32, descent_i32, line_gap_i32 := parser_get_font_vertical_metrics( entry.parser_info )
	ascent      := f32(ascent_i32)
	descent     := f32(descent_i32)
	line_gap    := f32(line_gap_i32)
	line_height := (ascent - descent + line_gap) * entry.size_scale

	line_count     : int = 1
	max_line_width : f32 = 0
	position       : Vec2

	prev_codepoint : rune
	for codepoint, index in text_utf8
	{
		if prev_codepoint > 0 {
			kern       := parser_get_codepoint_kern_advance( entry.parser_info, prev_codepoint, codepoint )
			position.x += f32(kern) * entry.size_scale
		}
		if codepoint == '\n'
		{
			line_count    += 1
			max_line_width = max(max_line_width, position.x)
			position.x     = 0.0
			position.y    -= line_height
			position.y     = position.y
			prev_codepoint = rune(0)
			continue
		}
		if abs( entry.size ) <= ctx.shaper_ctx.adv_snap_small_font_threshold {
			position.x = ceil(position.x)
		}

		glyph_index := parser_find_glyph_index( entry.parser_info, codepoint )
		is_glyph_empty    := parser_is_glyph_empty( entry.parser_info,glyph_index )
		if ! is_glyph_empty
		{
			append( & output.glyphs, glyph_index)
			append( & output.positions, Vec2 {
				floor(position.x),
				floor(position.y)
			})
		}

		advance, _ := parser_get_codepoint_horizontal_metrics( entry.parser_info, codepoint )
		position.x += f32(advance) * entry.size_scale
		prev_codepoint = codepoint
	}

	output.end_cursor_pos = position
	max_line_width        = max(max_line_width, position.x)

	output.size.x = max_line_width
	output.size.y = f32(line_count) * line_height
}
