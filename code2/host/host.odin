package host

import "core:thread"
import "core:sync"

Path_Logs :: "../logs"
when ODIN_OS == .Windows
{
	Path_Sectr_Module        :: "sectr.dll"
	Path_Sectr_Live_Module   :: "sectr_live.dll"
	Path_Sectr_Debug_Symbols :: "sectr.pdb"
	Path_Sectr_Spall_Record  :: "sectr.spall"
}

// Only static memory host has.
host_memory: ProcessMemory

@(thread_local)
thread_memory: ThreadMemory

load_client_api :: proc(version_id: int) -> (loaded_module: Client_API)
{
	write_time, result := file_last_write_time_by_name("sectr.dll")
	if result != OS_ERROR_NONE {
		panic_contextless( "Could not resolve the last write time for sectr")
	}

	thread_sleep( Millisecond * 100 )

	live_file := Path_Sectr_Live_Module
	file_copy_sync( Path_Sectr_Module, live_file, allocator = context.temp_allocator )

	lib, load_result := os_lib_load( live_file )
	if ! load_result {
		panic( "Failed to load the sectr module." )
	}

	startup           := cast( type_of( host_memory.client_api.startup))           os_lib_get_proc(lib, "startup")
	tick_lane_startup := cast( type_of( host_memory.client_api.tick_lane_startup)) os_lib_get_proc(lib, "tick_lane_startup")
	hot_reload        := cast( type_of( host_memory.client_api.hot_reload))        os_lib_get_proc(lib, "hot_reload")
	tick_lane         := cast( type_of( host_memory.client_api.tick_lane))         os_lib_get_proc(lib, "tick_lane")
	clean_frame       := cast( type_of( host_memory.client_api.clean_frame))       os_lib_get_proc(lib, "clean_frame")
	if startup           == nil do panic("Failed to load sectr.startup symbol" )
	if tick_lane_startup == nil do panic("Failed to load sectr.tick_lane_startup symbol" )
	if hot_reload        == nil do panic("Failed to load sectr.hot_reload symbol" )
	if tick_lane         == nil do panic("Failed to load sectr.tick_lane symbol" )
	if clean_frame       == nil do panic("Failed to load sectr.clean_frmae symbol" )

	loaded_module.lib               = lib
	loaded_module.write_time        = write_time
	loaded_module.lib_version       = version_id
	loaded_module.startup           = startup
	loaded_module.tick_lane_startup = tick_lane_startup
	loaded_module.hot_reload        = hot_reload
	loaded_module.tick_lane         = tick_lane
	loaded_module.clean_frame       = clean_frame
	return
}

master_prepper_proc :: proc(thread: ^SysThread) {}
main :: proc()
{
	// Setup host arenas
	arena_init(& host_memory.host_persist, host_memory.host_persist_buf[:])
	arena_init(& host_memory.host_scratch, host_memory.host_scratch_buf[:])
	context.allocator      = arena_allocator(& host_memory.host_persist)
	context.temp_allocator = arena_allocator(& host_memory.host_scratch)
	// Setup the profiler
	{
		buffer_backing := make([]u8, SPALL_BUFFER_DEFAULT_SIZE * 4)
		host_memory.spall_profiler.ctx    = spall_context_create(Path_Sectr_Spall_Record)
		host_memory.spall_profiler.buffer = spall_buffer_create(buffer_backing)
	}
	// Setu the "Master Prepper" thread
	thread_memory.id = .Master_Prepper
	thread_id := thread_current_id()
	{
		using thread_memory
		system_ctx = & host_memory.threads[WorkerID.Master_Prepper]
		system_ctx.creation_allocator = {}
		system_ctx.procedure = master_prepper_proc
		when ODIN_OS == .Windows {
			// system_ctx.win32_thread    = w32_get_current_thread()
			// system_ctx.win32_thread_id = w32_get_current_thread_id()
			system_ctx.id = cast(int) system_ctx.win32_thread_id
		}
		free_all(context.temp_allocator)
	}
	// Setup the logger
	{
		fmt_backing := make([]byte, 32 * Kilo)
		defer free_all(context.temp_allocator)

		// Generating the logger's name, it will be used when the app is shutting down.
		path_logger_finalized : string
		{
			startup_time     := time_now()
			year, month, day := time_date( startup_time)
			hour, min, sec   := time_clock_from_time( startup_time)

			if ! os_is_directory( Path_Logs ) {
				os_make_directory( Path_Logs )
			}
			timestamp            := str_pfmt_buffer( fmt_backing, "%04d-%02d-%02d_%02d-%02d-%02d", year, month, day, hour, min, sec)
			path_logger_finalized = str_pfmt_buffer( fmt_backing, "%s/sectr_%v.log", Path_Logs, timestamp)
		}
		logger_init( & host_memory.logger, "Sectr Host", str_pfmt_buffer( fmt_backing, "%s/sectr.log", Path_Logs ) )
		context.logger = to_odin_logger( & host_memory.logger )
		{
			// Log System Context
			builder         := strbuilder_from_bytes( fmt_backing )
			str_pfmt_builder( & builder, "Core Count: %v, ", os_core_count() )
			str_pfmt_builder( & builder, "Page Size: %v",    os_page_size() )
			log_print( to_str(builder) )
		}
	}
	context.logger = to_odin_logger( & host_memory.logger )
	// Load the Enviornment API for the first-time
	{
		host_memory.client_api = load_client_api( 1 )
		verify( host_memory.client_api.lib_version != 0, "Failed to initially load the sectr module" )
	}

	// Client API Startup
	host_memory.host_api.sync_client_module      = sync_client_api
	host_memory.host_api.launch_tick_lane_thread = launch_tick_lane_thread
	host_memory.client_api.startup(& host_memory, & thread_memory)

	// Start the tick lanes 
	thread_wide_startup()
}

