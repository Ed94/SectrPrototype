package sectr

import "core:math/linalg"

pos_within_range2 :: proc( pos : Vec2, range : Range2 ) -> b32 {
	within_x := pos.x > range.p0.x && pos.x < range.p1.x
	within_y := pos.y < range.p0.y && pos.y > range.p1.y
	return b32(within_x && within_y)
}

box_is_within :: proc( box : ^ Box2, pos : Vec2 ) -> b32 {
	bounds := box_get_bounds( box )
	within_x_bounds : b32 = pos.x >= bounds.top_left.x     && pos.x <= bounds.bottom_right.x
	within_y_bounds : b32 = pos.y >= bounds.bottom_right.y && pos.y <= bounds.top_left.y
	return within_x_bounds && within_y_bounds
}

// Not sure if I should in the future not do the radius check,
// As it maybe be better off as a general proc used in an iteration...
box_is_within_view :: proc( box : ^ Box2 ) -> b32
{
	state := get_state(); using state
	screen_extent := app_window.extent

	screen_bounds_radius := max(screen_extent.x, screen_extent.y)
	box_bounds_radius    := max(box.extent.x,    box.extent.y)

	cam                 := project.workspace.cam
	cam_box_distance    := linalg.distance(cam.target, box.position)
	acceptable_distance := box_bounds_radius + screen_bounds_radius

	if cam_box_distance > acceptable_distance {
		return false
	}

	screen_bounds := view_get_bounds()
	bounds        := box_get_bounds( box )

	within_bounds : b32 = false

	// within_x_bounds : b32 = pos.x >= bounds.top_left.x     && pos.x <= bounds.bottom_right.x
	// within_y_bounds : b32 = pos.y >= bounds.bottom_right.y && pos.y <= bounds.top_left.y

	return within_bounds
}

is_within_screenspace :: proc( pos : Vec2 ) -> b32 {
	state         := get_state(); using state
	screen_extent := state.app_window.extent
	cam           := & project.workspace.cam
	within_x_bounds : b32 = pos.x >= -screen_extent.x && pos.x <= screen_extent.x
	within_y_bounds : b32 = pos.y >= -screen_extent.y && pos.y <= screen_extent.y
	return within_x_bounds && within_y_bounds
}
