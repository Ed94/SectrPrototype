package sectr

import "core:math/linalg"

pos_within_range2 :: proc( pos : Vec2, range : Range2 ) -> b32 {
	within_x := pos.x > range.p0.x && pos.x < range.p1.x
	within_y := pos.y < range.p0.y && pos.y > range.p1.y
	return b32(within_x && within_y)
}

is_within_screenspace :: proc( pos : Vec2 ) -> b32 {
	state         := get_state(); using state
	screen_extent := state.app_window.extent
	cam           := & project.workspace.cam
	within_x_bounds : b32 = pos.x >= -screen_extent.x && pos.x <= screen_extent.x
	within_y_bounds : b32 = pos.y >= -screen_extent.y && pos.y <= screen_extent.y
	return within_x_bounds && within_y_bounds
}
