package sectr

State :: struct {
	project : Project,

	screen_width  : i32,
	screen_height : i32,

	monitor_id         : i32,
	monitor_refresh_hz : i32,

	engine_refresh_hz     : i32,
	engine_refresh_target : i32,

	draw_debug_text_y : f32
}

Project :: struct {
	// TODO(Ed) : Support multiple workspaces
	workspace : Workspace
}

Workspace :: struct {

}
