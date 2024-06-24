// Goal is for any Position or 'Shape' intersections used by the prototype to be defined here for centeralization

package sectr

import "core:math/linalg"

// AABB: Separating Axis Theorem
intersects_range2 :: #force_inline proc "contextless" ( a, b: Range2 ) -> bool
{
	// Check if there's no overlap on the x-axis
	if a.max.x < b.min.x || b.max.x < a.min.x {
			return false; // No overlap on x-axis means no intersection
	}
	// Check if there's no overlap on the y-axis
	if a.max.y < b.min.y || b.max.y < a.min.y {
			return false; // No overlap on y-axis means no intersection
	}
	// If neither of the above conditions are true, there's at least a partial overlap
	return true;
}

// AABB: Separating Axis Theorem
overlap_range2 :: #force_inline proc "contextless" ( a, b: Range2 ) -> bool
{
	// Check if there's no overlap on the x-axis
	if a.max.x <= b.min.x || b.max.x <= a.min.x {
			return false; // No overlap on x-axis means no intersection
	}
	// Check if there's no overlap on the y-axis
	if a.max.y <= b.min.y || b.max.y <= a.min.y {
			return false; // No overlap on y-axis means no intersection
	}
	// If neither of the above conditions are true, there's at least a partial overlap
	return true;
}


// TODO(Ed): Do we need this? Also does it even work (looks unfinished)?
is_within_screenspace :: #force_inline proc "contextless" ( pos : Vec2 ) -> b32 {
	state         := get_state(); using state
	screen_extent := state.app_window.extent
	cam           := & project.workspace.cam
	within_x_bounds : b32 = pos.x >= -screen_extent.x && pos.x <= screen_extent.x
	within_y_bounds : b32 = pos.y >= -screen_extent.y && pos.y <= screen_extent.y
	return within_x_bounds && within_y_bounds
}

within_range2 :: #force_inline proc "contextless" ( a, b : Range2 ) -> bool {
	within_x := b.min.x >= a.min.x && b.max.x <= a.max.x
  within_y := b.min.y >= a.min.y && b.max.y <= a.max.y
	return within_x && within_y
}

pos_within_range2 :: #force_inline proc "contextless" ( pos : Vec2, range : Range2 ) -> b32 {
	within_x := pos.x > range.min.x && pos.x < range.max.x
	within_y := pos.y > range.min.y && pos.y < range.max.y
	return b32(within_x && within_y)
}
