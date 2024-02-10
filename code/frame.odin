package sectr

Frame :: struct {
	position      : Vec2,
	width, height : f32,
	color         : Color
}

get_bounds :: proc( frame : ^ Frame ) -> Bounds2 {
	half_width  := frame.width  / 2
	half_height := frame.height / 2
	bottom_left := Vec2 { -half_width, -half_height }
	top_right   := Vec2 {  half_width,  half_height }
	return { bottom_left, top_right }
}

get_rect :: proc ( frame : ^ Frame ) -> Rectangle {
	half_width  := frame.width  / 2
	half_height := frame.height / 2
	rect : Rectangle = {
		x = frame.position.x - half_width,
		y = frame.position.y - half_height,
		width  = frame.width,
		height = frame.height,
	}
	return rect
}
