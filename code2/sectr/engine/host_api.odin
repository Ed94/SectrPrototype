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
	host_persist_buf: [32 * Mega]byte,
	host_scratch_buf: [64 * Mega]byte,
	host_persist:     Odin_Arena,      // Host Persistent (Non-Wipeable), for bad third-party static object allocation
	host_scratch:     Odin_Arena,      // Host Temporary  Wipable
	host_api:         Host_API,        // Client -> Host Interface

	// Textual Logging
	host_logger:           Logger,
	path_logger_finalized: string,

	// Profiling
	spall_context: Spall_Context,
	// TODO(Ed): Try out Superluminal's API!

	// Multi-threading
	threads:             [MAX_THREADS](^SysThread), // All threads are tracked here.
	job_system:          JobSystemContext, // State tracking for job system.
	tick_running:        b64,              // When disabled will lead to shutdown of the process.
	tick_lanes:          int,              // Runtime tracker of live tick lane threads
	lane_sync:           sync.Barrier,     // Used to sync tick lanes during wide junctions.
	job_hot_reload_sync: sync.Barrier,     // Used to sync jobs with main thread during hot-reload junction.
	lane_job_sync:       sync.Barrier,     // Used to sync tick lanes and job workers during hot-reload.

	// Client Module
	client_api_hot_reloaded: b64,       // Used to signal to threads when hot-reload paths should be taken.
	client_api:              ModuleAPI, // Host -> Client Interface
	client_memory:           State,

	// Testing
	job_group_reload: JobGroup,
	job_info_reload: [JOB_TEST_NUM]TestJobInfo,
	job_reload:      [JOB_TEST_NUM]Job,
}
JOB_TEST_NUM :: 64

Host_API :: struct {
	request_virtual_memory:    #type proc(), // All dynamic allocations will utilize vmem interfaces
	request_virtual_mapped_io: #type proc(), // TODO(Ed): Figure out usage constraints of this.
}

ThreadMemory :: struct {
	using _:    ThreadWorkerContext,

	// Per-thread profiling
	spall_buffer_backing: [SPALL_BUFFER_DEFAULT_SIZE]byte,
	spall_buffer:         Spall_Buffer,

	client_memory: ThreadState,
}
