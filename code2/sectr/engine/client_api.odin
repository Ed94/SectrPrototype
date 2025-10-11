package sectr

import    "base:runtime"
import  c "core:c/libc"
import    "core:dynlib"

Path_Assets       :: "../assets/"
Path_Shaders      :: "../shaders/"
Path_Input_Replay :: "input.sectr_replay"

ModuleAPI :: struct {
	lib:        dynlib.Library,
	// write-time: FileTime,

	startup:    type_of( startup ),
	hot_reload: type_of( hot_reload ),
}

StartupContext :: struct {}

@export
startup :: proc(host_mem: ^HostMemory)
{


	thread_wide_startup()
}

thread_wide_startup :: proc()
{

}

@export
hot_reload :: proc()
{

}
