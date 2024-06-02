/* Space

Provides various definitions for converting from one standard of measurement to another.
Provides constructs and transformations in reguards to space.


Ultimately the user's window ppcm (pixels-per-centimeter) determins how all virtual metric conventions are handled.
*/
package sectr

// The points to pixels and pixels to points are our only reference to accurately converting
// an object from world space to screen-space.
// This prototype engine will have all its spacial unit base for distances in virtual pixels.

Inches_To_CM  :: cast(f32) 2.54
Points_Per_CM :: cast(f32) 28.3465
CM_Per_Point  :: cast(f32) 1.0 / DPT_DPCM
CM_Per_Pixel  :: cast(f32) 1.0 / DPT_PPCM
DPT_DPCM      :: cast(f32) 72.0 * Inches_To_CM // 182.88 points/dots per cm
DPT_PPCM      :: cast(f32) 96.0 * Inches_To_CM // 243.84 pixels per cm

when ODIN_OS == OS_Type.Windows {
	op_default_dpcm :: 72.0 * Inches_To_CM
	os_default_ppcm :: 96.0 * Inches_To_CM
	// 1 inch = 2.54 cm, 96 inch * 2.54 = 243.84 DPCM
}

//region Unit Conversion Impl

// cm_to_points :: proc( cm : f32 ) -> f32 {

// }

// points_to_cm :: proc( points : f32 ) -> f32 {
// 	screen_dpc := get_state().app_window.dpc
// 	cm_per_pixel := 1.0 / screen_dpc
// 	pixels := points * DPT_DPC * cm_per_pixel
// 	return points *
// }

f32_cm_to_pixels :: #force_inline proc "contextless"(cm: f32) -> f32 {
	screen_ppcm := get_state().app_window.ppcm
	return cm * screen_ppcm
}

f32_pixels_to_cm :: #force_inline proc "contextless"(pixels: f32) -> f32 {
	screen_ppcm  := get_state().app_window.ppcm
	cm_per_pixel := 1.0 / screen_ppcm
	return pixels * cm_per_pixel
}

f32_points_to_pixels :: #force_inline proc "contextless"(points: f32) -> f32 {
	screen_ppcm  := get_state().app_window.ppcm
	cm_per_pixel := 1.0 / screen_ppcm
	return points * DPT_PPCM * cm_per_pixel
}

f32_pixels_to_points :: #force_inline proc "contextless"(pixels: f32) -> f32 {
	screen_ppcm  := get_state().app_window.ppcm
	cm_per_pixel := 1.0 / screen_ppcm
	return pixels * cm_per_pixel * Points_Per_CM
}

vec2_cm_to_pixels :: #force_inline proc "contextless"(v: Vec2) -> Vec2 {
	screen_ppcm := get_state().app_window.ppcm
	return v * screen_ppcm
}

vec2_pixels_to_cm :: #force_inline proc "contextless"(v: Vec2) -> Vec2 {
	screen_ppcm  := get_state().app_window.ppcm
	cm_per_pixel := 1.0 / screen_ppcm
	return v * cm_per_pixel
}

vec2_points_to_pixels :: #force_inline proc "contextless"(vpoints: Vec2) -> Vec2 {
	screen_ppcm  := get_state().app_window.ppcm
	cm_per_pixel := 1.0 / screen_ppcm
	return vpoints * DPT_PPCM * cm_per_pixel
}

range2_cm_to_pixels :: #force_inline proc "contextless"( range : Range2 ) -> Range2 {
	screen_ppcm := get_state().app_window.ppcm
	result := Range2 { pts = { range.min * screen_ppcm, range.max * screen_ppcm }}
	return result
}

range2_pixels_to_cm :: #force_inline proc "contextless"( range : Range2 ) -> Range2 {
	screen_ppcm := get_state().app_window.ppcm
	cm_per_pixel := 1.0 / screen_ppcm
	result := Range2 { pts = { range.min * cm_per_pixel, range.max * cm_per_pixel }}
	return result
}

// vec2_points_to_cm :: proc( vpoints : Vec2 ) -> Vec2 {

// }

//endregion

Camera :: struct {
	view     : Extents2,
	position : Vec2,
	zoom     : f32,
}

Camera_Default := Camera { zoom = 1 }

CameraZoomMode :: enum u32 {
	Digital,
	Smooth,
}

// TODO(Ed) : I'm not sure making the size and extent types distinct has made things easier or more difficult in Odin..
// The lack of operator overloads is going to make any sort of nice typesystem
// for doing lots of math or phyiscs more error prone or filled with proc overload mapppings
AreaSize :: Vec2

Bounds2 :: struct {
	top_left, bottom_right: Vec2,
}

BoundsCorners2 :: struct {
	top_left, top_right, bottom_left, bottom_right: Vec2,
}

Extents2  :: Vec2
Extents2i :: Vec2i

WS_Pos :: struct {
	tile_id : Vec2i,
	rel     : Vec2,
}

bounds2_radius :: proc(bounds: Bounds2) -> f32 {
	return max( bounds.bottom_right.x, bounds.top_left.y )
}

extent_from_size :: proc(size: AreaSize) -> Extents2 {
	return transmute(Extents2) size * 2.0
}

