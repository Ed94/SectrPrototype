package sectr

// Sokol should only be used here and in the client_api_sokol_callbacks.odin

import sokol_app  "thirdparty:sokol/app"
import sokol_gfx  "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"
import sokol_gp   "thirdparty:sokol/gp"

/*
This definies the client interface for the host process to call into 
*/

ModuleAPI :: struct {
	lib:          DynLibrary,
	write_time:   FileTime,
	lib_version : int,

	startup:            type_of( startup),
	shutdown:           type_of( sectr_shutdown),
	tick_lane_startup:  type_of( tick_lane_startup),
	job_worker_startup: type_of( job_worker_startup),
	hot_reload:         type_of( hot_reload),
	tick_lane:          type_of( tick_lane),
	clean_frame:        type_of( clean_frame),
	jobsys_worker_tick: type_of( jobsys_worker_tick)
}

/*
Called by host.main when it completes its setup.

The goal of startup is to first prapre persistent state, 
then prepare for multi-threaded "laned" tick: thread_wide_startup.
*/
@export
startup :: proc(host_mem: ^ProcessMemory, thread_mem: ^ThreadMemory)
{
	// (Ignore RAD Debugger's values being null)
	memory = host_mem
	thread = thread_mem
	// grime_set_profiler_module_context(& memory.spall_context)
	// grime_set_profiler_thread_buffer(& thread.spall_buffer)
	profile(#procedure)

	startup_tick := tick_now()

	logger_init(& memory.client_memory.logger, "Sectr", memory.host_logger.file_path, memory.host_logger.file)
	context.logger = to_odin_logger(& memory.client_memory.logger)

	using memory.client_memory

		// Configuration Load
	// TODO(Ed): Make this actually load from an ini
	{
		using config
		resolution_width  = 1000
		resolution_height =  600
		refresh_rate      =    0

		cam_min_zoom                 = 0.001
		cam_max_zoom                 = 5.0
		cam_zoom_mode                = .Smooth
		cam_zoom_smooth_snappiness   = 4.0
		cam_zoom_sensitivity_smooth  = 0.5
		cam_zoom_sensitivity_digital = 0.25
		cam_zoom_scroll_delta_scale  = 0.25

		engine_refresh_hz = 240

		timing_fps_moving_avg_alpha = 0.9

		ui_resize_border_width = 5

		// color_theme = App_Thm_Dusk

		text_snap_glyph_shape_position = false
		text_snap_glyph_render_height  = false
		text_size_screen_scalar        = 1.4
		text_size_canvas_scalar        = 1.4
		text_alpha_sharpen             = 0.1
	}

	Desired_OS_Scheduler_MS :: 1
	sleep_is_granular = set__scheduler_granularity( Desired_OS_Scheduler_MS )

	// TODO(Ed): String Cache (Not backed by slab!)

	// TODO(Ed): Setup input system

	// TODO(Ed): Setup sokol_app
	// TODO(Ed): Setup sokol_gfx
	// TODO(Ed): Setup sokol_gp

	// TODO(Ed): Use job system to load fonts!!!

	// TODO(Ed): Setup screen ui state
	// TODO(Ed): Setup proper workspace scaffold

	startup_ms := duration_ms( tick_lap_time( & startup_tick))
	log_print_fmt("Startup time: %v ms", startup_ms)
}

// For some reason odin's symbols conflict with native foreign symbols...
@export
sectr_shutdown :: proc()
{
	context.logger = to_odin_logger(& memory.client_memory.logger)

	// TODO(Ed): Shut down font system

	// TODO(Ed): Shutdown sokol gp, gfx, and app.

	log_print("Client module shutdown complete")
}

/*
Called by host.sync_client_api when the client module has be reloaded.
Threads will eventually return to their tick_lane upon completion.
*/
@export
hot_reload :: proc(host_mem: ^ProcessMemory, thread_mem: ^ThreadMemory)
{
	// Critical reference synchronization
	{
		thread = thread_mem
		if thread.id == .Master_Prepper {
			sync_store(& memory, host_mem, .Release)
			// grime_set_profiler_module_context(& memory.spall_context)
		}
		else {
			// NOTE(Ed): This is problably not necessary, they're just loops for my sanity.
			for ; memory == nil; { sync_load(& memory, .Acquire) }
			for ; thread == nil; { thread = thread_mem }
		}
		// grime_set_profiler_thread_buffer(& thread.spall_buffer)
	}
	profile(#procedure)
	// Do hot-reload stuff...
	{
		context.logger = to_odin_logger(& memory.client_memory.logger)

		// TODO(Ed): Setup context alloators


		// TODO(Ed): Patch Sokol contextes

		// We hopefully don't have to patch third-party allocators anymore per-hot-reload.
		{

		}

		// TODO(Ed): Reload the font system

		log_print("Module reloaded")
	}
	// Critical reference synchronization
	{
		leader := barrier_wait(& memory.lane_job_sync)
		if thread.id == .Master_Prepper {
				sync_store(& memory.client_api_hot_reloaded, false, .Release)
		}
		else {
			// NOTE(Ed): This is problably not necessary, they're just loops for my sanity.
			for ; memory.client_api_hot_reloaded == true;  { sync_load(& memory.client_api_hot_reloaded, .Acquire) }
		}
		leader = barrier_wait(& memory.lane_job_sync)
	}
}

/*
Called by host_tick_lane_startup
Used for lane specific startup operations
*/
@export
tick_lane_startup :: proc(thread_mem: ^ThreadMemory)
{
	if thread_mem.id != .Master_Prepper {
		thread = thread_mem
		// grime_set_profiler_thread_buffer(& thread.spall_buffer)
	}
	profile(#procedure)
}

@export
job_worker_startup :: proc(thread_mem: ^ThreadMemory)
{
	if thread_mem.id != .Master_Prepper {
		thread = thread_mem
		// grime_set_profiler_thread_buffer(& thread.spall_buffer)
	}
	profile(#procedure)
}

/*
Host handles the loop. 
(We need threads to be outside of client callstack in the event of a hot-reload)
*/
@export
tick_lane :: proc(host_delta_time_ms: f64, host_delta_ns: Duration) -> (should_close: bool = false)
{
	profile(#procedure)

	profile_begin("sokol_app: pre_client_tick")
	// should_close |= cast(b64) sokol_app.pre_client_frame() // TODO(Ed): SOKOL!
	profile_end()

	profile_begin("Client Tick")
	{
		should_close = tick_lane_work_frame(host_delta_time_ms)
	}
	client_tick := tick_now()
	profile_end()

	profile_begin("sokol_app: post_client_tick")
	// sokol_app.post_client_frame() // TODO(Ed): SOKOL!
	profile_end()

	tick_lane_frametime(& client_tick, host_delta_time_ms, host_delta_ns)
	return sync_load(& should_close, .Acquire)
}

// Note(Ed): Necessary for sokol_app_frame_callback
tick_lane_work_frame :: proc(host_delta_time_ms: f64) -> (should_close: bool)
{
	profile("Work frame")
	context.logger = to_odin_logger( & memory.client_memory.logger )

	// TODO(Ed): Setup frame alloator

	if thread.id == .Master_Prepper
	{
		// config := & memory.client_memory.config
		// debug  := & memory.client_memory.debug

		// debug.draw_ui_box_bounds_points = false
		// debug.draw_ui_padding_bounds    = false
		// debug.draw_ui_content_bounds    = false

		// config.engine_refresh_hz = 165

		// config.color_theme = App_Thm_Light
		// config.color_theme = App_Thm_Dusk
		// config.color_theme = App_Thm_Dark

		// sokol_width  := sokol_app.widthf()
		// sokol_height := sokol_app.heightf()

		// window := & get_state().app_window
		// if	int(window.extent.x) != int(sokol_width) || int(window.extent.y) != int(sokol_height) {
			// window.resized = true
			// window.extent.x = sokol_width  * 0.5
			// window.extent.y = sokol_height * 0.5
			// log("sokol_app: Event-based frame callback triggered (detected a resize")
		// }
	}
	
	// Test dispatching 64 jobs during hot_reload loop (when the above store is uncommented)
	if true
	{
		if thread.id == .Master_Prepper {
			profile("dispatching")
			for job_id := 1; job_id < JOB_TEST_NUM; job_id += 1 {
				memory.job_info_reload[job_id].id = job_id
				memory.job_reload[job_id] = make_job_raw(& memory.job_group_reload, & memory.job_info_reload[job_id], test_job, {}, "Job Test (Hot-Reload)")
				job_dispatch_single(& memory.job_reload[job_id], .Normal)
			}
		}
		should_close = true
	}
	// should_close |= update( host_delta_time_ms )
	// render()
	return
}

@export
jobsys_worker_tick :: proc(host_delta_time_ms: f64, host_delta_ns: Duration)
{
	// profile("Worker Tick")
	context.logger = to_odin_logger(& memory.client_memory.logger)

	ORDERED_PRIORITIES :: [len(JobPriority)]JobPriority{.High, .Normal, .Low}
	block: for priority in ORDERED_PRIORITIES 
	{
		if memory.job_system.job_lists[priority].head == nil do continue
		if sync_mutex_try_lock(& memory.job_system.job_lists[priority].mutex) 
		{
			profile("Executing Job")
			if job := memory.job_system.job_lists[priority].head; job != nil 
			{
				if thread.id in job.ignored {
					sync_mutex_unlock(& memory.job_system.job_lists[priority].mutex)
					continue
				}
				memory.job_system.job_lists[priority].head = job.next
				sync_mutex_unlock(& memory.job_system.job_lists[priority].mutex)

				assert(job.group != nil)
				assert(job.cb    != nil)
				job.cb(job.data)

				sync_sub(& job.group.counter, 1, .Seq_Cst)
				break block
			}
			sync_mutex_unlock(& memory.job_system.job_lists[priority].mutex)
		}
	}
	// Updating worker timing
	{
		// TODO(Ed): Setup timing
	}
}

TestJobInfo :: struct {
	id: int,
}
test_job :: proc(data: rawptr)
{
	profile(#procedure)
	info := cast(^TestJobInfo) data
	log_print_fmt("Test job succeeded: %v", info.id)
}

Frametime_High_Perf_Threshold_MS :: 1 / 240.0

// TODO(Ed): Lift this to be usable by both tick lanes and job worker threads.
tick_lane_frametime :: proc(client_tick: ^Tick, host_delta_time_ms: f64, host_delta_ns: Duration, can_sleep := true)
{
	profile(#procedure)
	config := app_config()

	if thread.id == .Master_Prepper
	{
		frametime := & memory.client_memory.frametime

		frametime.target_ms          = 1.0 / f64(config.engine_refresh_hz)
		sub_ms_granularity_required := frametime.target_ms <= Frametime_High_Perf_Threshold_MS

		frametime.delta_ns      = tick_lap_time( client_tick )
		frametime.delta_ms      = duration_ms( frametime.delta_ns )
		frametime.delta_seconds = duration_seconds( host_delta_ns )
		frametime.elapsed_ms    = frametime.delta_ms + host_delta_time_ms

		if frametime.elapsed_ms < frametime.target_ms
		{
			sleep_ms       := frametime.target_ms - frametime.elapsed_ms
			pre_sleep_tick := tick_now()

			if can_sleep && sleep_ms > 0 {
				// thread_sleep( cast(Duration) sleep_ms * MS_To_NS )
				// thread__highres_wait( sleep_ms )
			}

			sleep_delta_ns := tick_lap_time( & pre_sleep_tick)
			sleep_delta_ms := duration_ms( sleep_delta_ns )

			if sleep_delta_ms < sleep_ms {
				// log( str_fmt_tmp("frametime sleep was off by: %v ms", sleep_delta_ms - sleep_ms ))
			}

			frametime.elapsed_ms += sleep_delta_ms
			for ; frametime.elapsed_ms < frametime.target_ms; {
				sleep_delta_ns = tick_lap_time( & pre_sleep_tick)
				sleep_delta_ms = duration_ms( sleep_delta_ns )

				frametime.elapsed_ms += sleep_delta_ms
			}
		}

		config.timing_fps_moving_avg_alpha = 0.99
		frametime.avg_ms  = mov_avg_exp( f64(config.timing_fps_moving_avg_alpha), frametime.elapsed_ms, frametime.avg_ms )
		frametime.fps_avg = 1 / (frametime.avg_ms * MS_To_S)

		if frametime.elapsed_ms > 60.0 {
			log_print_fmt("Big tick! %v ms", frametime.elapsed_ms, LoggerLevel.Warning)
		}

		frametime.current_frame += 1
	}
	else 
	{
		// Non-main thread tick lane timing (since they are in lock-step this should be minimal delta)
	}
}

@export
clean_frame :: proc()
{
	profile(#procedure)
	context.logger = to_odin_logger(& memory.client_memory.logger)

	if thread.id == .Master_Prepper
	{
		// mem_reset( frame_allocator() )
	}
	return
}
