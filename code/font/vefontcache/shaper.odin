package vefontcache
/*
Note(Ed): The only reason I didn't directly use harfbuzz is because hamza exists and seems to be under active development as an alternative.
*/

import "core:c"
import "thirdparty:harfbuzz"

shape_lru_code :: djb8_hash_32

Shaped_Text :: struct {
	glyphs             : [dynamic]Glyph,
	positions          : [dynamic]Vec2,
	end_cursor_pos     : Vec2,
	size               : Vec2,
	entry              : ^Entry,
	font               : Font_ID,
}

Shaped_Text_Cache :: struct {
	storage       : [dynamic]Shaped_Text,
	state         : LRU_Cache,
	next_cache_id : i32,
}

Shaper_Shape_Text_Uncached_Proc :: #type proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : Entry, output : ^Shaped_Text )

Shaper_Kind :: enum {
	Naive    = 0,
	Harfbuzz = 1,
}

Shaper_Context :: struct {
	hb_buffer : harfbuzz.Buffer,

	snap_glyph_position           : b32,
	adv_snap_small_font_threshold : f32,
}

Shaper_Info :: struct {
	blob : harfbuzz.Blob,
	face : harfbuzz.Face,
	font : harfbuzz.Font,
}

shaper_init :: proc( ctx : ^Shaper_Context )
{
	ctx.hb_buffer = harfbuzz.buffer_create()
	assert( ctx.hb_buffer != nil, "VEFontCache.shaper_init: Failed to create harfbuzz buffer")
}

shaper_shutdown :: proc( ctx : ^Shaper_Context )
{
	if ctx.hb_buffer != nil {
		harfbuzz.buffer_destroy( ctx.hb_buffer )
	}
}

shaper_load_font :: proc( ctx : ^Shaper_Context, label : string, data : []byte, user_data : rawptr = nil ) -> (info : Shaper_Info)
{
	using info
	blob = harfbuzz.blob_create( raw_data(data), cast(c.uint) len(data), harfbuzz.Memory_Mode.READONLY, user_data, nil )
	face = harfbuzz.face_create( blob, 0 )
	font = harfbuzz.font_create( face )
	return
}

shaper_unload_font :: proc( ctx : ^Shaper_Info )
{
	using ctx
	if blob != nil do harfbuzz.font_destroy( font )
	if face != nil do harfbuzz.face_destroy( face )
	if blob != nil do harfbuzz.blob_destroy( blob )
}

