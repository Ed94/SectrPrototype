package sectr

Path_Assets       :: "../assets/"
Path_Shaders      :: "../shaders/"
Path_Input_Replay :: "input.sectr_replay"


Path_Logs :: "../logs"
when ODIN_OS == .Windows
{
	Path_Module        :: "sectr.dll"
	Path_Live_Module   :: "sectr_live.dll"
	Path_Debug_Symbols :: "sectr.pdb"
	Path_Spall_Record  :: "sectr.spall"
}

DISABLE_CLIENT_PROFILING :: false
DISABLE_HOST_PROFILING   :: false

// Hard constraint for Windows
MAX_THREADS :: 64

// TODO(Ed): We can technically hot-reload this (spin up or down lanes on reloads)
THREAD_TICK_LANES        :: 2 // Must be at least one for main thread.
THREAD_JOB_WORKERS       :: 2 // Must be at least one for latent IO operations.

/*
Job workers are spawned in after tick lanes.
Even if the user adjust them at runtme in the future, 
we'd have all threads drain and respawn them from scratch.
*/
THREAD_JOB_WORKER_ID_START :: THREAD_TICK_LANES
THREAD_JOB_WORKER_ID_END   :: (THREAD_TICK_LANES + THREAD_JOB_WORKERS)
