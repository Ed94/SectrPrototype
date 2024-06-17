package sectr

import "base:runtime"
import "core:time"
import str "core:strings"

import sokol_app "thirdparty:sokol/app"

#region("Sokol App")

sokol_app_init_callback :: proc "c" () {
	context = get_state().sokol_context
	log("sokol_app: Confirmed initialization")
}

// This is being filled in but we're directly controlling the lifetime of sokol_app's execution.
// So this will only get called during window pan or resize events (on Win32 at least)
sokol_app_frame_callback :: proc "c" () {
	context = get_state().sokol_context
	state  := get_state()

	should_close : b32

	sokol_width  := sokol_app.widthf()
	sokol_height := sokol_app.heightf()

	window := & state.app_window
	// if	int(window.extent.x) != int(sokol_width) || int(window.extent.y) != int(sokol_height) {
		window.resized = true
		window.extent.x = cast(f32) i32(sokol_width  * 0.5)
		window.extent.y = cast(f32) i32(sokol_height * 0.5)
		// log("sokol_app: Event-based frame callback triggered (detected a resize")
	// }

	font_provider_reload()

	// sokol_app is the only good reference for a frame-time at this point.
	sokol_delta_ms := sokol_app.frame_delta()
	sokol_delta_ns := transmute(Duration) sokol_delta_ms * MS_To_NS

	client_tick := time.tick_now()
	should_close |= tick_work_frame( sokol_delta_ms )
	tick_frametime( & client_tick, sokol_delta_ms, sokol_delta_ns )

	window.resized = false
}

sokol_app_cleanup_callback :: proc "c" () {
	context = get_state().sokol_context
	log("sokol_app: Confirmed cleanup")
}

sokol_app_alloc :: proc "c" ( size : u64, user_data : rawptr ) -> rawptr {
	context = get_state().sokol_context
	block, error := alloc( int(size), allocator = persistent_slab_allocator() )
	ensure(error == AllocatorError.None, "sokol_app allocation failed")
	return block
}

sokol_app_free :: proc "c" ( data : rawptr, user_data : rawptr ) {
	context = get_state().sokol_context
	free(data, allocator = persistent_slab_allocator() )
}

sokol_app_log_callback :: proc "c" (
	tag:              cstring,
	log_level:        u32,
	log_item_id:      u32,
	message_or_null:  cstring,
	line_nr:          u32,
	filename_or_null: cstring,
	user_data:        rawptr) {
	context = get_state().sokol_context

	odin_level : LogLevel
	switch log_level {
		case 0: odin_level = .Fatal
		case 1: odin_level = .Error
		case 2: odin_level = .Warning
		case 3: odin_level = .Info
	}

	cloned_msg : string = ""
	if message_or_null != nil {
		cloned_msg = str.clone_from_cstring(message_or_null, context.temp_allocator)
	}
	cloned_fname : string = ""
	if filename_or_null != nil {
		cloned_fname = str.clone_from_cstring(filename_or_null, context.temp_allocator)
	}

	cloned_tag := str.clone_from_cstring(tag, context.temp_allocator)
	logf( "%-80s %s::%v", cloned_msg, cloned_tag, line_nr, level = odin_level )
}

// TODO(Ed): This needs to queue to a job stask for a event callback handling thread to deal with.
sokol_app_event_callback :: proc "c" (sokol_event : ^sokol_app.Event)
{
	state := get_state(); using state
	context = sokol_context

	event : InputEvent
	using event

	_sokol_frame_id = sokol_event.frame_count
	frame_id        = frame

	mouse.pos   = { sokol_event.mouse_x,  sokol_event.mouse_y }
	mouse.delta = { sokol_event.mouse_dx, sokol_event.mouse_dy }

	switch sokol_event.type
	{
		case .INVALID:
			logf("sokol_app - event: INVALID?")
			logf("%v", sokol_event)

		case .KEY_DOWN:
			type      = .Key_Pressed
			key       = to_key_from_sokol( sokol_event.key_code )
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .KEY_UP:
			type      = .Key_Released
			key       = to_key_from_sokol( sokol_event.key_code )
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .CHAR:
			type      = .Unicode
			codepoint = transmute(rune) sokol_event.char_code
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .MOUSE_DOWN:
			type      = .Mouse_Pressed
			mouse.btn = to_mouse_btn_from_sokol( sokol_event.mouse_button )
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .MOUSE_UP:
			type      = .Mouse_Released
			mouse.btn = to_mouse_btn_from_sokol( sokol_event.mouse_button )
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .MOUSE_SCROLL:
			type         = .Mouse_Scroll
			mouse.scroll = { sokol_event.scroll_x, sokol_event.scroll_y }
			modifiers    = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .MOUSE_MOVE:
			type      = .Mouse_Move
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .MOUSE_ENTER:
			type      = .Mouse_Enter
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		case .MOUSE_LEAVE:
			type      = .Mouse_Leave
			modifiers = to_modifiers_code_from_sokol( sokol_event.modifiers )

		// TODO(Ed): Add support
		case .TOUCHES_BEGAN:
		case .TOUCHES_MOVED:
		case .TOUCHES_ENDED:
		case .TOUCHES_CANCELLED:

		case .RESIZED:

		case .ICONIFIED:

		case .RESTORED:

		case .FOCUSED:

		case .UNFOCUSED:

		case .SUSPENDED:

		case .RESUMED:

		case .QUIT_REQUESTED:

		case .CLIPBOARD_PASTED:

		case .FILES_DROPPED:

		case .DISPLAY_CHANGED:
			logf("sokol_app - event: Display changed")
			logf("refresh rate: %v", sokol_app.refresh_rate())
			monitor_refresh_hz := sokol_app.refresh_rate()
	}
}

#endregion("Sokol App")

#region("Sokol GFX")

sokol_gfx_alloc :: proc "c" ( size : u64, user_data : rawptr ) -> rawptr {
	context = get_state().sokol_context
	block, error := alloc( int(size), allocator = persistent_slab_allocator() )
	ensure(error == AllocatorError.None, "sokol_gfx allocation failed")
	return block
}

sokol_gfx_free :: proc "c" ( data : rawptr, user_data : rawptr ) {
	context = get_state().sokol_context
	free(data, allocator = persistent_slab_allocator() )
}

sokol_gfx_log_callback :: proc "c" (
	tag:              cstring,
	log_level:        u32,
	log_item_id:      u32,
	message_or_null:  cstring,
	line_nr:          u32,
	filename_or_null: cstring,
	user_data:        rawptr) {
	context = get_state().sokol_context

	odin_level : LogLevel
	switch log_level {
		case 0: odin_level = .Fatal
		case 1: odin_level = .Error
		case 2: odin_level = .Warning
		case 3: odin_level = .Info
	}

	cloned_msg : string = ""
	if message_or_null != nil {
		cloned_msg = str.clone_from_cstring(message_or_null, context.temp_allocator)
	}
	cloned_fname : string = ""
	if filename_or_null != nil {
		cloned_fname = str.clone_from_cstring(filename_or_null, context.temp_allocator)
	}

	cloned_tag := str.clone_from_cstring(tag, context.temp_allocator)
	logf( "%-80s %s::%v", cloned_msg, cloned_tag, line_nr, level = odin_level )
}

#endregion("Sokol GFX")
