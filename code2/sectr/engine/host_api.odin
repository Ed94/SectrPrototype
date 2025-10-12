package sectr

import "core:sync"

HostMemory :: struct {
	host_scratch: [256 * Kilo]byte,

	client_api_sync_lock: sync.Benaphore,

	client_api:     ModuleAPI,
	client_memory: ^State,
	host_api:       Host_API,
}

Host_API :: struct {
	launch_live_thread: #type proc(),

	request_virtual_memory: #type proc(),
	request_virtual_mapped_io: #type proc(),
	
	sync_client_module : #type proc(),
}

ThreadMemory :: struct {
	using _: ThreadWorkerContext,
	live_lanes: int,
}
