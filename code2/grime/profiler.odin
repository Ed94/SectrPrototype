package grime

import "core:prof/spall"

/*
This is just a snippet file, do not use directly.
*/

set_profiler_module_context :: #force_inline proc "contextless" (profiler : ^Spall_Context) {
	sync_store(& static_memory.spall_context, profiler, .Release)
}

set_profiler_thread_buffer :: #force_inline proc "contextless" (buffer: ^Spall_Buffer) {
	sync_store(& thread_memory.spall_buffer, buffer, .Release)
}

DISABLE_PROFILING :: true

@(deferred_none = profile_end, disabled = DISABLE_PROFILING)
profile :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( static_memory.spall_context, thread_memory.spall_buffer, name, "", loc )
}
@(disabled = DISABLE_PROFILING)
profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( static_memory.spall_context, thread_memory.spall_buffer, name, "", loc )
}
@(disabled = DISABLE_PROFILING)
profile_end :: #force_inline proc "contextless" () {
	spall._buffer_end( static_memory.spall_context, thread_memory.spall_buffer)
}
