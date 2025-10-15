package grime

//region STATIC MEMORY
              grime_memory: StaticMemory
@thread_local grime_thread: ThreadMemory
//endregion STATIC MEMORY

StaticMemory :: struct {
	spall_context: ^Spall_Context,
}
ThreadMemory :: struct {
	spall_buffer: ^Spall_Buffer,
}
