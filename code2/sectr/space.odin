package sectr

/* Space
Provides various definitions for converting from one standard of measurement to another.
Provides constructs and transformations in reguards to space.

Ultimately the user's window ppcm (pixels-per-centimeter) determins how all virtual metric conventions are handled.
*/

// The points to pixels and pixels to points are our only reference to accurately converting
// an object from world space to screen-space.
// This prototype engine will have all its spacial unit base for distances in virtual pixels.

Inches_To_CM  :: cast(f32) 2.54
Points_Per_CM :: cast(f32) 28.3465
CM_Per_Point  :: cast(f32) 1.0 / DPT_DPCM
CM_Per_Pixel  :: cast(f32) 1.0 / DPT_PPCM
DPT_DPCM      :: cast(f32) 72.0 * Inches_To_CM // 182.88 points/dots per cm
DPT_PPCM      :: cast(f32) 96.0 * Inches_To_CM // 243.84 pixels per cm

when ODIN_OS == .Windows {
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
f32_cm_to_pixels      :: #force_inline proc "contextless"(cm,             screen_ppcm: f32) -> f32   { return cm     * screen_ppcm }
f32_pixels_to_cm      :: #force_inline proc "contextless"(pixels,         screen_ppcm: f32) -> f32   { return pixels *            (1.0 / screen_ppcm) }
f32_points_to_pixels  :: #force_inline proc "contextless"(points,         screen_ppcm: f32) -> f32   { return points * DPT_PPCM * (1.0 / screen_ppcm) }
f32_pixels_to_points  :: #force_inline proc "contextless"(pixels,         screen_ppcm: f32) -> f32   { return pixels * (1.0 / screen_ppcm) * Points_Per_CM }
v2f4_cm_to_pixels     :: #force_inline proc "contextless"(v: V2_F4,       screen_ppcm: f32) -> V2_F4 { return v * screen_ppcm }
v2f4_pixels_to_cm     :: #force_inline proc "contextless"(v: V2_F4,       screen_ppcm: f32) -> V2_F4 { return v * (1.0 / screen_ppcm) }
v2f4_points_to_pixels :: #force_inline proc "contextless"(vpoints: V2_F4, screen_ppcm: f32) -> V2_F4 { return vpoints * DPT_PPCM * (1.0 / screen_ppcm) }
r2f4_cm_to_pixels     :: #force_inline proc "contextless"(range: R2_F4,   screen_ppcm: f32) -> R2_F4 { return R2_F4 { range.p0 * screen_ppcm, range.p1 * screen_ppcm } }
range2_pixels_to_cm   :: #force_inline proc "contextless"(range: R2_F4,   screen_ppcm: f32) -> R2_F4 {  cm_per_pixel := 1.0 / screen_ppcm; return R2_F4 { range.p0 * cm_per_pixel, range.p1 * cm_per_pixel } }
// vec2_points_to_cm :: proc( vpoints : Vec2 ) -> Vec2 {
// }

//endregion Unit Conversion Impl

AreaSize :: V2_F4

Bounds2 :: struct {
	top_left, bottom_right: V2_F4,
}
BoundsCorners2 :: struct {
	top_left, top_right, bottom_left, bottom_right: V2_F4,
}

E2_F4 :: V2_F4
E2_S4 :: V2_F4

WS_Pos :: struct {
	tile_id : V2_S4,
	rel     : V2_F4,
}

Camera :: struct {
	view     : E2_F4,
	position : V2_F4,
	zoom     : f32,
}

Camera_Default := Camera { zoom = 1 }

CameraZoomMode :: enum u32 {
	Digital,
	Smooth,
}

Extents2_F4 :: V2_F4
Extents2_S4 :: V2_S4


bounds2_radius    :: #force_inline proc "contextless" (bounds: Bounds2)            -> f32            { return max( bounds.bottom_right.x, bounds.top_left.y ) }
extent_from_size  :: #force_inline proc "contextless" (size: AreaSize)             -> Extents2_F4    { return transmute(Extents2_F4) (size          * 2.0) }
screen_size       :: #force_inline proc "contextless" (screen_extent: Extents2_F4) -> AreaSize       { return transmute(AreaSize)    (screen_extent * 2.0) }
screen_get_bounds :: #force_inline proc "contextless" (screen_extent: Extents2_F4) -> R2_F4          { return R2_F4 { { -screen_extent.x, -screen_extent.y} /*bottom_left*/, {  screen_extent.x,  screen_extent.y}  /*top_right*/ } }
screen_get_corners :: #force_inline proc "contextless"(screen_extent: Extents2_F4) -> BoundsCorners2 { return { 
	top_left     = { -screen_extent.x,  screen_extent.y },
	top_right    = {  screen_extent.x,  screen_extent.y },
	bottom_left  = { -screen_extent.x, -screen_extent.y },
	bottom_right = {  screen_extent.x, -screen_extent.y },
}}
view_get_bounds :: #force_inline proc "contextless"(cam: Camera, screen_extent: Extents2_F4) -> R2_F4 {
	cam_zoom_ratio := 1.0 / cam.zoom
	bottom_left    := V2_F4 { -screen_extent.x, -screen_extent.y}
	top_right      := V2_F4 {  screen_extent.x,  screen_extent.y}
	bottom_left = screen_to_ws_view_pos(bottom_left, cam.position, cam.zoom)
	top_right   = screen_to_ws_view_pos(top_right, cam.position, cam.zoom)
	return R2_F4{bottom_left, top_right}
}
view_get_corners :: #force_inline proc "contextless"(cam: Camera, screen_extent: Extents2_F4) -> BoundsCorners2 {
	cam_zoom_ratio := 1.0 / cam.zoom
	zoomed_extent  := screen_extent * cam_zoom_ratio
	top_left     := cam.position + V2_F4 { -zoomed_extent.x,  zoomed_extent.y }
	top_right    := cam.position + V2_F4 {  zoomed_extent.x,  zoomed_extent.y }
	bottom_left  := cam.position + V2_F4 { -zoomed_extent.x, -zoomed_extent.y }
	bottom_right := cam.position + V2_F4 {  zoomed_extent.x, -zoomed_extent.y }
	return { top_left, top_right, bottom_left, bottom_right }
}
render_to_screen_pos  :: #force_inline proc "contextless" (pos: V2_F4, screen_extent: Extents2_F4)      -> V2_F4 { return V2_F4 { pos.x - screen_extent.x,  (pos.y * -1) + screen_extent.y } }
render_to_ws_view_pos :: #force_inline proc "contextless" (pos: V2_F4)                                  -> V2_F4 { return {} } //TODO(Ed): Implement?
screen_to_ws_view_pos :: #force_inline proc "contextless" (pos: V2_F4, cam_pos: V2_F4, cam_zoom: f32, ) -> V2_F4 { return pos * (/*Camera Zoom Ratio*/1.0 / cam_zoom) - cam_pos } // TODO(Ed): Doesn't take into account view extent.
screen_to_render_pos  :: #force_inline proc "contextless" (pos: V2_F4, screen_extent: Extents2_F4)      -> V2_F4 { return pos + screen_extent } // Centered screen space to conventional screen space used for rendering

