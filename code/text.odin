package sectr

import    "core:unicode/utf8"
import rl "vendor:raylib"

debug_draw_text :: proc( content : string, pos : Vec2, size : f32, color : rl.Color = rl.WHITE, font : rl.Font = {} )
{
	state := get_state(); using state

	if len( content ) == 0 {
		return
	}
	runes := utf8.string_to_runes( content, context.temp_allocator )

	font := font
	if ( font.glyphs == nil ) {
		font = default_font
	}

	pos := screen_to_render(pos)

	rl.DrawTextCodepoints( font,
		raw_data(runes), cast(i32) len(runes),
		position = transmute(rl.Vector2) pos,
		fontSize = size,
		spacing  = 0.0,
		tint     = color );
}

// Raylib's equivalent doesn't take a length for the string (making it a pain in the ass)
// So this is a 1:1 copy except it takes Odin strings
measure_text_size :: proc ( text : string, font : Font, font_size, spacing : f32 ) -> AreaSize
{
	// This is a static var within raylib. We don't have getter access to it.
	@static text_line_spacing : f32 = 15

	text_size : AreaSize

	if font.texture.id == 0 || len(text) == 0 {
		return text_size
	}

	temp_byte_counter : i32 = 0 // Used to count longer text line num chars
	byte_counter      : i32 = 0

	text_width      : f32 = 0.0
	temp_text_width : f32 = 0.0 // Used to counter longer text line width

	text_height := cast(f32) font.baseSize
	scale_factor := font_size / text_height

	letter : rune
	index  : i32 = 0

	for id : i32 = 0; id < i32(len(text)); {
		byte_counter += 1

		next : i32 = 0

		ctext := cast(cstring) ( & raw_data( text )[id] )
		letter = rl.GetCodepointNext( ctext, & next )
		index  = rl.GetGlyphIndex( font, letter )

		id += 1

		if letter != rune('\n')
		{
			if font.glyphs[index].advanceX != 0 {
				text_width += f32(font.glyphs[index].advanceX)
			}
			else {
				text_width += font.recs[index].width + f32(font.glyphs[index].offsetX)
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
