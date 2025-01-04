package grime

import "base:runtime"
import "core:prof/spall"

SpallProfiler :: struct {
	ctx     : spall.Context,
	buffer  : spall.Buffer,
}

@(private)
Module_Context : ^SpallProfiler

set_profiler_module_context :: #force_inline proc "contextless" ( ctx : ^SpallProfiler ) {
	Module_Context = ctx
}

DISABLE_PROFILING :: false

@(deferred_none = profile_end, disabled = DISABLE_PROFILING)
profile :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & Module_Context.ctx, & Module_Context.buffer, name, "", loc )
}

@(disabled = DISABLE_PROFILING)
profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & Module_Context.ctx, & Module_Context.buffer, name, "", loc )
}

@(disabled = DISABLE_PROFILING)
profile_end :: #force_inline proc "contextless" () {
	spall._buffer_end( & Module_Context.ctx, & Module_Context.buffer)
}

