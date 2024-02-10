package sectr

import    "core:unicode/utf8"
import rl "vendor:raylib"

debug_text :: proc( content : string, pos : Vec2, size : f32 = 16.0, color : rl.Color = rl.WHITE, font : rl.Font = {} )
{
	if len( content ) == 0 {
		return
	}
	runes := utf8.string_to_runes( content, context.temp_allocator )

	font := font
	if ( font.chars == nil ) {
		font = get_state().default_font
	}

	rl.DrawTextCodepoints( font,
		raw_data(runes), cast(i32) len(runes),
		position = transmute(rl.Vector2) pos,
		fontSize = size,
		spacing  = 0.0,
		tint     = color );
}
