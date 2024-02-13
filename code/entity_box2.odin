package sectr

import "core:encoding/json"

import rl "vendor:raylib"

// TODO(Ed) : I made this before doing Ryan's UI series. It was my initial attempt at a "frame"
// conceptually that I need as an Entity primitive for all my 2D primitives that I would lay out
// in either world (workspace) space or in screenspace (fixed ui space)

Box2 :: struct {
	position : Vec2,
	extent   : Extents2,
	color    : Color,
	layer    : i32,
}

box_size :: proc( box : ^ Box2 ) -> AreaSize {
	return transmute(AreaSize) box.extent * 2.0
}

box_get_bounds :: proc( box : ^ Box2 ) -> Bounds2 {
	top_left     := box.position + Vec2 { -box.extent.x,  box.extent.y }
	bottom_right := box.position + Vec2 {  box.extent.x, -box.extent.y }
	return { top_left, bottom_right }
}

box_set_size :: proc( box : ^ Box2, size : AreaSize ) {
	box.extent = transmute(Extents2) size * 0.5
}

// TODO(Ed) : Fix this up?
get_rl_rect :: proc ( box : ^ Box2 ) -> rl.Rectangle {
	rect : rl.Rectangle = {
		x = box.position.x - box.extent.x,
		y = box.position.y - box.extent.y,
		width  = box.extent.x * 2.0,
		height = box.extent.y * 2.0,
	}
	return rect
}