// TODO(Ed): These should assume a cam_context or have the ability to provide it in params
ws_view_extent        :: #force_inline proc "contextless" (cam_view: Extents2_F4, cam_zoom: f32) -> Extents2_F4 { return cam_view * (/*Camera Zoom Ratio*/1.0 / cam_zoom) }
ws_view_to_screen_pos :: #force_inline proc "contextless" (ws_pos : V2_F4, cam: Camera) -> V2_F4 {
	// Apply camera transformation
	view_pos := (ws_pos - cam.position) * cam.zoom
	// TODO(Ed): properly take into account cam.view
	screen_pos := view_pos
	return screen_pos
}
ws_view_to_render_pos :: #force_inline proc "contextless"(position: V2_F4, cam: Camera, screen_extent: Extents2_F4) -> V2_F4 {
	extent_offset: V2_F4 = { screen_extent.x, screen_extent.y } * { 1, 1 }
	position   := V2_F4 { position.x, position.y }
	cam_offset := V2_F4 { cam.position.x, cam.position.y }
	return extent_offset + (position + cam_offset) * cam.zoom
}

// Workspace view to screen space position (zoom agnostic)
// TODO(Ed): Support a position which would not be centered on the screen if in a viewport
ws_view_to_screen_pos_no_zoom :: #force_inline proc "contextless"(position: V2_F4, cam: Camera) -> V2_F4 {
	cam_zoom_ratio := 1.0 / cam.zoom
	return { position.x, position.y } * cam_zoom_ratio
}

// Workspace view to render space position (zoom agnostic)
// TODO(Ed): Support a position which would not be centered on the screen if in a viewport
ws_view_to_render_pos_no_zoom :: #force_inline proc "contextless"(position: V2_F4, cam: Camera) -> V2_F4 {
	cam_zoom_ratio := 1.0 / cam.zoom
	return { position.x, position.y } * cam_zoom_ratio
}