screen_size :: proc "contextless" () -> AreaSize {
	extent := get_state().app_window.extent
	return transmute(AreaSize) ( extent * 2.0 )
}

screen_get_bounds :: #force_inline proc "contextless" () -> Range2 {
	state          := get_state(); using state
	screen_extent  := state.app_window.extent
	bottom_left    := Vec2 { -screen_extent.x, -screen_extent.y}
	top_right      := Vec2 {  screen_extent.x,  screen_extent.y}
	return range2( bottom_left, top_right )
}

screen_get_corners :: #force_inline proc "contextless"() -> BoundsCorners2 {
	state         := get_state(); using state
	screen_extent := state.app_window.extent
	top_left     := Vec2 { -screen_extent.x,  screen_extent.y }
	top_right    := Vec2 {  screen_extent.x,  screen_extent.y }
	bottom_left  := Vec2 { -screen_extent.x, -screen_extent.y }
	bottom_right := Vec2 {  screen_extent.x, -screen_extent.y }
	return { top_left, top_right, bottom_left, bottom_right }
}

// TODO(Ed): Use a cam/workspace context instead (when multiple workspaces viewproting supported)
view_get_bounds :: #force_inline proc "contextless"() -> Range2 {
	state          := get_state(); using state
	cam            := & project.workspace.cam
	screen_extent  := state.app_window.extent
	cam_zoom_ratio := 1.0 / cam.zoom
	bottom_left  := Vec2 { cam.position.x, -cam.position.y } + Vec2 { -screen_extent.x, -screen_extent.y} * cam_zoom_ratio
	top_right    := Vec2 { cam.position.x, -cam.position.y } + Vec2 {  screen_extent.x,  screen_extent.y} * cam_zoom_ratio
	return range2( bottom_left, top_right )
}

// TODO(Ed): Use a cam/workspace context instead (when multiple workspace viewproting)
view_get_corners :: #force_inline proc "contextless"() -> BoundsCorners2 {
	state          := get_state(); using state
	cam            := & project.workspace.cam
	cam_zoom_ratio := 1.0 / cam.zoom
	screen_extent  := state.app_window.extent * cam_zoom_ratio
	top_left     := cam.position + Vec2 { -screen_extent.x,  screen_extent.y }
	top_right    := cam.position + Vec2 {  screen_extent.x,  screen_extent.y }
	bottom_left  := cam.position + Vec2 { -screen_extent.x, -screen_extent.y }
	bottom_right := cam.position + Vec2 {  screen_extent.x, -screen_extent.y }
	return { top_left, top_right, bottom_left, bottom_right }
}

render_to_screen_pos :: #force_inline proc "contextless" (pos : Vec2) -> Vec2 {
	extent := & get_state().app_window.extent
	result := Vec2 {
		pos.x - extent.x,
		pos.y * -1 + extent.y
	}
	return result
}

render_to_ws_view_pos :: #force_inline proc "contextless" (pos : Vec2) -> Vec2 {
	return {}
}

screen_to_ws_view_pos :: #force_inline proc "contextless" (pos: Vec2) -> Vec2 {
	state := get_state(); using state
	cam   := & project.workspace.cam
	result := Vec2 { cam.position.x, -cam.position.y}  + Vec2 { pos.x, pos.y } * (1 / cam.zoom)
	return result
}

// Centered screen space to conventional screen space used for rendering
screen_to_render_pos :: #force_inline proc "contextless" (pos : Vec2) -> Vec2 {
	screen_extent := transmute(Vec2) get_state().app_window.extent
	return pos * {1, -1} + { screen_extent.x, screen_extent.y }
}

// TODO(Ed): These should assume a cam_context or have the ability to provide it in params

// Extent of workspace view (currently hardcoded to the app window's extent, eventually will be based on a viewport object's extent field)
// TODO(Ed): Support a position which would not be centered on the screen if in a viewport
ws_view_extent :: #force_inline proc "contextless"() -> Extents2 {
	state          := get_state(); using state
	cam_zoom_ratio := 1.0 / project.workspace.cam.zoom
	return app_window.extent * cam_zoom_ratio
}

// Workspace view to screen space position
// TODO(Ed): Support a position which would not be centered on the screen if in a viewport
ws_view_to_screen_pos :: #force_inline proc "contextless"(position: Vec2) -> Vec2 {
	return position
}

ws_view_to_render_pos :: #force_inline proc "contextless"(position: Vec2) -> Vec2 {
	return { position.x, position.y * -1 }
}

// Workspace view to screen space position (zoom agnostic)
// TODO(Ed): Support a position which would not be centered on the screen if in a viewport
ws_view_to_screen_pos_no_zoom :: #force_inline proc "contextless"(position: Vec2) -> Vec2 {
	state          := get_state(); using state
	cam_zoom_ratio := 1.0 / state.project.workspace.cam.zoom
	return { position.x, position.y } * cam_zoom_ratio
}

// Workspace view to render space position (zoom agnostic)
// TODO(Ed): Support a position which would not be centered on the screen if in a viewport
ws_view_to_render_pos_no_zoom :: #force_inline proc "contextless"(position: Vec2) -> Vec2 {
	state          := get_state(); using state
	cam_zoom_ratio := 1.0 / state.project.workspace.cam.zoom
	return { position.x, position.y } * cam_zoom_ratio
}
