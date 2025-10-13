package grime

/*
This is just a snippet file, do not use directly.
*/

import "base:runtime"
import "core:prof/spall"

SpallProfiler :: struct {
	ctx     : spall.Context,
	buffer  : spall.Buffer,
}

set_profiler_module_context :: #force_inline proc "contextless" ( profiler : ^SpallProfiler ) {
	static_memory.spall_profiler = profiler
}

DISABLE_PROFILING :: true

@(deferred_none = profile_end, disabled = DISABLE_PROFILING)
profile :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & static_memory.spall_profiler.ctx, & static_memory.spall_profiler.buffer, name, "", loc )
}
@(disabled = DISABLE_PROFILING)
profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & static_memory.spall_profiler.ctx, & static_memory.spall_profiler.buffer, name, "", loc )
}
@(disabled = DISABLE_PROFILING)
profile_end :: #force_inline proc "contextless" () {
	spall._buffer_end( & static_memory.spall_profiler.ctx, & static_memory.spall_profiler.buffer)
}
