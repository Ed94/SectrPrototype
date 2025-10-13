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

// TODO(Ed): We can technically hot-reload this (spin up or down lanes on reloads)
THREAD_TICK_LANES        :: 2
