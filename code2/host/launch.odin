package host

Path_Logs :: "../logs"
when ODIN_OS == .Windows
{
	Path_Sectr_Module        :: "sectr.dll"
	Path_Sectr_Live_Module   :: "sectr_live.dll"
	Path_Sectr_Debug_Symbols :: "sectr.pdb"
}

// Only static memory host has.
host_memory: HostMemory

main :: proc()
{
	host_memory.host_api.sync_client_module = sync_client_api
	host_memory.client_api.startup(& host_memory)
}

@export
sync_client_api :: proc()
{
	// Fill out detection and reloading of client api.
}
