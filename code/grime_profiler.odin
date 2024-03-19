package sectr

import "base:runtime"
import "core:prof/spall"

SpallProfiler :: struct {
	ctx     : spall.Context,
	buffer  : spall.Buffer,
}

@(deferred_none=profile_end)
profile :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & Memory_App.profiler.ctx, & Memory_App.profiler.buffer, name, "", loc )
}

profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & Memory_App.profiler.ctx, & Memory_App.profiler.buffer, name, "", loc )
}

profile_end :: #force_inline proc "contextless" () {
	spall._buffer_end( & Memory_App.profiler.ctx, & Memory_App.profiler.buffer)
}
