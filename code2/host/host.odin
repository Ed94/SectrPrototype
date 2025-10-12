package host

// TODO(Ed): Remove this
import "core:mem"

Path_Logs :: "../logs"
when ODIN_OS == .Windows
{
	Path_Sectr_Module        :: "sectr.dll"
	Path_Sectr_Live_Module   :: "sectr_live.dll"
	Path_Sectr_Debug_Symbols :: "sectr.pdb"
}

// Only static memory host has.
host_memory: HostMemory

@(thread_local)
thread_memory: ThreadMemory

master_prepper_proc :: proc(thread: ^SysThread) {}
main :: proc()
{
	// TODO(Ed): Change this
	host_scratch: mem.Arena; mem.arena_init(& host_scratch, host_memory.host_scratch[:])
	context.allocator      = mem.arena_allocator(& host_scratch)
	context.temp_allocator = context.allocator

	thread_memory.index = .Master_Prepper
	thread_id := thread_current_id()
	{
		using thread_memory
		system_ctx.creation_allocator = {}
		system_ctx.procedure = master_prepper_proc
		when ODIN_OS == .Windows {
			// system_ctx.win32_thread    = w32_get_current_thread()
			// system_ctx.win32_thread_id = w32_get_current_thread_id()
			system_ctx.id = cast(int) system_ctx.win32_thread_id
		}
	}

	write_time, result := file_last_write_time_by_name("sectr.dll")
	if result != OS_ERROR_NONE {
		panic_contextless( "Could not resolve the last write time for sectr")
	}

	thread_sleep( Millisecond * 100 )

	live_file := Path_Sectr_Live_Module
	file_copy_sync( Path_Sectr_Module, live_file, allocator = context.temp_allocator )
	{
		lib, load_result := os_lib_load( live_file )
		if ! load_result {
			panic( "Failed to load the sectr module." )
		}

		startup    := cast( type_of( host_memory.client_api.startup   )) os_lib_get_proc(lib, "startup")
		hot_reload := cast( type_of( host_memory.client_api.hot_reload)) os_lib_get_proc(lib, "hot_reload")
		if startup    == nil do panic("Failed to load sectr.startup symbol" )
		if hot_reload == nil do panic("Failed to load sectr.reload symbol" )

		host_memory.client_api.lib        = lib
		host_memory.client_api.startup    = startup
		host_memory.client_api.hot_reload = hot_reload
	}
	host_memory.host_api.sync_client_module = sync_client_api
	host_memory.client_api.startup(& host_memory, & thread_memory)
}

@export
sync_client_api :: proc()
{
	// Fill out detection and reloading of client api.
}