shaper_shape_from_text :: #force_inline proc( ctx : ^Shaper_Context, parser_info : Parser_Font_Info, info : Shaper_Info, output :^Shaped_Text, text_utf8 : string,
	ascent, descent, line_gap : i32, size, size_scale : f32 )
{
	profile(#procedure)
	current_script := harfbuzz.Script.UNKNOWN
	hb_ucfunc      := harfbuzz.unicode_funcs_get_default()
	harfbuzz.buffer_clear_contents( ctx.hb_buffer )
	assert( info.font != nil )

	ascent   := f32(ascent)
	descent  := f32(descent)
	line_gap := f32(line_gap)

	max_line_width := f32(0)
	line_count     := 1
	line_height    := ((ascent - descent + line_gap) * size_scale)

	position : Vec2
	shape_run :: proc( parser_info : Parser_Font_Info, buffer : harfbuzz.Buffer, script : harfbuzz.Script, font : harfbuzz.Font, output : ^Shaped_Text,
		position : ^Vec2, max_line_width: ^f32, line_count: ^int,
		ascent, descent, line_gap, size, size_scale: f32,
		snap_shape_pos : b32, adv_snap_small_font_threshold : f32 )
	{
		profile(#procedure)
		// Set script and direction. We use the system's default langauge.
		// script = HB_SCRIPT_LATIN
		harfbuzz.buffer_set_script( buffer, script )
		harfbuzz.buffer_set_direction( buffer, harfbuzz.script_get_horizontal_direction( script ))
		harfbuzz.buffer_set_language( buffer, harfbuzz.language_get_default() )

		// Perform the actual shaping of this run using HarfBuzz.
		harfbuzz.buffer_set_content_type( buffer, harfbuzz.Buffer_Content_Type.UNICODE )
		harfbuzz.shape( font, buffer, nil, 0 )

		// Loop over glyphs and append to output buffer.
		glyph_count : u32
		glyph_infos     := harfbuzz.buffer_get_glyph_infos( buffer, & glyph_count )
		glyph_positions := harfbuzz.buffer_get_glyph_positions( buffer, & glyph_count )

		line_height := (ascent - descent + line_gap) * size_scale

		for index : i32; index < i32(glyph_count); index += 1
		{
			hb_glyph     := glyph_infos[ index ]
			hb_gposition := glyph_positions[ index ]
			glyph_id     := cast(Glyph) hb_glyph.codepoint

			if hb_glyph.cluster > 0
			{
				(max_line_width^)     = max( max_line_width^, position.x )
				position.x            = 0.0
				position.y           -= line_height
				position.y            = floor(position.y)
				(line_count^)         += 1
				continue
			}
			if abs( size ) <= adv_snap_small_font_threshold
			{
				(position^) = ceil( position^ )
			}

			glyph_pos := position^
			offset    := Vec2 { f32(hb_gposition.x_offset), f32(hb_gposition.y_offset) } * size_scale
			glyph_pos += offset

			if snap_shape_pos {
				glyph_pos = ceil(glyph_pos)
			}

			advance := Vec2 { 
				f32(hb_gposition.x_advance) * size_scale, 
				f32(hb_gposition.y_advance) * size_scale
			}
			(position^)          += advance
			(max_line_width^)     = max(max_line_width^, position.x)

			is_empty := parser_is_glyph_empty(parser_info, glyph_id)
			if ! is_empty {
				append( & output.glyphs, glyph_id )
				append( & output.positions, glyph_pos)
			}
		}

		output.end_cursor_pos = position^
		harfbuzz.buffer_clear_contents( buffer )
	}

	// Note(Original Author):
	// We first start with simple bidi and run logic.
	// True CTL is pretty hard and we don't fully support that; patches welcome!

	for codepoint, byte_offset in text_utf8
	{
		hb_codepoint := cast(harfbuzz.Codepoint) codepoint

		script := harfbuzz.unicode_script( hb_ucfunc, hb_codepoint )

		// Can we continue the current run?
		ScriptKind :: harfbuzz.Script

		special_script : b32 = script == ScriptKind.UNKNOWN || script == ScriptKind.INHERITED || script == ScriptKind.COMMON
		if special_script || script == current_script || byte_offset == 0 {
			harfbuzz.buffer_add( ctx.hb_buffer, hb_codepoint, codepoint == '\n' ? 1 : 0 )
			current_script = special_script ? current_script : script
			continue
		}

		// End current run since we've encountered a script change.
		shape_run( parser_info,
			ctx.hb_buffer, current_script, info.font, output, 
			& position, & max_line_width, & line_count, 
			ascent, descent, line_gap, size, size_scale, 
			ctx.snap_glyph_position, ctx.adv_snap_small_font_threshold
		)
		harfbuzz.buffer_add( ctx.hb_buffer, hb_codepoint, codepoint == '\n' ? 1 : 0 )
		current_script = script
	}

	// End the last run if needed
	shape_run( parser_info,
		ctx.hb_buffer, current_script, info.font, output, 
		& position, & max_line_width, & line_count, 
		ascent, descent, line_gap, size, size_scale, 
		ctx.snap_glyph_position, ctx.adv_snap_small_font_threshold
	)

	// Set the final size
	output.size.x = max_line_width
	output.size.y = f32(line_count) * line_height
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

shaper_shape_text_cached :: #force_inline proc( ctx : ^Context, font : Font_ID, text_utf8 : string, entry : Entry, shape_text_uncached : $Shaper_Shape_Text_Uncached_Proc ) -> (shaped_text : Shaped_Text)
{
	profile(#procedure)
	font        := font
	font_bytes  := slice_ptr( transmute(^byte) & font,  size_of(Font_ID) )
	text_bytes  := transmute( []byte) text_utf8

	lru_code : u32
	shape_lru_code( & lru_code, font_bytes )
	shape_lru_code( & lru_code, text_bytes )

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
			assert( next_evict_idx != 0xFFFFFFFF )

			shape_cache_idx = lru_peek( state ^, next_evict_idx, must_find = true )
			assert( shape_cache_idx != - 1 )

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
