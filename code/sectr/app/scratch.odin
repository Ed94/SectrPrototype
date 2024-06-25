package sectr

// Scratch space

import sokol_gfx "thirdparty:sokol/gfx"

DebugData :: struct {
	square_size : i32,
	square_pos  : Vec2,

	debug_text_vis    : b32,
	draw_debug_text_y : f32,

	cursor_locked     : b32,
	cursor_unlock_pos : Vec2, // Raylib changes the mose position on lock, we want restore the position the user would be in on screen
	mouse_vis         : b32,
	last_mouse_pos    : Vec2,

	// UI Vis
	draw_ui_box_bounds_points : bool,
	draw_ui_padding_bounds    : bool,
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

	gfx_clear_demo_pass_action : sokol_gfx.Pass_Action,
	gfx_tri_demo_state : struct {
		pipeline    : sokol_gfx.Pipeline,
    bindings    : sokol_gfx.Bindings,
    pass_action : sokol_gfx.Pass_Action,
	}
}
