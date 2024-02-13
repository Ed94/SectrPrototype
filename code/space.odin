package sectr

import rl "vendor:raylib"

// The points to pixels and pixels to points are our only reference to accurately converting
// an object from world space to screen-space.
// This prototype engine will have all its spacial unit base for distances in centimetres.

Inches_To_CM :: cast(f32)2.54
Points_Per_CM :: cast(f32)28.3465
CM_Per_Point :: cast(f32)1.0 / 28.3465 // Precalculated reciprocal for multiplication
DPT_DPC :: cast(f32)72.0 * Inches_To_CM

when ODIN_OS == OS_Type.Windows {
	os_default_dpc :: 96 * Inches_To_CM
	// 1 inch = 2.54 cm, 96 inch * 2.54 = 243.84 DPC
}

cm_to_pixels :: proc {
	f32_cm_to_pixels,
	vec2_cm_to_pixels,
}

pixels_to_cm :: proc {
	f32_pixels_to_cm,
	vec2_pixels_to_cm,
}

points_to_pixels :: proc {
	f32_points_to_pixels,
	vec2_points_to_pixels,
}


//region Unit Conversion Impl

// cm_to_points :: proc ( cm : f32 ) -> f32 {

// }

// points_to_cm :: proc( points : f32 ) -> f32 {
// 	screen_dpc := get_state().app_window.dpc
// 	cm_per_pixel := 1.0 / screen_dpc
// 	pixels := points * DPT_DPC * cm_per_pixel
// 	return points *
// }

f32_cm_to_pixels :: proc(cm: f32) -> f32 {
	screen_dpc := get_state().app_window.dpc
	return cm * screen_dpc
}

f32_pixels_to_cm :: proc(pixels: f32) -> f32 {
	screen_dpc := get_state().app_window.dpc
	cm_per_pixel := 1.0 / screen_dpc
	return pixels * cm_per_pixel
}

f32_points_to_pixels :: proc(points: f32) -> f32 {
	screen_dpc := get_state().app_window.dpc
	cm_per_pixel := 1.0 / screen_dpc
	return points * DPT_DPC * cm_per_pixel
}

f32_pixels_to_points :: proc(pixels: f32) -> f32 {
	screen_dpc := get_state().app_window.dpc
	cm_per_pixel := 1.0 / screen_dpc
	return pixels * cm_per_pixel * Points_Per_CM
}

vec2_cm_to_pixels :: proc(v: Vec2) -> Vec2 {
	screen_dpc := get_state().app_window.dpc
	return v * screen_dpc
}

vec2_pixels_to_cm :: proc(v: Vec2) -> Vec2 {
	screen_dpc := get_state().app_window.dpc
	cm_per_pixel := 1.0 / screen_dpc
	return v * cm_per_pixel
}

vec2_points_to_pixels :: proc(vpoints: Vec2) -> Vec2 {
	screen_dpc := get_state().app_window.dpc
	cm_per_pixel := 1.0 / screen_dpc
	return vpoints * DPT_DPC * cm_per_pixel
}


// vec2_points_to_cm :: proc ( vpoints : Vec2 ) -> Vec2 {

// }

//endregion

Camera :: rl.Camera2D

// TODO(Ed) : I'm not sure making the size and extent types distinct has made things easier or more difficult in Odin..
// The lack of operator overloads is going to make any sort of nice typesystem
// for doing lots of math or phyiscs more error prone or filled with proc wrappers
AreaSize :: distinct Vec2

Bounds2 :: struct {
	top_left, bottom_right: Vec2,
}

BoundsCorners2 :: struct {
	top_left, top_right, bottom_left, bottom_right: Vec2,
}

Extents2 :: distinct Vec2
Extents2i :: distinct Vec2i

WS_Pos :: struct {
	tile_id : Vec2i,
	rel     : Vec2,
}

bounds2_radius :: proc(bounds: Bounds2) -> f32 {
	return max(bounds.bottom_right.x, bounds.top_left.y)
}

extent_from_size :: proc(size: AreaSize) -> Extents2 {
	return transmute(Extents2)size * 2.0
}

screen_size :: proc "contextless" () -> AreaSize {
	extent := get_state().app_window.extent
	return transmute(AreaSize)(extent * 2.0)
}

screen_get_corners :: proc() -> BoundsCorners2 {
	state := get_state();using state
	screen_extent := state.app_window.extent
	top_left := Vec2{-screen_extent.x, screen_extent.y}
	top_right := Vec2{screen_extent.x, screen_extent.y}
	bottom_left := Vec2{-screen_extent.x, -screen_extent.y}
	bottom_right := Vec2{screen_extent.x, -screen_extent.y}
	return {top_left, top_right, bottom_left, bottom_right}
}

view_get_bounds :: proc() -> Bounds2 {
	state := get_state();using state
	cam := &project.workspace.cam
	screen_extent := state.app_window.extent
	top_left := cam.target + Vec2{-screen_extent.x, screen_extent.y}
	bottom_right := cam.target + Vec2{screen_extent.x, -screen_extent.y}
	return {top_left, bottom_right}
}

view_get_corners :: proc() -> BoundsCorners2 {
	state := get_state();using state
	cam := &project.workspace.cam
	cam_zoom_ratio := 1.0 / cam.zoom
	screen_extent := state.app_window.extent * cam_zoom_ratio
	top_left := cam.target + Vec2{-screen_extent.x, screen_extent.y}
	top_right := cam.target + Vec2{screen_extent.x, screen_extent.y}
	bottom_left := cam.target + Vec2{-screen_extent.x, -screen_extent.y}
	bottom_right := cam.target + Vec2{screen_extent.x, -screen_extent.y}
	return {top_left, top_right, bottom_left, bottom_right}
}

screen_to_world :: proc(pos: Vec2) -> Vec2 {
	state := get_state();using state
	cam := &project.workspace.cam
	return vec2_pixels_to_cm(cam.target + pos * (1 / cam.zoom))
}

screen_to_render :: proc(pos: Vec2) -> Vec2 {
	screen_extent := transmute(Vec2)get_state().project.workspace.cam.offset
	return pos + {screen_extent.x, -screen_extent.y}
}

world_screen_extent :: proc() -> Extents2 {
	state := get_state();using state
	cam_zoom_ratio := 1.0 / project.workspace.cam.zoom
	return app_window.extent * cam_zoom_ratio
}

world_to_screen_pos :: proc(position: Vec2) -> Vec2 {
	return {position.x, position.y * -1}
}

world_to_screen_no_zoom :: proc(position: Vec2) -> Vec2 {
	state := get_state();using state
	cam_zoom_ratio := 1.0 / state.project.workspace.cam.zoom
	return {position.x, position.y * -1} * cam_zoom_ratio
}
