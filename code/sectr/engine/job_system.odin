package sectr

ThreadProc :: #type proc(data: rawptr)

IgnoredThreads :: bit_set[ 0 ..< 64 ]

JobProc :: #type proc(data: rawptr)

JobGroup :: struct {
	counter: u64,
}

JobPriority :: enum {
	Medium = 0,
	Low,
	High,
}

Job :: struct {
	next:    ^Job,
	cb:      JobProc,
	data:    rawptr,
	group:   ^JobGroup,
	ignored: IgnoredThreads,
	dbg_lbl: string,
}

JobList :: struct {
	head:  ^Job,
	mutex: AtomicMutex,
}

JobSystemContext :: struct {
	job_lists:   [JobPriority]JobList,
	worker_cb:   ThreadProc,
	worker_data: rawptr,
	counter:     int,
	workers:     [] ^ThreadWorkerContext,
	running:     b32,
}

ThreadWorkerContext :: struct {
	system_ctx: Thread,
	index:      int,
}

// Hard constraint for Windows
JOB_SYSTEM_MAX_WORKER_THREADS :: 64

/*
Threads are setup upfront during the client API's startup.


*/

jobsys_startup :: proc(ctx: ^JobSystemContext, num_workers : int, worker_exec: ThreadProc, worker_data: rawptr) {
	ctx^ = {
		worker_cb      = worker_exec,
		worker_data    = worker_data,
		counter        = 1,
	}
	// Determine number of physical cores
	// Allocate worker contextes based on number of physical cores - 1 (main thread managed by host included assumed to be index 0)
	// 
	// num_hw_threads = min(JOB_SYSTEM_MAX_WORKER_THREADS, )
	// jobsys_worker_make :
}

thread_worker_exec :: proc(_: rawptr) {
	
}

jobsys_shutdown :: proc(ctx: ^JobSystemContext) {

}
