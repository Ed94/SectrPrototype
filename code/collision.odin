package sectr

import "core:math/linalg"

pos_within_range2 :: proc( pos : Vec2, range : Range2 ) -> b32 {
	within_x := pos.x > range.min.x && pos.x < range.max.x
	within_y := pos.y > range.min.y && pos.y < range.max.y
	return b32(within_x && within_y)
}

// TODO(Ed): Do we need this? Also does it even work (looks unfinished)?
is_within_screenspace :: proc( pos : Vec2 ) -> b32 {
	state         := get_state(); using state
	screen_extent := state.app_window.extent
	cam           := & project.workspace.cam
	within_x_bounds : b32 = pos.x >= -screen_extent.x && pos.x <= screen_extent.x
	within_y_bounds : b32 = pos.y >= -screen_extent.y && pos.y <= screen_extent.y
	return within_x_bounds && within_y_bounds
}

within_range2 :: #force_inline proc ( a, b : Range2 ) -> bool {
	a_half_size := size_range2( a ) * 0.5
	b_half_size := size_range2( b ) * 0.5
	a_center := a.p0 + { a_half_size.x, -a_half_size.y }
	b_center := b.p0 + { b_half_size.x, -b_half_size.y }

	within_x := abs(a_center.x - b_center.x) <= (a_half_size.x + b_half_size.y)
  within_y := abs(a_center.y - b_center.y) <= (a_half_size.y + b_half_size.y)
	return within_x && within_y
}
