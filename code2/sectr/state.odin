package sectr

// This should be the only global on client module side.
memory: ^HostMemory

@(thread_local)
thread_memory: ^ThreadMemory

THREAD_TICK_LANES :: 2

State :: struct {
	job_system: JobSystemContext,
}
