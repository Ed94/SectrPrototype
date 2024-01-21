package sectr

import "core:unicode/utf8"

import rl "vendor:raylib"

font_rec_mono_semicasual_reg : rl.Font;
default_font                 : rl.Font

debug_text :: proc( content : string, x, y : f32, size : f32 = 16.0, color : rl.Color = rl.WHITE, font : rl.Font = default_font )
{
	if len( content ) == 0 {
		return
	}
	runes := utf8.string_to_runes( content )

	rl.DrawTextCodepoints( font,
		raw_data(runes), cast(i32) len(runes),
		position = rl.Vector2 { x, y },
		fontSize = size,
		spacing  = 0.0,
		tint     = color );
}
