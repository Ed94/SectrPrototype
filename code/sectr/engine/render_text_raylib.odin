package sectr

import "core:math"
import "core:strings"
import "core:unicode/utf8"
import rl "vendor:raylib"

debug_draw_text :: proc( content : string, pos : Vec2, size : f32, color : rl.Color = rl.WHITE, font : FontID = Font_Default )
{
	// profile(#procedure)
	state := get_state(); using state

	if len( content ) == 0 {
		return
	}
	runes, alloc_error := to_runes( content, frame_allocator() )
	// runes, alloc_error := to_runes( content, context.temp_allocator )
	// verify( alloc_error == AllocatorError.None, "Failed to temp allocate runes" )

	font := font
	if font.key == Font_Default.key {
	// if ( len(font) == 0 ) {
		font = default_font
	}
	pos := screen_to_render_pos(pos)

	px_size := size

	rl_font := to_rl_Font(font, px_size )
	rl.SetTextureFilter(rl_font.texture, rl.TextureFilter.POINT)
	rl.DrawTextCodepoints( rl_font,
		raw_data(runes), cast(i32) len(runes),
		position = transmute(rl.Vector2) pos,
		fontSize = px_size,
		spacing  = 0.0,
		tint     = color );
	rl.SetTextureFilter(rl_font.texture, rl.TextureFilter.POINT)
}

draw_text_screenspace :: proc( content : StrRunesPair, pos : Vec2, size : f32, color : rl.Color = rl.WHITE, font : FontID = Font_Default )
{
	// profile(#procedure)
	state := get_state(); using state

	if len( content.str ) == 0 {
		return
	}
	font := font
	if  font.key == Font_Default.key {
		font = default_font
	}
	pos := pos

	rl_font := to_rl_Font(font, size )
	runes   := content.runes

	rl.SetTextureFilter(rl_font.texture, rl.TextureFilter.POINT)
	rl.DrawTextCodepoints( rl_font,
		raw_data(runes), cast(i32) len(runes),
		position = transmute(rl.Vector2) pos,
		fontSize = size,
		spacing  = 0.0,
		tint     = color );
	rl.SetTextureFilter(rl_font.texture, rl.TextureFilter.POINT)
}

ws_view_draw_text_string :: proc( content : string, pos : Vec2, size : f32, color : rl.Color = rl.WHITE, font : FontID = Font_Default )
{
	// profile(#procedure)
	state := get_state(); using state

	if len( content ) == 0 {
		return
	}
	runes, alloc_error := to_runes( content, frame_allocator() )
	verify( alloc_error == AllocatorError.None, "Failed to temp allocate runes" )

	font := font
	if  font.key == Font_Default.key {
	// if len(font) == 0 {
		font = default_font
	}
	pos := ws_view_to_render_pos(pos)

	px_size     := size
	zoom_adjust := px_size * project.workspace.cam.zoom

	rl_font := to_rl_Font(font, zoom_adjust )
	rl.SetTextureFilter(rl_font.texture, rl.TextureFilter.POINT)
	rl.DrawTextCodepoints( rl_font,
		raw_data(runes), cast(i32) len(runes),
		position = transmute(rl.Vector2) pos,
		fontSize = px_size,
		spacing  = 0.0,
		tint     = color );
	rl.SetTextureFilter(rl_font.texture, rl.TextureFilter.POINT)
}

when true
{
	ws_view_draw_text_StrRunesPair :: proc( content : StrRunesPair, pos : Vec2, size : f32, color : rl.Color = rl.WHITE, font : FontID = Font_Default )
	{
		profile(#procedure)
		state := get_state(); using state

		if len( content.str ) == 0 {
			return
		}
		font := font
		if  font.key == Font_Default.key {
			font = default_font
		}
		pos := ws_view_to_render_pos(pos)

		px_size     := size
		zoom_adjust := px_size * project.workspace.cam.zoom
		rl_font     := to_rl_Font(font, zoom_adjust )
		runes       := content.runes

		profile_begin("raylib draw codepoints related")
		// rl.DrawTextCodepoints( rl_font,
		// 	raw_data(runes), cast(i32) len(runes),
		// 	position = transmute(rl.Vector2) pos,
		// 	fontSize = px_size,
		// 	spacing  = 0.0,
		// 	tint     = color );
		rl.DrawTextEx(rl_font,
			strings.clone_to_cstring(content.str),
			position = transmute(rl.Vector2) pos,
			fontSize = px_size,
			spacing  = 0.0,
			tint     = color
		)
		profile_end()
	}
}
else
{
	ws_view_draw_text_StrRunesPair :: proc( content : StrRunesPair, pos : Vec2, size : f32, color : rl.Color = rl.WHITE, font : FontID = Font_Default )
	{
    profile(#procedure)
    state := get_state(); using state

		// We need an alternative way to draw text to the screen (the above is way to expensive)
		// Possibly need to watch handmade hero...


	}
}

// Raylib's equivalent doesn't take a length for the string (making it a pain in the ass)
// So this is a 1:1 copy except it takes Odin strings
measure_text_size_raylib :: proc( text : string, font : FontID, font_size := Font_Use_Default_Size, spacing : f32 ) -> Vec2
{
	// profile(#procedure)
	px_size := math.round( points_to_pixels( font_size ) )
	rl_font := to_rl_Font( font, font_size )

	// This is a static var within raylib. We don't have getter access to it.
	// Note(Ed) : raylib font size is in pixels so this is also.
	@static text_line_spacing : f32 = 15

	text_size : Vec2

	if rl_font.texture.id == 0 || len(text) == 0 {
		return text_size
	}

	temp_byte_counter : i32 = 0 // Used to count longer text line num chars
	byte_counter      : i32 = 0

	text_width      : f32 = 0.0
	temp_text_width : f32 = 0.0 // Used to counter longer text line width

	text_height := cast(f32) rl_font.baseSize
	scale_factor := px_size / text_height

	letter : rune
	index  : i32 = 0

	for id : i32 = 0; id < i32(len(text));
	{
		byte_counter += 1

		next : i32 = 0

		ctext := cast(cstring) ( & raw_data( text )[id] )
		letter = rl.GetCodepointNext( ctext, & next )
		index  = rl.GetGlyphIndex( rl_font, letter )

		id += 1

		if letter != rune('\n')
		{
			if rl_font.glyphs[index].advanceX != 0 {
				text_width += f32(rl_font.glyphs[index].advanceX)
			}
			else {
				text_width += rl_font.recs[index].width + f32(rl_font.glyphs[index].offsetX)
			}
		}
		else
		{
			if temp_text_width < text_width {
				temp_text_width = text_width
			}
			byte_counter = 0
			text_width   = 0

			text_height += text_line_spacing

			if temp_byte_counter < byte_counter {
				temp_byte_counter = byte_counter
			}
		}
	}
	if temp_text_width < text_width {
		temp_text_width = text_width
	}
	text_size.x = temp_text_width * scale_factor + f32(temp_byte_counter - 1) * spacing
	text_size.y = text_height * scale_factor

	return text_size
}