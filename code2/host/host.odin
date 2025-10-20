package host

//region STATIC MEMORY
// All program defined process memory here. (There will still be artifacts from the OS CRT and third-party pacakges)
                host_memory:   ProcessMemory
@(thread_local) thread_memory: ThreadMemory

//endregion STATIC MEMORY

//region HOST RUNTIME

load_client_api :: proc(version_id: int) -> (loaded_module: Client_API) {
	profile(#procedure)
	using loaded_module
	// Make sure we have a dll to work with
	file_io_err: OS_Error; write_time, file_io_err = file_last_write_time_by_name("sectr.dll")
	if file_io_err != OS_ERROR_NONE {
		panic_contextless( "Could not resolve the last write time for sectr")
	}
	//TODO(Ed): Lets try to minimize this...
	thread_sleep( Millisecond * 25 )
	// Get the live dll loaded up
	file_copy_sync( Path_Sectr_Module, Path_Sectr_Live_Module, allocator = context.temp_allocator )
	did_load: bool; lib, did_load = os_lib_load( Path_Sectr_Live_Module )
	if ! did_load do panic( "Failed to load the sectr module.")
	startup            = transmute( type_of( host_memory.client_api.startup))            os_lib_get_proc(lib, "startup")
	shutdown           = transmute( type_of( host_memory.client_api.shutdown))           os_lib_get_proc(lib, "sectr_shutdown")
	tick_lane_startup  = transmute( type_of( host_memory.client_api.tick_lane_startup))  os_lib_get_proc(lib, "tick_lane_startup")
	job_worker_startup = transmute( type_of( host_memory.client_api.job_worker_startup)) os_lib_get_proc(lib, "job_worker_startup")
	hot_reload         = transmute( type_of( host_memory.client_api.hot_reload))         os_lib_get_proc(lib, "hot_reload")
	tick_lane          = transmute( type_of( host_memory.client_api.tick_lane))          os_lib_get_proc(lib, "tick_lane")
	clean_frame        = transmute( type_of( host_memory.client_api.clean_frame))        os_lib_get_proc(lib, "clean_frame")
	jobsys_worker_tick = transmute( type_of( host_memory.client_api.jobsys_worker_tick)) os_lib_get_proc(lib, "jobsys_worker_tick")
	if startup            == nil do panic("Failed to load sectr.startup symbol" )
	if shutdown           == nil do panic("Failed to load sectr.shutdown symbol" )
	if tick_lane_startup  == nil do panic("Failed to load sectr.tick_lane_startup symbol" )
	if job_worker_startup == nil do panic("Failed to load sectr.job_worker_startup symbol" )
	if hot_reload         == nil do panic("Failed to load sectr.hot_reload symbol" )
	if tick_lane          == nil do panic("Failed to load sectr.tick_lane symbol" )
	if clean_frame        == nil do panic("Failed to load sectr.clean_frame symbol" )
	if jobsys_worker_tick == nil do panic("Failed to laod sectr.jobsys_worker_tick")
	lib_version = version_id
	return
}

master_prepper_proc :: proc(thread: ^SysThread) {}
main :: proc()
{
	// Setup host arenas
	// TODO(Ed): Preferablly I want to eliminate usage of this. We should be able to do almost everything here with fixed allocations..
	arena_init(& host_memory.host_persist, host_memory.host_persist_buf[:])
	arena_init(& host_memory.host_scratch, host_memory.host_scratch_buf[:])
	context.allocator      = arena_allocator(& host_memory.host_persist)
	context.temp_allocator = arena_allocator(& host_memory.host_scratch)
	// Setup the "Master Prepper" thread
	{
		thread_memory.id = .Master_Prepper
		thread_id := thread_current_id()
		using thread_memory
		host_memory.threads[WorkerID.Master_Prepper] = new(SysThread)
		system_ctx = host_memory.threads[WorkerID.Master_Prepper]
		system_ctx.creation_allocator = {}
		system_ctx.procedure = master_prepper_proc
		when ODIN_OS == .Windows {
			// system_ctx.win32_thread    = w32_get_current_thread()
			// system_ctx.win32_thread_id = w32_get_current_thread_id()
			system_ctx.id = cast(int) system_ctx.win32_thread_id
		}
	}
	when SHOULD_SETUP_PROFILERS
	{
		// Setup main profiler
		host_memory.spall_context = spall_context_create(Path_Sectr_Spall_Record)
		grime_set_profiler_module_context(& host_memory.spall_context)
		thread_memory.spall_buffer = spall_buffer_create(thread_memory.spall_buffer_backing[:], cast(u32) thread_memory.system_ctx.id)
		grime_set_profiler_thread_buffer(& thread_memory.spall_buffer)
	}
	// Setup the logger
	path_logger_finalized: string
	{
		profile("Setup the logger")
		// Generating the logger's name, it will be used when the app is shutting down.
		{
			startup_time     := time_now()
			year, month, day := time_date( startup_time)
			hour, min, sec   := time_clock_from_time( startup_time)

			if ! os_is_directory( Path_Logs ) {
				os_make_directory( Path_Logs )
			}
			timestamp                        := str_pfmt_tmp("%04d-%02d-%02d_%02d-%02d-%02d", year, month, day, hour, min, sec)
			host_memory.path_logger_finalized = str_pfmt("%s/sectr_%v.log", Path_Logs, timestamp)
		}
		logger_init( & host_memory.host_logger, "Sectr Host", str_pfmt_tmp("%s/sectr.log", Path_Logs))
		context.logger = to_odin_logger( & host_memory.host_logger )
		{
			// Log System Context
			builder := strbuilder_make_len(16 * Kilo, context.temp_allocator)
			str_pfmt_builder( & builder, "Core Count: %v, ", os_core_count() )
			str_pfmt_builder( & builder, "Page Size: %v",    os_page_size() )
			log_print( to_str(builder) )
		}
		free_all(context.temp_allocator)
	}
	context.logger = to_odin_logger( & host_memory.host_logger )
	// Load the Enviornment API for the first-time
	{
		host_memory.client_api = load_client_api( 1 )
		verify( host_memory.client_api.lib_version != 0, "Failed to initially load the sectr module" )
	}
	// Client API Startup
	host_memory.client_api.startup(& host_memory, & thread_memory)
	{
		profile("thread_wide_startup")
		assert(thread_memory.id == .Master_Prepper)
		{
			profile("Tick Lanes")
			host_memory.tick_running = true
			host_memory.tick_lanes   = THREAD_TICK_LANES
			barrier_init(& host_memory.lane_sync, THREAD_TICK_LANES)
			when THREAD_TICK_LANES > 1 {
				for id in 1 ..= (THREAD_TICK_LANES - 1) {
					launch_tick_lane_thread(cast(WorkerID) id)
				}
			}
		}
		// Job System Setup
		{
			profile("Job System")
			host_memory.job_system.running    = true
			host_memory.job_system.worker_num = THREAD_JOB_WORKERS
			for & list in host_memory.job_system.job_lists {
				list = {}
			}
			// Determine number of physical cores
			barrier_init(& host_memory.job_hot_reload_sync, THREAD_JOB_WORKERS + 1)
			for id in THREAD_JOB_WORKER_ID_START ..< THREAD_JOB_WORKER_ID_END {
				log_print_fmt("Spawned job worker: %v", cast(WorkerID) id)
				worker_thread           := thread_create(host_job_worker_entrypoint, .Normal)
				worker_thread.user_index = int(id)
				host_memory.threads[worker_thread.user_index] = worker_thread
				thread_start(worker_thread)
			}
		}
		barrier_init(& host_memory.lane_job_sync, THREAD_TICK_LANES + THREAD_JOB_WORKERS)
	}
	free_all(context.temp_allocator)
	host_tick_lane()

	profile_begin("Host Shutdown")
	if thread_memory.id == .Master_Prepper {
		thread_join_multiple(.. host_memory.threads[1:THREAD_TICK_LANES + THREAD_JOB_WORKERS])
	}
	
	host_memory.client_api.shutdown();

	unload_client_api( & host_memory.client_api )

	log_print("Succesfuly closed")
	file_close( host_memory.host_logger.file )
	file_rename( str_pfmt_tmp("%s/sectr.log",  Path_Logs), host_memory.path_logger_finalized )
	profile_end()

	// End profiling
	spall_buffer_destroy(& host_memory.spall_context, & thread_memory.spall_buffer)
	spall_context_destroy( & host_memory.spall_context )
}
launch_tick_lane_thread :: proc(id : WorkerID) {
	assert_contextless(thread_memory.id == .Master_Prepper)
	// TODO(Ed): We need to make our own version of this that doesn't allocate memory.
	lane_thread           := thread_create(host_tick_lane_entrypoint, .High)
	lane_thread.user_index = int(id)
	host_memory.threads[lane_thread.user_index] = lane_thread
	thread_start(lane_thread)
}

host_tick_lane_entrypoint :: proc(lane_thread: ^SysThread) {
	thread_memory.system_ctx = lane_thread
	thread_memory.id         = cast(WorkerID) lane_thread.user_index
	when SHOULD_SETUP_PROFILERS
	{
		thread_memory.spall_buffer = spall_buffer_create(thread_memory.spall_buffer_backing[:], cast(u32) thread_memory.system_ctx.id)
		host_memory.client_api.tick_lane_startup(& thread_memory)
		grime_set_profiler_thread_buffer(& thread_memory.spall_buffer)
	}
	host_tick_lane()
}
host_tick_lane :: proc()
{
	profile(#procedure)
	delta_ns: Duration
	host_tick := time_tick_now()

	for ; sync_load(& host_memory.tick_running, .Relaxed);
	{
		profile("Host Tick")
		leader := barrier_wait(& host_memory.lane_sync)

		running: b64 = host_memory.client_api.tick_lane(duration_seconds(delta_ns), delta_ns) == false
		if thread_memory.id == .Master_Prepper { 
			sync_store(& host_memory.tick_running, running, .Release) 
		}
		host_memory.client_api.clean_frame()

		delta_ns  = time_tick_lap_time( & host_tick )
		host_tick = time_tick_now()
		// Lanes are synced before doing running check..
		sync_client_api()
	}
	host_lane_shutdown()
}
host_lane_shutdown :: proc()
{
	profile(#procedure)
	if thread_memory.id == .Master_Prepper {
		jobs_enqueued := true
		// if jobs_enqueued == false do debug_trap()
		for ; jobs_enqueued; {
			jobs_enqueued  = false
			jobs_enqueued |= host_memory.job_system.job_lists[.Normal].head != nil
			jobs_enqueued |= host_memory.job_system.job_lists[.Low].head    != nil
			jobs_enqueued |= host_memory.job_system.job_lists[.High].head   != nil
			// if jobs_enqueued == false do debug_trap()
		} 
		sync_store(& host_memory.job_system.running, false, .Release)
	}
	if thread_memory.id != .Master_Prepper {
		spall_buffer_destroy( & host_memory.spall_context, & thread_memory.spall_buffer )
	}
	leader := barrier_wait(& host_memory.lane_job_sync)
}

host_job_worker_entrypoint :: proc(worker_thread: ^SysThread)
{
	thread_memory.system_ctx = worker_thread
	thread_memory.id         = cast(WorkerID) worker_thread.user_index
	when SHOULD_SETUP_PROFILERS
	{
		thread_memory.spall_buffer = spall_buffer_create(thread_memory.spall_buffer_backing[:], cast(u32) thread_memory.system_ctx.id)
		host_memory.client_api.job_worker_startup(& thread_memory)
		grime_set_profiler_thread_buffer(& thread_memory.spall_buffer)
	}
	jobs_enqueued := false
	jobs_enqueued |= host_memory.job_system.job_lists[.Normal].head != nil
	jobs_enqueued |= host_memory.job_system.job_lists[.Low].head    != nil
	jobs_enqueued |= host_memory.job_system.job_lists[.High].head   != nil
	delta_ns: Duration
	host_tick := time_tick_now()
	for ; jobs_enqueued || sync_load(& host_memory.job_system.running, .Relaxed); 
	{
		// profile("Host Job Tick")

		host_memory.client_api.jobsys_worker_tick(duration_seconds(delta_ns), delta_ns)

		delta_ns  = time_tick_lap_time( & host_tick )
		host_tick = time_tick_now()

		jobs_enqueued  = false
		jobs_enqueued |= host_memory.job_system.job_lists[.Normal].head != nil
		jobs_enqueued |= host_memory.job_system.job_lists[.Low].head    != nil
		jobs_enqueued |= host_memory.job_system.job_lists[.High].head   != nil

		if jobs_enqueued == false && sync_load(& host_memory.client_api_hot_reloaded, .Acquire) {
			// Signals to main hread when all jobs have drained.
			leader :=barrier_wait(& host_memory.job_hot_reload_sync) 
			// Job threads wait here until client module is back
			leader  =barrier_wait(& host_memory.job_hot_reload_sync) 
			host_memory.client_api.hot_reload(& host_memory, & thread_memory)
		}
	}
	spall_buffer_destroy( & host_memory.spall_context, & thread_memory.spall_buffer )
	// Were exiting, wait for tick lanes.
	leader := barrier_wait(& host_memory.lane_job_sync)
}

sync_client_api :: proc()
{
	profile(#procedure)
	// We don't want any lanes to be in client callstack during a hot-reload
	leader := barrier_wait(& host_memory.lane_sync)
	if thread_memory.id == .Master_Prepper 
	{
		write_time, result := file_last_write_time_by_name( Path_Sectr_Module );
		if result == OS_ERROR_NONE && host_memory.client_api.write_time != write_time
		{
			profile("Master_Prepper: Reloading client module")
			sync_store(& host_memory.client_api_hot_reloaded, true, .Release)
			// We nee to wait for the job queue to drain.
			leader = barrier_wait(& host_memory.job_hot_reload_sync)
			{
				version_id := host_memory.client_api.lib_version + 1
				unload_client_api( & host_memory.client_api )
				// Wait for pdb to unlock (linker may still be writting)
				for ; file_is_locked( Path_Sectr_Debug_Symbols ) && file_is_locked( Path_Sectr_Live_Module ); {}

				thread_sleep( Millisecond * 25 )

				host_memory.client_api = load_client_api( version_id )
				verify( host_memory.client_api.lib_version != 0, "Failed to hot-reload the sectr module" )
			}
			leader = barrier_wait(& host_memory.job_hot_reload_sync)
		}
	}
	leader = barrier_wait(& host_memory.lane_sync)
	// Lanes are safe to continue.
	if sync_load(& host_memory.client_api_hot_reloaded, .Acquire) {
		host_memory.client_api.hot_reload(& host_memory, & thread_memory)
	}
}
unload_client_api :: proc( module : ^Client_API )
{
	profile(#procedure)
	os_lib_unload( module.lib )
	file_remove( Path_Sectr_Live_Module )
	module^ = {}
	log_print("Unloaded client API")
}

//endregion HOST RUNTIME
