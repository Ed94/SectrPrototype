package sectr

import rl "vendor:raylib"


range2_to_rl_rect :: #force_inline proc "contextless"( range : Range2 ) -> rl.Rectangle
{
	rect := rl.Rectangle {
		range.min.x,
		range.max.y,
		abs(range.max.x - range.min.x),
		abs(range.max.y - range.min.y),
	}
	return rect
}


