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

	startup:     type_of( startup ),
	shutdown:    type_of( sectr_shutdown ),
	reload:      type_of( hot_reload ),
	tick:        type_of( tick ),
	clean_frame: type_of( clean_frame ),
}

StartupContext :: struct {}

@export
startup :: proc(ctx: StartupContext)
{

}

@export
sectr_shutdown :: proc()
{

}

@export
hot_reload :: proc()
{

}

@export
tick :: proc()
{

}

@export
clean_frame ::proc()
{

}
