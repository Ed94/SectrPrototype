package sectr

JobIgnoredThreads :: bit_set[ WorkerID ]

JobProc :: #type proc(data: rawptr)

JobGroup :: struct {
	counter: u64,
}

JobPriority :: enum (u32) {
	Normal = 0,
	Low,
	High,
}

Job :: struct {
	next:      ^Job,
	cb:        JobProc,
	data:      rawptr,
	// scratch:   ^CArena,
	group:     ^JobGroup,
	ignored:   JobIgnoredThreads,
	dbg_label: string,
}

JobList :: struct {
	head:  ^Job,
	mutex: AtomicMutex,
}

JobSystemContext :: struct {
	job_lists:   [JobPriority]JobList,
	// worker_cb:   ThreadProc,
	// worker_data: rawptr,
	worker_num: int,
	workers:    [THREAD_JOB_WORKERS]^ThreadWorkerContext,
	running:    b32,
}

ThreadWorkerContext :: struct {
	system_ctx: ^SysThread,
	id:         WorkerID,
}

WorkerID :: enum int {
	Master_Prepper = 0,

	Atomic_Accountant      = 1,
	Branch_Mispredictor    = 2,
	Callstack_Canopy       = 3,
	Deadlock_Daemon        = 4,
	Fencepost_Fiddler      = 5,
	Goto_Goon              = 6,
	Hot_Path_Hitchhiker    = 7,
	Lock_Free_Liar         = 8,
	Panic_As_A_Service     = 9,
	Race_Condition_Gambler = 10,
	Spinlock_Spelunker     = 11,
	Thread_Local_Tourist   = 12,
	Unattended_Child       = 13,
	Volatile_Vandal        = 14,
	While_True_Wanderer    = 15,

	API_Apologist,
	Artifical_Sweetener,
	Assertion_Avenger,
	Async_Antagonist,
	Black_Box_Provider,
	Bit_Rot_Repacker,
	Big_O_Admirer,
	Blitting_Bandit,
	Blockchain_Believer,
	Blue_Caller,
	Blue_Screen_Shopper,
	Breakpoint_Bandit,
	Buffer_Baron,
	Cafecito_Barista,
	Callback_Operator,
	Cache_Concierge,
	Carpe_Datum,
	Chief_Synergy_Officer,
	Cipher_Clerk,
	Conscripted_Camper,
	Dean_Of_Misplaced_Delegation,
	Dereference_Doctorate,
	Checkbox_Validator,
	Credible_Threat,
	Deadline_Denialist,
	DMA_Desperado,
	Dump_Curator,
	Edge_Case_Evangelist,
	Exception_Excavator,
	Feature_Creeper,
	Fitness_Unpacker,
	Flop_Flipper,
	Floating_Point_Propoganda,
	Global_Guardian,
	Ghost_Protocols,
	Halting_Solver,
	Handshake_Hypeman,
	Headcount_Hoarder,
	Heisenbug_Hunter,
	Heuristic_Hypnotist,
	Hotfix_Hooligan,
	Idle_Malware,
	Implementation_Detailer,
	Interrupt_Ignorer,
	Interrupt_Insurgent,
	Kickoff_Holiday,
	Kilobyte_Kingpin,
	Latency_Lover,
	Legacy_Liaison,
	Linter_Lamenter,
	Low_Hanging_Fruit_Picker,
	Malloc_Maverick,
	Malpractice_Mitigator,
	Merge_Conflict_Mediator,
	Memory_Mangler,
	Mañana_Manager,
	Minimum_Wage_Multiplexer,
	Monad_Masquerader,
	NaN_Propagator,
	NDA_Negotiator,
	Null_Pointer_Enthusiast,
	Off_By_One_Offender,
	On_Call_Intern,
	Onboarding_Overlord,
	Overflow_Investor,
	Out_Of_Bounds_Outlaw,
	Page_Fault_Pioneer,
	Patient_Zero_Pollinator,
	Payload_Plunderer,
	Perpetual_Peon,
	Phishing_Pharmacist,
	Pipeline_Plumber,
	Pointer_Pilgrim,
	Production_Pusher,
	Red_Tape_Renderer,
	Resting_Receptionist,
	Quantum_Quibbler,
	Register_Riveter,
	Register_Spill_Rancher,
	Roadmap_Revisionist,
	Runtime_Ruffian,
	Sabbatical_Scheduler,
	Scope_Creep_Shepherd,
	Segfault_Stretcher,
	Siesta_Scheduler,
	Singleton_Sinner,
	Sleeper_Cell_Spammer,
	Spaghetti_Chef,
	Speculative_Skeptic,
	Stack_Smuggler,
	Techdebt_Treasurer,
	Triage_Technician,
	Undefined_Behavior_Brokerage,
	Unreachable_Utopian,
	Unicode_Usurper,
	Unsafe_Advocate,
	Unwind_Understudy,
	Voltage_Vampire,
	Vibe_Checker,
	Virtual_Vagrant,
	Void_Voyager,
	Waiting_Room_Warden,
	Weltschmerz_Worker,
	Write_Barrier_Warden,
	XORcist,
	Yellowpage_Dialer,	
	Zeroring_Comissioner,
	Zero_Cost_Commando,
	Zero_Day_Dreamer,
	Zombie_Zookeeper,
	Zombo_Vistor,
}

