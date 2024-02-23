package sectr 

import "base:runtime"
import "core:os"

ensure :: proc( condition : b32, msg : string, location := #caller_location )
{
	if condition {
		return
	}
	log( msg, LogLevel.Warning, location )
	runtime.debug_trap()
}

// TODO(Ed) : Setup exit codes!
fatal :: proc( msg : string, exit_code : int = -1, location := #caller_location )
{
	log( msg, LogLevel.Fatal, location )
	runtime.debug_trap()
	os.exit( exit_code )
}

verify :: proc( condition : b32, msg : string, exit_code : int = -1, location := #caller_location )
{
	if condition {
		return
	}
	log( msg, LogLevel.Fatal, location )
	runtime.debug_trap()
	os.exit( exit_code )
}
