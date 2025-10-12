package sectr

// import    "base:runtime"
// import  c "core:c/libc"
import    "core:dynlib"
import "core:sync"

Path_Assets       :: "../assets/"
Path_Shaders      :: "../shaders/"
Path_Input_Replay :: "input.sectr_replay"

ModuleAPI :: struct {
	lib:        dynlib.Library,
	// write-time: FileTime,

	startup:           type_of( startup ),
	hot_reload:        type_of( hot_reload ),
	tick_lane_startup: type_of( tick_lane_startup),
}

StartupContext :: struct {}

@export
startup :: proc(host_mem: ^HostMemory, thread_mem: ^ThreadMemory)
{
	dummy : int = 0
	dummy += 1

	memory = host_mem

	thread_wide_startup(thread_mem)
}

thread_wide_startup :: proc(thread_mem: ^ThreadMemory)
{
	if thread_mem.id == .Master_Prepper {
		sync.barrier_init(& memory.client_api_sync_lock, THREAD_TICK_LANES)
	}
	memory.host_api.launch_tick_lane_thread(.Atomic_Accountant)
	tick_lane_startup(thread_mem)
}

@export
tick_lane_startup :: proc(thread_mem: ^ThreadMemory)
{
	thread_memory            = thread_mem
	thread_memory.live_lanes = THREAD_TICK_LANES
	tick_lane()
}

tick_lane :: proc()
{
	dummy : int = 0
	for ;;
	{
		dummy += 1
		if thread_memory.id == .Master_Prepper
		{
			memory.host_api.sync_client_module()
		}
		leader := sync.barrier_wait(& memory.client_api_sync_lock)
	}
}

@export
hot_reload :: proc(host_mem: ^HostMemory, thread_mem: ^ThreadMemory)
{

}