@(private) div_ceil :: #force_inline proc(a, b: int) -> int { return (a + b - 1) / b }

make_job_raw :: proc(group: ^JobGroup, data: rawptr, cb: JobProc, ignored_threads: JobIgnoredThreads = {}, dbg_label: string = "") -> Job {
    assert(group != nil)
    assert(cb != nil)
    return {cb = cb, data = data, group = group, ignored = {}, dbg_label = dbg_label}
}

job_dispatch_single :: proc(job: ^Job, priority: JobPriority = .Normal) {
	assert(job.group != nil)
	sync_add(& job.group.counter, 1, .Seq_Cst)	

	sync_mutex_lock(& memory.job_system.job_lists[priority].mutex)
	job.next = memory.job_system.job_lists[priority].head
	memory.job_system.job_lists[priority].head = job
	sync_mutex_unlock(& memory.job_system.job_lists[priority].mutex)
}

// Note: it's on you to clean up the memory after the jobs if you use a custom allocator.
// dispatch :: proc(priority: Priority = .Medium, jobs: ..Job, allocator := context.temp_allocator) -> []Job {
//     _jobs := make([]Job, len(jobs), allocator)
//     copy(_jobs, jobs)
//     dispatch_jobs(priority, _jobs)
//     return _jobs
// }

// Push jobs to the queue for the given priority.
// dispatch_jobs :: proc(priority: Priority, jobs: []Job) {
//     for &job, i in jobs {
//         assert(job.group != nil)
//         intrinsics.atomic_add(&job.group.atomic_counter, 1)
//         if i < len(jobs) - 1 {
//             job._next = &jobs[i + 1]
//         }
//     }

//     sync.atomic_mutex_lock(&_state.job_lists[priority].mutex)
//     jobs[len(jobs) - 1]._next = _state.job_lists[priority].head
//     _state.job_lists[priority].head = &jobs[0]
//     sync.atomic_mutex_unlock(&_state.job_lists[priority].mutex)
// }

// Block the current thread until all jobs in the group are finished.
// Other queued jobs are executed while waiting.
// wait :: proc(group: ^Group) {
//     for !group_is_finished(group) {
//         try_execute_queued_job()
//     }
//     group^ = {}
// }

// Check if all jobs in the group are finished.
// @(require_results)
// group_is_finished :: #force_inline proc(group: ^Group) -> bool {
//     return intrinsics.atomic_load(&group.atomic_counter) <= 0
// }
