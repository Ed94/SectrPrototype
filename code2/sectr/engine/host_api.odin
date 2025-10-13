package sectr

import "core:sync"

/*
Everything defined for the host module within the client module
so that the client module has full awareness of relevant host definitions

Client interaction with host is very minimal, 
host will only provide the base runtime for client's tick lanes and job system workers.

Host is has all statically (data/bss) defined memory for the application, it will not mess with
client_memory however.
*/

ProcessMemory :: struct {
	// Host 
	host_persist_buf: [64 * Mega]byte,
	host_scratch_buf: [32 * Mega]byte,
	host_persist:     Odin_Arena,
	host_scratch:     Odin_Arena,
	host_api:         Host_API,

	// Textual Logging
	logger: Logger,

	// Profiling
	spall_profiler: ^SpallProfiler,

	// Multi-threading
	threads: [MAX_THREADS](SysThread),

	client_api_hot_reloaded: b64,
	client_api_sync_lock:    sync.Barrier,

	// Client Module
	client_api:    ModuleAPI,
	client_memory: State,
}

Host_API :: struct {
	request_virtual_memory: #type proc(),
	request_virtual_mapped_io: #type proc(),
}

ThreadMemory :: struct {
	using _: ThreadWorkerContext,
	live_lanes: int,
}
