package VEFontCache

ShapedText :: struct {
	// draw_list      : DrawList,
	glyphs         : [dynamic]Glyph,
	positions      : [dynamic]Vec2,
	end_cursor_pos : Vec2,
	size           : Vec2,
	// storage_hash   : u64,
	// draw_hash      : u64,
}

ShapedTextCache :: struct {
	storage       : [dynamic]ShapedText,
	state         : LRU_Cache,
	next_cache_id : i32,
}


// shape_draw_hash :: #force_inline proc "contextless" ( shaped : ^ShapedText, pos, scale : Vec2 ) -> (draw_hash : u64)
// {
// 	pos   := pos
// 	scale := scale
// 	pos_bytes   := slice_ptr( transmute(^byte) & pos,   size_of(Vec2))
// 	scale_bytes := slice_ptr( transmute(^byte) & scale, size_of(Vec2))

// 	draw_hash = shaped.storage_hash
// 	shape_lru_hash( & shaped.draw_hash, pos_bytes )
// 	shape_lru_hash( & shaped.draw_hash, scale_bytes )
// 	return
// }

// shape_lru_hash_og :: #force_inline proc "contextless" ( label : string ) -> u64 {
// 	hash : u64
// 	for str_byte in transmute([]byte) label {
// 		hash = ((hash << 8) + hash) + u64(str_byte)
// 	}
// 	return hash
// }

shape_lru_hash :: #force_inline proc "contextless" ( hash : ^u64, bytes : []byte ) {
	for value in bytes {
		(hash^) = (( (hash^) << 8) + (hash^) ) + u64(value)
	}
}

shape_text_cached :: proc( ctx : ^Context, font : FontID, text_utf8 : string, entry : ^Entry ) -> ^ShapedText
{
	// profile(#procedure)
	font        := font
	font_bytes  := slice_ptr( transmute(^byte) & font,  size_of(FontID) )
	text_bytes  := transmute( []byte) text_utf8

	lru_code : u64
	shape_lru_hash( & lru_code, font_bytes )
	shape_lru_hash( & lru_code, text_bytes )

	// @static buffer : [64 * Kilobyte]byte
	// text_size       := len(text_utf8)
	// sice_end_offset := size_of(FontID) + len(text_utf8)

	// buffer_slice := buffer[:]
	// copy( buffer_slice, font_bytes )

	// buffer_slice_post_font := buffer[ size_of(FontID) : sice_end_offset ]
	// copy( buffer_slice_post_font, text_bytes )

	// lru_code := shape_lru_hash_og( transmute(string) buffer[: sice_end_offset ] )

	shape_cache := & ctx.shape_cache
	state       := & ctx.shape_cache.state

	shape_cache_idx := LRU_get( state, lru_code )
	if shape_cache_idx == -1
	{
		if shape_cache.next_cache_id < i32(state.capacity) {
			shape_cache_idx            = shape_cache.next_cache_id
			shape_cache.next_cache_id += 1
			evicted := LRU_put( state, lru_code, shape_cache_idx )
			assert( evicted == lru_code )
		}
		else
		{
			next_evict_idx := LRU_get_next_evicted( state )
			assert( next_evict_idx != 0xFFFFFFFFFFFFFFFF )

			shape_cache_idx = LRU_peek( state, next_evict_idx, must_find = true )
			assert( shape_cache_idx != - 1 )

			LRU_put( state, lru_code, shape_cache_idx )
		}

		shape_entry := & shape_cache.storage[ shape_cache_idx ]
		// shape_entry.storage_hash = lru_code
		shape_text_uncached( ctx, font, text_utf8, entry, shape_entry )
	}

	return & shape_cache.storage[ shape_cache_idx ]
}

shape_text_uncached :: proc( ctx : ^Context, font : FontID, text_utf8 : string, entry : ^Entry, output : ^ShapedText )
{
	// profile(#procedure)
	assert( ctx != nil )
	assert( font >= 0 && int(font) < len(ctx.entries) )

	use_full_text_shape := ctx.text_shape_adv

	clear( & output.glyphs )
	clear( & output.positions )

	ascent_i32, descent_i32, line_gap_i32 := parser_get_font_vertical_metrics( & entry.parser_info )
	ascent      := f32(ascent_i32)
	descent     := f32(descent_i32)
	line_gap    := f32(line_gap_i32)
	line_height := (ascent - descent + line_gap) * entry.size_scale

	if use_full_text_shape
	{
		// assert( entry.shaper_info != nil )
		shaper_shape_from_text( & ctx.shaper_ctx, & entry.shaper_info, output, text_utf8, ascent_i32, descent_i32, line_gap_i32, entry.size, entry.size_scale )
		// TODO(Ed): Need to be able to provide the text height as well
		return
	}
	else
	{
		// Note(Original Author):
		// We use our own fallback dumbass text shaping.
		// WARNING: PLEASE USE HARFBUZZ. GOOD TEXT SHAPING IS IMPORTANT FOR INTERNATIONALISATION.

		line_count     : int = 1
		max_line_width : f32 = 0
		position       : Vec2

		prev_codepoint : rune
		for codepoint in text_utf8
		{
			if prev_codepoint > 0 {
				kern       := parser_get_codepoint_kern_advance( & entry.parser_info, prev_codepoint, codepoint )
				position.x += f32(kern) * entry.size_scale
			}
			if codepoint == '\n'
			{
				line_count    += 1
				max_line_width = max(max_line_width, position.x)
				position.x     = 0.0
				position.y    -= line_height
				position.y     = ceil(position.y)
				prev_codepoint = rune(0)
				continue
			}
			if abs( entry.size ) <= Advance_Snap_Smallfont_Size {
				position.x = ceil( position.x )
			}

			append( & output.glyphs, parser_find_glyph_index( & entry.parser_info, codepoint ))
			advance, _ := parser_get_codepoint_horizontal_metrics( & entry.parser_info, codepoint )

			append( & output.positions, Vec2 {
				ceil(position.x),
				position.y
			})

			position.x    += f32(advance) * entry.size_scale
			prev_codepoint = codepoint
		}

		output.end_cursor_pos = position
		max_line_width        = max(max_line_width, position.x)

		output.size.x = max_line_width
		output.size.y = f32(line_count) * line_height
	}
}
