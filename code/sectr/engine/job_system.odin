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
	// scratch: CArena,
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

WorkerID :: enum u32 {
	Master_Prepper = 0,
	
	API_Apologist,
	Artifical_Sweetener,
	Assertion_Avenger,
	Async_Antagonist,
	Atomic_Accountant,
	Black_Box_Provider,
	Bit_Rot_Repacker,
	Big_O_Admirer,
	Blitting_Bandit,
	Blockchain_Believer,
	Blue_Caller,
	Blue_Screen_Shopper,
	Branch_Mispredictor,
	Breakpoint_Bandit,
	Buffer_Baron,
	Cache_Concierge,
	Cafecito_Barista,
	Callback_Operator,
	Callstack_Canopy,
	Carpe_Datum,
	Chief_Synergy_Officer,
	Cipher_Clerk,
	Conscripted_Camper,
	Dean_Of_Misplaced_Delegation,
	Dereference_Doctorate,
	Checkbox_Boi,
	Credible_Threat,
	Dead_Drop_Delegate,
	Deadline_Denialist,
	Deadlock_Daemon,
	DMA_Desperado,
	Dump_Curator,
	Edge_Case_Evangelist,
	Enterprise_Entangler,
	Exception_Excavator,
	Git_Blame_Archaeologist,
	Feature_Creeper,
	Feature_Freeze_Fighter,
	Fencepost_Fiddler,
	Fitness_Unpacker,
	Flop_Flipper,
	Floating_Point_Propoganda,
	Forgets_To_Check,
	Global_Guardian,
	Goto_Goon,
	Ghost_Protocols,
	Halting_Solver,
	Handshake_Hypeman,
	Headcount_Hoarder,
	Heisenbug_Hunter,
	Heuristic_Hypnotist,
	Hotfix_Hooligan,
	Hot_Path_Hitchhiker,
	Idle_Malware,
	Implementation_Detailer,
	Interrupt_Ignorer,
	Interrupt_Insurgent,
	Jank_Jockey,
	Jefe_De_Errores,
	Kickoff_Holiday,
	Kilobyte_Kingpin,
	KPI_Keeper,
	Latency_Lover,
	Leeroy_Jenkins,
	Legacy_Liaison,
	Loop_Lobbyist,
	Linter_Lamenter,
	Lock_Free_Liar,
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
	Panic_As_A_Service,
	Paradigm_Pivoter,
	Patient_Zero_Pollinator,
	Payload_Plunderer,
	Perpetual_Peon,
	Phishing_Pharmacist,
	Pipeline_Plumber,
	Pointer_Pilgrim,
	Production_Pusher,
	Quiet_Quitter,
	Query_Gremlin,
	Race_Condition_Gambler,
	Rebase_Renegade,
	Red_Tape_Renderer,
	Resting_Receptionist,
	Quantum_Quibbler,
	Regex_Rancher,
	Register_Riveter,
	Register_Spill_Rancher,
	Roadmap_Revisionist,
	Rootkit_Realtor,
	Runtime_Ruffian,
	Sabbatical_Scheduler,
	Shift_Manager,
	Speculative_Skeptic,
	Segfault_Stretcher,
	Siesta_Scheduler,
	Singleton_Sinner,
	Sleeper_Cell_Spammer,
	Spaghetti_Chef,
	Spinlock_Spelunker,
	Stack_Smuggler,
	Stakeholder_Simulator,
	TCP_Tango,
	Techdebt_Treasurer,
	Tenured_Trapper,
	Thread_Local_Tourist,
	Triage_Technician,
	Tunnel_Fisherman,
	Type_Theorist,
	UDP_Unicycle,
	Unattended_Child,
	Undefined_Behavior_Brokerage,
	Unreachable_Utopian,
	Unicode_Usurper,
	Unsafe_Advocate,
	Unsigned_Vigilante,
	Unwind_Understudy,
	Voltage_Vampire,
	Vibe_Checker,
	Virtual_Vagrant,
	Volatile_Vandal,
	Void_Voyager,
	Waiting_Room_Warden,
	Weltschmerz_Worker,
	While_True_Wanderer,
	Write_Barrier_Warden,
	XORcist,
	YAGNI_Yeller,
	Yellowpage_Dialer,	
	Zeroring_Comissioner,
	Zero_Cost_Commando,
	Zero_Day_Dreamer,
	Zombie_Zookeeper,
	Zombo_Vistor,
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
