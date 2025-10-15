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
	for ; memory == nil; {
		memory = host_mem
	}
	for ; thread == nil; {
		thread = thread_mem
	}
	grime_set_profiler_module_context(& memory.spall_context)
	grime_set_profiler_thread_buffer(& thread.spall_buffer)
	profile(#procedure)
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
			for ; memory == nil; {
				sync_load(& memory, .Acquire)
			}
			for ; thread == nil; {
				thread = thread_mem
			}
		}
		grime_set_profiler_thread_buffer(& thread.spall_buffer)
	}
	profile(#procedure)
	// Do hot-reload stuff...
	{
		
	}
	// Critical reference synchronization
	{
		leader := barrier_wait(& memory.lane_job_sync)
		if thread.id == .Master_Prepper {
				sync_store(& memory.client_api_hot_reloaded, false, .Release)
		}
		else {
			for ; memory.client_api_hot_reloaded == true;  {
				sync_load(& memory.client_api_hot_reloaded, .Acquire)
			}
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
		sync_store(& should_close, timer > EXIT_TIME, .Release)

		// Test dispatching 64 jobs during hot_reload loop (when the above store is uncommented)
		for job_id := 1; job_id < 64; job_id += 1 {
			memory.job_info_reload[job_id].id = job_id
			memory.job_reload[job_id] = make_job_raw(& memory.job_group_reload, & memory.job_info_reload[job_id], test_job, {}, "Job Test (Hot-Reload)")
			job_dispatch_single(& memory.job_reload[job_id], .Normal)
		}
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

	profile_end()

	// profile_begin("sokol_app: post_client_tick")
	// profile_end()

	tick_lane_frametime()
	return sync_load(& should_close, .Acquire)
}

@export
jobsys_worker_tick :: proc()
{
	profile("Worker Tick")

	ORDERED_PRIORITIES :: [len(JobPriority)]JobPriority{.High, .Normal, .Low}
	block: for priority in ORDERED_PRIORITIES 
	{
		if memory.job_system.job_lists[priority].head == nil do continue
		if sync_mutex_try_lock(& memory.job_system.job_lists[priority].mutex) 
		{
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

tick_lane_frametime :: proc()
{
	profile(#procedure)
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
