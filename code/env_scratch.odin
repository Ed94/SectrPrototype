package sectr

// Scratch space

import rl "vendor:raylib"

DebugData :: struct {
	square_size : i32,
	square_pos  : rl.Vector2,

	draw_debug_text_y : f32,

	cursor_locked     : b32,
	cursor_unlock_pos : Vec2, // Raylib changes the mose position on lock, we want restore the position the user would be in on screen
	mouse_vis         : b32,
	last_mouse_pos    : Vec2,

	// UI Vis
	draw_ui_box_bounds_points : bool,
	draw_UI_padding_bounds    : bool,
	draw_ui_content_bounds    : bool,

	// Test First
	frame_2_created : b32,

	// Test Draggable
	draggable_box_pos  : Vec2,
	draggable_box_size : Vec2,
	box_original_size  : Vec2,

	// Test parsing
	path_lorem    : string,
	lorem_content : []byte,
	lorem_parse   : PWS_ParseResult,

	// Test 3d Viewport
	cam_vp      : rl.Camera3D,
	viewport_rt : rl.RenderTexture,
}