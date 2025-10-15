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

	startup:            type_of( startup ),
	tick_lane_startup:  type_of( tick_lane_startup),
	job_worker_startup: type_of( job_worker_startup),
	hot_reload:         type_of( hot_reload ),
	tick_lane:          type_of( tick_lane ),
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
	// Rad Debugger driving me crazy..
	// NOTE(Ed): This is problably not necessary, they're just loops for my sanity.
	for ; memory == nil; { memory = host_mem   }
	for ; thread == nil; { thread = thread_mem }
	grime_set_profiler_module_context(& memory.spall_context)
	grime_set_profiler_thread_buffer(& thread.spall_buffer)
	profile(#procedure)

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
			grime_set_profiler_module_context(& memory.spall_context)
		}
		else {
			// NOTE(Ed): This is problably not necessary, they're just loops for my sanity.
			for ; memory == nil; { sync_load(& memory, .Acquire) }
			for ; thread == nil; { thread = thread_mem }
		}
		grime_set_profiler_thread_buffer(& thread.spall_buffer)
	}
	profile(#procedure)
	// Do hot-reload stuff...
	{
		// Test dispatching 64 jobs during hot_reload loop (when the above store is uncommented)
		for job_id := 1; job_id < 64; job_id += 1 {
			memory.job_info_reload[job_id].id = job_id
			memory.job_reload[job_id] = make_job_raw(& memory.job_group_reload, & memory.job_info_reload[job_id], test_job, {}, "Job Test (Hot-Reload)")
			job_dispatch_single(& memory.job_reload[job_id], .Normal)
		}
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
		grime_set_profiler_thread_buffer(& thread.spall_buffer)
	}
	profile(#procedure)
}

@export
job_worker_startup :: proc(thread_mem: ^ThreadMemory)
{
	if thread_mem.id != .Master_Prepper {
		thread = thread_mem
		grime_set_profiler_thread_buffer(& thread.spall_buffer)
	}
	profile(#procedure)
}

/*
Host handles the loop. 
(We need threads to be outside of client callstack in the event of a hot-reload)
*/
@export
tick_lane :: proc(host_delta_time_ms: f64, host_delta_ns: Duration) -> (should_close: b64 = false)
{
	profile(#procedure)
	@thread_local dummy: int = 0
	dummy += 1

	EXIT_TIME :: 1

	// profile_begin("sokol_app: pre_client_tick")
	// should_close |= cast(b64) sokol_app.pre_client_frame()
	@static timer: f64
	if thread.id == .Master_Prepper {
		timer += host_delta_time_ms
		// sync_store(& should_close, timer > EXIT_TIME, .Release)

	}
	// profile_end()

	profile_begin("Client Tick")

	if thread.id == .Master_Prepper && timer > EXIT_TIME {
		// Test dispatching 64 jobs during the last iteration before exiting.
		for job_id := 1; job_id < 64; job_id += 1 {
			memory.job_info_exit[job_id].id = job_id
			memory.job_exit[job_id] = make_job_raw(& memory.job_group_exit, & memory.job_info_exit[job_id], test_job, {}, "Job Test (Exit)")
			job_dispatch_single(& memory.job_exit[job_id], .Normal)
		}
	}
	client_tick := tick_now()

	profile_end()

	// profile_begin("sokol_app: post_client_tick")
	// profile_end()

	tick_lane_frametime(& client_tick, host_delta_time_ms, host_delta_ns)
	return sync_load(& should_close, .Acquire)
}

@export
jobsys_worker_tick :: proc(host_delta_time_ms: f64, host_delta_ns: Duration)
{
	// profile("Worker Tick")

	ORDERED_PRIORITIES :: [len(JobPriority)]JobPriority{.High, .Normal, .Low}
	block: for priority in ORDERED_PRIORITIES 
	{
		if memory.job_system.job_lists[priority].head == nil do continue
		if sync_mutex_try_lock(& memory.job_system.job_lists[priority].mutex) 
		{
			profile("Executing Job")
			if job := memory.job_system.job_lists[priority].head; job != nil 
			{
				if int(thread.id) in job.ignored {
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

	// Updating worker frametime
	{
		// TODO(Ed): Setup 
		
	}
}

TestJobInfo :: struct {
	id: int,
}
test_job :: proc(data: rawptr)
{
	profile(#procedure)
	info := cast(^TestJobInfo) data
	// log_print_fmt("Test job succeeded: %v", info.id)
}

Frametime_High_Perf_Threshold_MS :: 1 / 240.0

tick_lane_frametime :: proc(client_tick: ^Tick, host_delta_time_ms: f64, host_delta_ns: Duration, can_sleep := true)
{
	profile(#procedure)
	config    := app_config()
	frametime := & memory.client_memory.frametime
	// context.allocator      = frame_slab_allocator()
	// context.temp_allocator = transient_allocator()

	if thread.id == .Master_Prepper
	{
		frametime.target_ms          = 1.0 / f64(config.engine_refresh_hz) * S_To_MS
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
	if thread.id == .Master_Prepper
	{

	}
	return
}
