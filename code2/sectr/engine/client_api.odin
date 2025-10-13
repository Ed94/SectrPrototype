package sectr

import "core:dynlib"
import "core:sync"

Path_Assets       :: "../assets/"
Path_Shaders      :: "../shaders/"
Path_Input_Replay :: "input.sectr_replay"

ModuleAPI :: struct {
	lib:          dynlib.Library,
	write_time:   FileTime,
	lib_version : int,

	startup:           type_of( startup ),
	tick_lane_startup: type_of( tick_lane_startup),
	hot_reload:        type_of( hot_reload ),
	tick_lane:         type_of( tick_lane ),
	clean_frame:       type_of( clean_frame),
}

StartupContext :: struct {}

/*
Called by host.main when it completes its setup.

The goal of startup is to first prapre persistent state, 
then prepare for multi-threaded "laned" tick: thread_wide_startup.
*/
@export
startup :: proc(host_mem: ^ProcessMemory, thread_mem: ^ThreadMemory)
{
	memory = host_mem
}

/*
Called by sync_client_api when the client module has be reloaded.
Threads will eventually return to their tick_lane upon completion.
*/
@export
hot_reload :: proc(host_mem: ^ProcessMemory, thread_mem: ^ThreadMemory)
{
	thread_ctx = thread_mem
	if thread_ctx.id == .Master_Prepper {
		cache_coherent_store(& memory, host_mem, .Release)
	}
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
	thread_ctx            = thread_mem
	thread_ctx.live_lanes = THREAD_TICK_LANES
}

@export
tick_lane :: proc(host_delta_time_ms: f64, host_delta_ns: Duration) -> (should_close: b64)
{
	@thread_local dummy: int = 0;
	dummy += 2
	return true
}

@export
clean_frame :: proc()
{
	@thread_local dummy: int = 0;
	dummy += 1
	return
}
