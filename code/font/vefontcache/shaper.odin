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

Shaper_Shape_Text_Uncached_Proc :: #type proc( ctx : ^Shaper_Context, entry : Entry, font_px_Size, font_scale : f32, text_utf8 : string, output : ^Shaped_Text )

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

shaper_load_font :: #force_inline proc( ctx : ^Shaper_Context, label : string, data : []byte, user_data : rawptr = nil ) -> (info : Shaper_Info)
{
	using info
	blob = harfbuzz.blob_create( raw_data(data), cast(c.uint) len(data), harfbuzz.Memory_Mode.READONLY, user_data, nil )
	face = harfbuzz.face_create( blob, 0 )
	font = harfbuzz.font_create( face )
	return
}

shaper_unload_font :: #force_inline proc( ctx : ^Shaper_Info )
{
	using ctx
	if blob != nil do harfbuzz.font_destroy( font )
	if face != nil do harfbuzz.face_destroy( face )
	if blob != nil do harfbuzz.blob_destroy( blob )
}

shaper_shape_harfbuzz :: #force_inline proc( ctx : ^Shaper_Context, text_utf8 : string, entry : Entry, font_px_Size, font_scale : f32, output :^Shaped_Text )
{
	profile(#procedure)
	current_script := harfbuzz.Script.UNKNOWN
	hb_ucfunc      := harfbuzz.unicode_funcs_get_default()
	harfbuzz.buffer_clear_contents( ctx.hb_buffer )

	ascent   := entry.ascent
	descent  := entry.descent
	line_gap := entry.line_gap
	
	max_line_width := f32(0)
	line_count     := 1
	line_height    := ((ascent - descent + line_gap) * font_scale)

	position : Vec2
	shape_run :: proc( output : ^Shaped_Text,
		entry  : Entry, 
		buffer : harfbuzz.Buffer,
		script : harfbuzz.Script, 
		
		position       : ^Vec2, 
		max_line_width : ^f32, 
		line_count     : ^int,

		font_px_size : f32,
		font_scale   : f32,

		snap_shape_pos                : b32, 
		adv_snap_small_font_threshold : f32 
	)
	{
		profile(#procedure)
		// Set script and direction. We use the system's default langauge.
		// script = HB_SCRIPT_LATIN
		harfbuzz.buffer_set_script( buffer, script )
		harfbuzz.buffer_set_direction( buffer, harfbuzz.script_get_horizontal_direction( script ))
		harfbuzz.buffer_set_language( buffer, harfbuzz.language_get_default() )

		// Perform the actual shaping of this run using HarfBuzz.
		harfbuzz.buffer_set_content_type( buffer, harfbuzz.Buffer_Content_Type.UNICODE )
		harfbuzz.shape( entry.shaper_info.font, buffer, nil, 0 )

		// Loop over glyphs and append to output buffer.
		glyph_count : u32
		glyph_infos     := harfbuzz.buffer_get_glyph_infos( buffer, & glyph_count )
		glyph_positions := harfbuzz.buffer_get_glyph_positions( buffer, & glyph_count )

		line_height := (entry.ascent - entry.descent + entry.line_gap) * font_scale

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
			if abs( font_px_size ) <= adv_snap_small_font_threshold
			{
				(position^) = ceil( position^ )
			}

			glyph_pos := position^
			offset    := Vec2 { f32(hb_gposition.x_offset), f32(hb_gposition.y_offset) } * font_scale
			glyph_pos += offset

			if snap_shape_pos {
				glyph_pos = ceil(glyph_pos)
			}

			advance := Vec2 { 
				f32(hb_gposition.x_advance) * font_scale, 
				f32(hb_gposition.y_advance) * font_scale
			}
			(position^)          += advance
			(max_line_width^)     = max(max_line_width^, position.x)

			is_empty := parser_is_glyph_empty(entry.parser_info, glyph_id)
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
		shape_run( output,
			entry, 
			ctx.hb_buffer, 
			current_script, 
			& position, 
			& max_line_width, 
			& line_count, 
			font_px_Size, 
			font_scale, 
			ctx.snap_glyph_position, 
			ctx.adv_snap_small_font_threshold
		)	
		harfbuzz.buffer_add( ctx.hb_buffer, hb_codepoint, codepoint == '\n' ? 1 : 0 )
		current_script = script
	}

	// End the last run if needed
	shape_run( output,
		entry, 
		ctx.hb_buffer, 
		current_script, 
		& position, 
		& max_line_width, 
		& line_count, 
		font_px_Size, 
		font_scale, 
		ctx.snap_glyph_position, 
		ctx.adv_snap_small_font_threshold
	)	

	// Set the final size
	output.size.x = max_line_width
	output.size.y = f32(line_count) * line_height
	return
}

shaper_shape_text_uncached_advanced :: #force_inline proc( ctx : ^Shaper_Context, 
	entry        : Entry, 
	font_px_size : f32, 
	font_scale   : f32, 
	text_utf8    : string, 
	output       : ^Shaped_Text
)
{
	profile(#procedure)
	assert( ctx != nil )

	clear( & output.glyphs )
	clear( & output.positions )

	shaper_shape_harfbuzz( ctx, text_utf8, entry, font_px_size, font_scale, output )
}

shaper_shape_text_latin :: #force_inline proc( ctx : ^Shaper_Context, 
	entry        : Entry, 
	font_px_Size : f32, 
	font_scale   : f32, 
	text_utf8    : string, 
	output       : ^Shaped_Text
)
{	
	profile(#procedure)
	assert( ctx != nil )

	clear( & output.glyphs )
	clear( & output.positions )

	line_height := (entry.ascent - entry.descent + entry.line_gap) * font_scale

	line_count     : int = 1
	max_line_width : f32 = 0
	position       : Vec2

	prev_codepoint : rune
	for codepoint, index in text_utf8
	{
		if prev_codepoint > 0 {
			kern       := parser_get_codepoint_kern_advance( entry.parser_info, prev_codepoint, codepoint )
			position.x += f32(kern) * font_scale
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
		if abs( font_px_Size ) <= ctx.adv_snap_small_font_threshold {
			position.x = ceil(position.x)
		}

		glyph_index    := parser_find_glyph_index( entry.parser_info, codepoint )
		is_glyph_empty := parser_is_glyph_empty( entry.parser_info, glyph_index )
		if ! is_glyph_empty
		{
			append( & output.glyphs, glyph_index)
			append( & output.positions, Vec2 {
				ceil(position.x),
				ceil(position.y)
			})
		}

		advance, _ := parser_get_codepoint_horizontal_metrics( entry.parser_info, codepoint )
		position.x += f32(advance) * font_scale
		prev_codepoint = codepoint
	}

	output.end_cursor_pos = position
	max_line_width        = max(max_line_width, position.x)

	output.size.x = max_line_width
	output.size.y = f32(line_count) * line_height
}

shaper_shape_text_cached :: #force_inline proc( text_utf8 : string, 
	ctx                 : ^Shaper_Context,
	shape_cache         : ^Shaped_Text_Cache, 
	font                : Font_ID,
	entry               : Entry, 
	font_px_size        : f32, 
	font_scale          : f32, 
	shape_text_uncached : $Shaper_Shape_Text_Uncached_Proc
) -> (shaped_text : Shaped_Text)
{
	profile(#procedure)
	font        := font
	font_bytes  := slice_ptr( transmute(^byte) & font,  size_of(Font_ID) )
	text_bytes  := transmute( []byte) text_utf8

	lru_code : u32
	shape_lru_code( & lru_code, font_bytes )
	shape_lru_code( & lru_code, text_bytes )

	state := & shape_cache.state

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
		shape_text_uncached( ctx, entry, font_px_size, font_scale, text_utf8, storage_entry )

		shaped_text = storage_entry ^
		return
	}

	shaped_text = shape_cache.storage[ shape_cache_idx ]
	return
}
