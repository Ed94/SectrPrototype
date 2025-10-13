package sectr

/*
All direct non-codebase package symbols should do zero allocations.
Any symbol that does must be mapped from the Grime package to properly tirage its allocator to odin's ideomatic interface.


*/

import "base:intrinsics"
	debug_trap :: intrinsics.debug_trap

import "core:dynlib"
	// Only referenced in ModuleAPI
	DynLibrary :: dynlib.Library

import "core:log"
	LoggerLevel :: log.Level

import "core:mem"
	// Used strickly for the logger
	Odin_Arena           :: mem.Arena
	odin_arena_allocator :: mem.arena_allocator

import "core:os"
	FileTime     :: os.File_Time
	process_exit :: os.exit

import "core:prof/spall"

import "core:sync"
	AtomicMutex :: sync.Atomic_Mutex
	sync_store  :: sync.atomic_store_explicit

import "core:thread"
	SysThread :: thread.Thread

import "core:time"
	Duration :: time.Duration

import "codebase:grime"
	Logger            :: grime.Logger
	SpallProfiler     :: grime.SpallProfiler

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024

ensure :: #force_inline proc( condition : b32, msg : string, location := #caller_location ) {
	if condition do return
	log_print( msg, LoggerLevel.Warning, location )
	debug_trap()
}
// TODO(Ed) : Setup exit codes!
fatal :: #force_inline proc( msg : string, exit_code : int = -1, location := #caller_location ) {
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}
// TODO(Ed) : Setup exit codes!
verify :: #force_inline proc( condition : b32, msg : string, exit_code : int = -1, location := #caller_location ) {
	if condition do return
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}

log_print :: proc( msg : string, level := LoggerLevel.Info, loc := #caller_location ) {
	context.allocator      = odin_arena_allocator(& memory.host_scratch)
	context.temp_allocator = odin_arena_allocator(& memory.host_scratch)
	log.log( level, msg, location = loc )
}
log_print_fmt :: proc( fmt : string, args : ..any,  level := LoggerLevel.Info, loc := #caller_location  ) {
	context.allocator      = odin_arena_allocator(& memory.host_scratch)
	context.temp_allocator = odin_arena_allocator(& memory.host_scratch)
	log.logf( level, fmt, ..args, location = loc )
}

@(deferred_none = profile_end, disabled = DISABLE_CLIENT_PROFILING) profile       :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) { spall._buffer_begin( & memory.spall_profiler.ctx, & memory.spall_profiler.buffer, name, "", loc ) }
@(                             disabled = DISABLE_CLIENT_PROFILING) profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) { spall._buffer_begin( & memory.spall_profiler.ctx, & memory.spall_profiler.buffer, name, "", loc ) }
@(                             disabled = DISABLE_CLIENT_PROFILING) profile_end   :: #force_inline proc "contextless" ()                                         { spall._buffer_end  ( & memory.spall_profiler.ctx, & memory.spall_profiler.buffer) }
