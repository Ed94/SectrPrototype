package host

// import "base:builtin"
	// Odin_OS_Type :: type_of(ODIN_OS)

// import "base:intrinsics"
	// atomic_thread_fence  :: intrinsics.atomic_thread_fence
	// mem_zero             :: intrinsics.mem_zero
	// mem_zero_volatile    :: intrinsics.mem_zero_volatile
	// mem_copy             :: intrinsics.mem_copy_non_overlapping
	// mem_copy_overlapping :: intrinsics.mem_copy

import "base:runtime"
	debug_trap :: runtime.debug_trap

import "core:dynlib"
	os_lib_load     :: dynlib.load_library
	os_lib_unload   :: dynlib.unload_library
	os_lib_get_proc :: dynlib.symbol_address

import "core:fmt"
	str_pfmt_builder :: fmt.sbprintf
	str_pfmt_buffer  :: fmt.bprintf

import "core:log"
	LoggerLevel :: log.Level

import "core:mem"
	Arena           :: mem.Arena
	arena_allocator :: mem.arena_allocator
	arena_init      :: mem.arena_init

import "core:os"
	FileTime                     :: os.File_Time
	file_last_write_time_by_name :: os.last_write_time_by_name
	file_remove                  :: os.remove
	OS_ERROR_NONE                :: os.ERROR_NONE
	os_is_directory              :: os.is_dir
	os_make_directory            :: os.make_directory
	os_core_count                :: os.processor_core_count
	os_page_size                 :: os.get_page_size
	process_exit                 :: os.exit

import "core:prof/spall"
	SPALL_BUFFER_DEFAULT_SIZE :: spall.BUFFER_DEFAULT_SIZE
	spall_context_create      :: spall.context_create
	spall_buffer_create       :: spall.buffer_create

import "core:strings"
	strbuilder_from_bytes :: strings.builder_from_bytes
	builder_to_str        :: strings.to_string

import "core:sync"
	thread_current_id    :: sync.current_thread_id
	cache_coherent_load  :: sync.atomic_load
	cache_coherent_store :: sync.atomic_store

import "core:time"
	Millisecond          :: time.Millisecond
	Second               :: time.Second
	Duration             :: time.Duration
	time_clock_from_time :: time.clock_from_time
	duration_seconds     :: time.duration_seconds
	time_date            :: time.date
	time_now             :: time.now
	thread_sleep         :: time.sleep
	time_tick_now        :: time.tick_now
	time_tick_lap_time   :: time.tick_lap_time

import "core:thread"
	SysThread :: thread.Thread

import grime "codebase:grime"
	DISABLE_PROFILING :: grime.DISABLE_PROFILING
	file_copy_sync    :: grime.file_copy_sync
	file_is_locked    :: grime.file_is_locked
	logger_init       :: grime.logger_init
	to_odin_logger    :: grime.to_odin_logger

import "codebase:sectr"
	MAX_THREADS   :: sectr.MAX_THREADS
	THREAD_TICK_LANES :: sectr.THREAD_TICK_LANES
	Client_API    :: sectr.ModuleAPI
	ProcessMemory :: sectr.ProcessMemory
	ThreadMemory  :: sectr.ThreadMemory
	WorkerID      :: sectr.WorkerID
	SpallProfiler :: sectr.SpallProfiler

ensure :: #force_inline proc( condition : b32, msg : string, location := #caller_location )
{
	if condition {
		return
	}
	log_print( msg, LoggerLevel.Warning, location )
	debug_trap()
}

// TODO(Ed) : Setup exit codes!
fatal :: #force_inline proc( msg : string, exit_code : int = -1, location := #caller_location )
{
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}

// TODO(Ed) : Setup exit codes!
verify :: #force_inline proc( condition : b32, msg : string, exit_code : int = -1, location := #caller_location )
{
	if condition {
		return
	}
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}


log_print :: proc( msg : string, level := LoggerLevel.Info, loc := #caller_location ) {
	context.allocator      = arena_allocator(& host_memory.host_scratch)
	context.temp_allocator = arena_allocator(& host_memory.host_scratch)
	log.log( level, msg, location = loc )
}

log_print_fmt :: proc( fmt : string, args : ..any,  level := LoggerLevel.Info, loc := #caller_location  ) {
	context.allocator      = arena_allocator(& host_memory.host_scratch)
	context.temp_allocator = arena_allocator(& host_memory.host_scratch)
	log.logf( level, fmt, ..args, location = loc )
}

@(deferred_none = profile_end, disabled = DISABLE_PROFILING)
profile :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & host_memory.spall_profiler.ctx, & host_memory.spall_profiler.buffer, name, "", loc )
}

@(disabled = DISABLE_PROFILING)
profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & host_memory.spall_profiler.ctx, & host_memory.spall_profiler.buffer, name, "", loc )
}

@(disabled = DISABLE_PROFILING)
profile_end :: #force_inline proc "contextless" () {
	spall._buffer_end( & host_memory.spall_profiler.ctx, & host_memory.spall_profiler.buffer)
}

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024

to_str :: proc {
	builder_to_str,
}
