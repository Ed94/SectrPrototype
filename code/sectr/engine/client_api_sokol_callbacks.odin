package sectr

import "base:runtime"
import str "core:strings"

import sokol_app "thirdparty:sokol/app"

// SokolLogEntry :: struct {
// 	tag:              cstring,
// 	log_level:        u32,
// 	log_item_id:      u32,
// 	message_or_null:  cstring,
// 	line_nr:          u32,
// 	filename_or_null : cstring,
// }

// SokolRelay :: struct {
// 	logs : StackFixed(SokolLogEntry, 512),
// }

// sokol_relay :: #force_inline proc "contextless" () -> ^SokolRelay {
// 	return & get_state().sokol_relay
// }

sokol_app_init_callback :: proc "c" () {
	context = get_state().sokol_context
	log("sokol_app: Confirmed initialization")
	// stack_push_contextless( & sokol_relay().logs, { "", 3, 0, "sokol_app: Confirmed initialization", 29, #file })
}

// This is being filled in but we're directly controlling the lifetime of sokol_app's execution.
// Thus we have no need for it todo frame callbacks
sokol_app_frame_callback :: proc "c" () {
	context = get_state().sokol_context
	log("sokol_app: SHOULD NOT HAVE CALLED THE FRAME CALLABCK")
	// stack_push_contextless( & sokol_relay().logs, { "", 3, 0, "sokol_app: SHOULD NOT HAVE CALLED THE FRAME CALLBACK", 29, #file })
}

sokol_app_cleanup_callback :: proc "c" () {
	context = get_state().sokol_context
	log("sokol_app: Confirmed cleanup")
	// stack_push_contextless( & sokol_relay().logs, { "", 3, 0, "sokol_app: Confirmed cleanup", 29, #file })
}

sokol_app_alloc :: proc "c" ( size : u64, user_data : rawptr ) -> rawptr {
	context = get_state().sokol_context
	block, error := alloc( int(size), allocator = persistent_slab_allocator() )
	ensure(error != AllocatorError.None, "sokol_app allocation failed")
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

	logf( "%-80s %v : %s::%s", cloned_msg, cloned_fname, str.clone_from_cstring(tag), level = odin_level )
	// push( & sokol_relay().logs, {tag, log_level, log_item_id, message_or_null, line_nr, filename_or_null, user_data })
}

// sokol_app_relay_update :: proc()
// {
// 	logs := & sokol_relay().logs
// 	for ; logs.idx != 0; pop( logs ) {
// 		odin_level : LogLevel
// 		switch log_level {
// 			case 0: odin_level = .Fatal
// 			case 1: odin_level = .Error
// 			case 2: odin_level = .Warning
// 			case 3: odin_level = .Info
// 		}

// 		cloned_msg : string = ""
// 		if message != nil {
// 			cloned_msg = str.clone_from_cstring(message, context.temp_allocator)
// 		}
// 		cloned_fname : string = ""
// 		if filename_or_null {
// 			cloned_fname = str.clone_from_cstring(filename_or_null, context.temp_allocator)
// 		}

// 		logf( "%-80s %v : %s::%s", cloned_msg, cloned_fname, str.clone_from_cstring(tag), level = odin_level )
// 	}
// }

sokol_app_event_callback :: proc "c" (event : ^sokol_app.Event) {

}
