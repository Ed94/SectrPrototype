package sectr

//region STATIC MEMORY
// This should be the only global on client module side.
                memory: ^ProcessMemory
@(thread_local) thread: ^ThreadMemory
//endregion STATIC MEMORy

State :: struct {
	job_system: JobSystemContext,
}
