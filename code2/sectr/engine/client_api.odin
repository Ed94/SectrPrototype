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

	thread_wide_startup()
}

thread_wide_startup :: proc()
{
	if thread_memory.id == .Master_Prepper
	{
		thread_memory.live_lanes = 

		tick_lane_startup() //
	}

	// TODO(Ed): Spawn helper thraed, then prepp both live threads
	memory.state.live_threads += 1; // Atomic_Accountant
	memory.host_api.launch_live_thread()
}

@export
tick_lane_startup :: proc(thread_mem: ^ThreadMemory)
{
	memory.state.live_threads += 1
	

	tick_lane()
}

tick_lane :: proc()
{
	dummy : int = 0
	for ;;
	{
		dummy += 1
		if thread_memory.index == .Master_Prepper
		{
			memory.host_api.sync_client_api()
		}
		
	}
}

@export
hot_reload :: proc(host_mem: ^HostMemory, thread_mem: ^ThreadMemory)
{

}
