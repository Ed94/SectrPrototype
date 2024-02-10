package sectr

import rl "vendor:raylib"

// The points to pixels and pixels to points are our only reference to accurately converting
// an object from world space to screen-space.
// This prototype engine will have all its spacial unit base for distances in centimetres.

Inches_To_Centimetre  :: cast(f32) 2.54
Points_Per_Centimetre := cast(f32) 28.3465
Centimetres_Per_Point :: cast(f32) 1.0 / 28.3465 // Precalculated reciprocal for multiplication
DPT_DPC               :: cast(f32) 72.0 * Inches_To_Centimetre

when ODIN_OS == OS_Type.Windows {
	os_default_dpc :: 96 * Inches_To_Centimetre
	// 1 inch = 2.54 cm, 96 inch * 2.54 = 243.84 DPC
}

f32_cm_to_pixels :: proc ( cm : f32 ) -> f32 {
	state := get_state(); using state
	return cm * screen_dpc
}

vec2_cm_to_pixels :: proc ( v : Vec2 ) -> Vec2 {
	state := get_state(); using state
	return v * screen_dpc
}

points_to_pixels :: proc ( points : f32 ) -> f32 {
	state := get_state(); using state
	cm_per_pixel := 1.0 / screen_dpc
	return points * DPT_DPC * cm_per_pixel
}

pixels_to_points :: proc ( pixels : f32 ) -> f32 {
	state := get_state(); using state
	cm_per_pixel := 1.0 / screen_dpc
	return pixels * cm_per_pixel * Points_Per_Centimetre
}

Camera :: rl.Camera2D

get_half_screen :: proc() -> AreaSize {
	state := get_state(); using state
	return {
		f32(screen_width)  / 2,
		f32(screen_height) / 2,
	}
}

Bounds2 :: struct {
	bottom_left, top_right : Vec2
}

AreaSize :: struct {
	width, height : f32
}
