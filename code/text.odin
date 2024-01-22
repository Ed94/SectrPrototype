package sectr

import    "core:unicode/utf8"
import rl "vendor:raylib"

debug_text :: proc( content : string, x, y : f32, size : f32 = 16.0, color : rl.Color = rl.WHITE, font : rl.Font = {} )
{
	if len( content ) == 0 {
		return
	}
	runes := utf8.string_to_runes( content, context.temp_allocator )

	font := font
	if ( font.chars == nil ) {
		font = ( cast( ^ State) memory.persistent ).default_font
	}

	rl.DrawTextCodepoints( font,
		raw_data(runes), cast(i32) len(runes),
		position = rl.Vector2 { x, y },
		fontSize = size,
		spacing  = 0.0,
		tint     = color );
}
