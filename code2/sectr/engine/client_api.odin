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
	memory = host_mem
	thread = thread_mem
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
	profile(#procedure)
	thread = thread_mem
	if thread.id == .Master_Prepper {
		grime_set_profiler_module_context(& memory.spall_context)
		sync_store(& memory, host_mem, .Release)
	}
	grime_set_profiler_thread_buffer(& thread.spall_buffer)
}

/*
Called by host_tick_lane_startup
Used for lane specific startup operations

The lane tick cannot be handled it, its call must be done by the host module.
(We need threads to not be within a client callstack in the even of a hot-reload)
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

/*

*/
@export
tick_lane :: proc(host_delta_time_ms: f64, host_delta_ns: Duration) -> (should_close: b64 = false)
{
	profile(#procedure)
	@thread_local dummy: int = 0
	dummy += 1

	// profile_begin("sokol_app: pre_client_tick")
	// should_close |= cast(b64) sokol_app.pre_client_frame()
	@static timer: f64
	if thread.id == .Master_Prepper {
		timer        += host_delta_time_ms
		sync_store(& should_close, timer > 5, .Release)
	}
	// profile_end()

	// profile_begin("Client Tick")

	// @thread_local test_job: TestJobInfo
	// for job_id := 1; job_id < 64; job_id += 1 {
		// job_dispatch(test_job, & test_job, .Medium, "Job Test")
	// }

	// profile_end()

	// profile_begin("sokol_app: post_client_tick")
	// profile_end()

	tick_lane_frametime()
	return sync_load(& should_close, .Acquire)
}

@export
jobsys_worker_tick :: proc() {
	profile("Worker Tick")

	@thread_local dummy: int = 0;
	dummy += 1
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
