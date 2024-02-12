package sectr

import "core:math/linalg"


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
	box_bounds    := box_get_bounds( box )

	within_bounds : b32 = false

	when false {
		within_x : b32 = box_bounds.top_left.x > screen_bounds.top_left.x
		within_x &= box_bounds.top_left.x < screen_bounds.bottom_right.x

		within_y : b32 = box_bounds.top_left.y > screen_bounds.top_left.y

		state         := get_state(); using state
		screen_extent := state.app_window.extent
		cam           := & project.workspace.cam
		within_x_bounds : b32 = pos.x >= -screen_extent.x && pos.x <= screen_extent.x
		within_y_bounds : b32 = pos.y >= -screen_extent.y && pos.y <= screen_extent.y
	}
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
