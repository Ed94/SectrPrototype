package host

import "base:runtime"
	debug_trap :: runtime.debug_trap

import "core:dynlib"
	os_lib_load     :: dynlib.load_library
	os_lib_unload   :: dynlib.unload_library
	os_lib_get_proc :: dynlib.symbol_address

import "core:fmt"
	str_pfmt_builder :: fmt.sbprintf
	str_pfmt_buffer  :: fmt.bprintf
	str_pfmt         :: fmt.aprintf
	str_pfmt_tmp     :: fmt.tprintf

import "core:log"
	LoggerLevel :: log.Level

import "core:mem"
	Arena           :: mem.Arena
	arena_allocator :: mem.arena_allocator
	arena_init      :: mem.arena_init

import "core:os"
	OS_ERROR_NONE                :: os.ERROR_NONE
	OS_Error                     :: os.Error
	FileTime                     :: os.File_Time
	file_close                   :: os.close
	file_last_write_time_by_name :: os.last_write_time_by_name
	file_remove                  :: os.remove
	file_rename                  :: os.rename
	file_status                  :: os.stat
	os_is_directory              :: os.is_dir
	os_make_directory            :: os.make_directory
	os_core_count                :: os.processor_core_count
	os_page_size                 :: os.get_page_size
	process_exit                 :: os.exit

import "core:prof/spall"
	spall_context_create      :: spall.context_create
	spall_context_destroy     :: spall.context_destroy
	spall_buffer_create       :: spall.buffer_create
	spall_buffer_destroy      :: spall.buffer_destroy

import "core:strings"
	strbuilder_from_bytes :: strings.builder_from_bytes
	strbuilder_make_len   :: strings.builder_make_len
	builder_to_str        :: strings.to_string

import "core:sync"
	Barrier              :: sync.Barrier
	barrier_init         :: sync.barrier_init
	barrier_wait         :: sync.barrier_wait
	thread_current_id    :: sync.current_thread_id
	// Cache coherent loads and stores (synchronizes relevant cache blocks/lines)
	sync_load            :: sync.atomic_load_explicit
	sync_store           :: sync.atomic_store_explicit

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
	SysThread            :: thread.Thread
	thread_create        :: thread.create
	thread_start         :: thread.start
	thread_destroy       :: thread.destroy
	thread_join_multiple :: thread.join_multiple
	thread_terminate     :: thread.terminate

import grime "codebase:grime"
	DISABLE_GRIME_PROFILING  :: grime.DISABLE_PROFILING

	grime_set_profiler_module_context :: grime.set_profiler_module_context
	grime_set_profiler_thread_buffer  :: grime.set_profiler_thread_buffer

	ensure :: grime.ensure
	fatal  :: grime.fatal
	verify :: grime.verify

	file_is_locked    :: grime.file_is_locked
	logger_init       :: grime.logger_init
	to_odin_logger    :: grime.to_odin_logger

	// Need to have it with un-wrapped allocator
	// file_copy_sync    :: grime.file_copy_sync
	file_copy_sync :: proc( path_src, path_dst: string, allocator := context.allocator ) -> b32
	{
		file_size : i64
		{
			path_info, result := file_status( path_src, allocator )
			if result != OS_ERROR_NONE {
				log_print_fmt("Could not get file info: %v", result, LoggerLevel.Error )
				return false
			}
			file_size = path_info.size
		}

		src_content, result := os.read_entire_file_from_filename( path_src, allocator )
		if ! result {
			log_print_fmt( "Failed to read file to copy: %v", path_src, LoggerLevel.Error )
			debug_trap()
			return false
		}

		result = os.write_entire_file( path_dst, src_content, false )
		if ! result {
			log_print_fmt( "Failed to copy file: %v", path_dst, LoggerLevel.Error )
			debug_trap()
			return false
		}
		return true
	}

import "codebase:sectr"
	DISABLE_HOST_PROFILING   :: sectr.DISABLE_HOST_PROFILING
	DISABLE_CLIENT_PROFILING :: sectr.DISABLE_CLIENT_PROFILING

	Path_Logs                  :: sectr.Path_Logs
	Path_Sectr_Debug_Symbols   :: sectr.Path_Debug_Symbols
	Path_Sectr_Live_Module     :: sectr.Path_Live_Module
	Path_Sectr_Module          :: sectr.Path_Module
	Path_Sectr_Spall_Record    :: sectr.Path_Spall_Record
	MAX_THREADS                :: sectr.MAX_THREADS
	THREAD_TICK_LANES          :: sectr.THREAD_TICK_LANES
	THREAD_JOB_WORKERS         :: sectr.THREAD_JOB_WORKERS
	THREAD_JOB_WORKER_ID_START :: sectr.THREAD_JOB_WORKER_ID_START
	THREAD_JOB_WORKER_ID_END   :: sectr.THREAD_JOB_WORKER_ID_END

	Client_API         :: sectr.ModuleAPI
	ProcessMemory      :: sectr.ProcessMemory
	ThreadMemory       :: sectr.ThreadMemory
	WorkerID           :: sectr.WorkerID

// ensure :: #force_inline proc( condition : b32, msg : string, location := #caller_location ) {
// 	if condition do return
// 	log_print( msg, LoggerLevel.Warning, location )
// 	debug_trap()
// }
// // TODO(Ed) : Setup exit codes!
// fatal :: #force_inline proc( msg : string, exit_code : int = -1, location := #caller_location ) {
// 	log_print( msg, LoggerLevel.Fatal, location )
// 	debug_trap()
// 	process_exit( exit_code )
// }
// // TODO(Ed) : Setup exit codes!
// verify :: #force_inline proc( condition : b32, msg : string, exit_code : int = -1, location := #caller_location ) {
// 	if condition do return
// 	log_print( msg, LoggerLevel.Fatal, location )
// 	debug_trap()
// 	process_exit( exit_code )
// }

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

SHOULD_SETUP_PROFILERS :: \
	DISABLE_GRIME_PROFILING  == false ||
	DISABLE_CLIENT_PROFILING == false ||
	DISABLE_HOST_PROFILING   == false 

@(deferred_none = profile_end, disabled = DISABLE_HOST_PROFILING)
profile :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & host_memory.spall_context, & thread_memory.spall_buffer, name, "", loc )
}
@(disabled = DISABLE_HOST_PROFILING)
profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & host_memory.spall_context, & thread_memory.spall_buffer, name, "", loc )
}
@(disabled = DISABLE_HOST_PROFILING)
profile_end :: #force_inline proc "contextless" () {
	spall._buffer_end( & host_memory.spall_context, & thread_memory.spall_buffer)
}

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024

to_str :: proc {
	builder_to_str,
}
