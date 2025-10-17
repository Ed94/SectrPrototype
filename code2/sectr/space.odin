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