thread_wide_startup :: proc()
{
	assert(thread_memory.id == .Master_Prepper)
	if THREAD_TICK_LANES > 1 {
		launch_tick_lane_thread(.Atomic_Accountant)
		sync.barrier_init(& host_memory.client_api_sync_lock, THREAD_TICK_LANES)
	}
	host_tick_lane_startup(thread_memory.system_ctx)
}

@export
launch_tick_lane_thread :: proc(id : WorkerID) {
	assert_contextless(thread_memory.id == .Master_Prepper)
	// TODO(Ed): We need to make our own version of this that doesn't allocate memory.
	lane_thread           := thread.create(host_tick_lane_startup, .High)
	lane_thread.user_index = int(id)
	thread.start(lane_thread)
}

host_tick_lane_startup :: proc(lane_thread: ^SysThread) {
	thread_memory.system_ctx = lane_thread
	thread_memory.id         = cast(WorkerID) lane_thread.user_index
	host_memory.client_api.tick_lane_startup(& thread_memory)
	
	host_tick_lane()
}

host_tick_lane :: proc()
{
	delta_ns: Duration

	host_tick := time_tick_now()

	running : b64 = true
	for ; running ;
	{
		profile("Host Tick")
		sync_client_api()

		running = host_memory.client_api.tick_lane( duration_seconds(delta_ns), delta_ns )
		// host_memory.client_api.clean_frame()

		delta_ns   = time_tick_lap_time( & host_tick )
		host_tick  = time_tick_now()
	}
}

@export
sync_client_api :: proc()
{
	leader := sync.barrier_wait(& host_memory.client_api_sync_lock)
	free_all(context.temp_allocator)
	profile(#procedure)
	if thread_memory.id == .Master_Prepper 
	{
		write_time, result := file_last_write_time_by_name( Path_Sectr_Module );
		if result == OS_ERROR_NONE && host_memory.client_api.write_time != write_time
		{
			thread_coherent_store(& host_memory.client_api_hot_reloaded, true)

			version_id := host_memory.client_api.lib_version + 1
			unload_client_api( & host_memory.client_api )

			// Wait for pdb to unlock (linker may still be writting)
			for ; file_is_locked( Path_Sectr_Debug_Symbols ) && file_is_locked( Path_Sectr_Live_Module ); {}
			thread_sleep( Millisecond * 100 )

			host_memory.client_api = load_client_api( version_id )
			verify( host_memory.client_api.lib_version != 0, "Failed to hot-reload the sectr module" )
		}
	}
	leader = sync.barrier_wait(& host_memory.client_api_sync_lock)
	if thread_coherent_load(& host_memory.client_api_hot_reloaded)
	{
		host_memory.client_api.hot_reload(& host_memory, & thread_memory)
		if thread_memory.id == .Master_Prepper {
			thread_coherent_store(& host_memory.client_api_hot_reloaded, false)
		}
	}
}

unload_client_api :: proc( module : ^Client_API )
{
	os_lib_unload( module.lib )
	file_remove( Path_Sectr_Live_Module )
	module^ = {}
	log_print("Unloaded sectr API")
}
