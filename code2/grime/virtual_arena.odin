package grime
/*
So this is a virtual memory backed arena allocator designed
to take advantage of one large contigous reserve of memory.
With the expectation that resizes with its interface will only occur using the last allocated block.
Note(Ed): Odin's mem allocator now has that feature 

All virtual address space memory for this application is managed by a virtual arena.
No other part of the program will directly touch the vitual memory interface direclty other than it.

Thus for the scope of this prototype the Virtual Arena are the only interfaces to dynamic address spaces for the runtime of the client app.
The host application as well ideally (although this may not be the case for a while)
*/
VArena_GrowthPolicyProc :: #type proc( commit_used, committed, reserved, requested_size : uint ) -> uint

VArena :: struct {
	using vmem:       VirtualMemoryRegion,
	tracker:          MemoryTracker,
	dbg_name:         string,
	commit_used:      uint,
	growth_policy:    VArena_GrowthPolicyProc,
	allow_any_resize: b32,
	mutex:            Mutex,
}

