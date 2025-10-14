package grime

//region STATIC MEMORY
              static_memory: StaticMemory
@thread_local thread_memory: ThreadMemory
//endregion STATIC MEMORY

StaticMemory :: struct {
	spall_context: ^Spall_Context,
}
ThreadMemory :: struct {
	spall_buffer: ^Spall_Buffer,
}
