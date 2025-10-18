package grime

@(private)               grime_memory: StaticMemory
@(private, thread_local) grime_thread: ThreadMemory

StaticMemory :: struct {
	spall_context: ^Spall_Context,
}
ThreadMemory :: struct {
	spall_buffer: ^Spall_Buffer,
}
