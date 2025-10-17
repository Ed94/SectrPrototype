package sectr

import sokol_app "thirdparty:sokol/app"

sokol_app_init_callback :: proc "c" () {
	context = memory.client_memory.sokol_context
	log_print("sokol_app: Confirmed initialization")
}
// This is being filled in but we're directly controlling the lifetime of sokol_app's execution.
// So this will only get called during window pan or resize events (on Win32 at least)
sokol_app_frame_callback :: proc "c" ()
{
	profile(#procedure)
	context = memory.client_memory.sokol_context
	should_close: bool

	sokol_width  := sokol_app.widthf()
	sokol_height := sokol_app.heightf()

	window := & memory.client_memory.app_window
	// if	int(window.extent.x) != int(sokol_width) || int(window.extent.y) != int(sokol_height) {
		window.resized = true
		window.extent.x = cast(f32) i32(sokol_width  * 0.5)
		window.extent.y = cast(f32) i32(sokol_height * 0.5)
		// log("sokol_app: Event-based frame callback triggered (detected a resize")
	// }

	// sokol_app is the only good reference for a frame-time at this point.
	sokol_delta_ms := sokol_app.frame_delta()
	sokol_delta_ns := transmute(Duration) sokol_delta_ms * MS_To_NS

	profile_begin("Client Tick")
	client_tick := tick_now()
	should_close |= tick_lane_work_frame( sokol_delta_ms )
	profile_end()

	tick_lane_frametime( & client_tick, sokol_delta_ms, sokol_delta_ns, can_sleep = false )
	window.resized = false
}
