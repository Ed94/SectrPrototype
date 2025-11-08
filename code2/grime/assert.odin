package grime

// TODO(Ed): Below should be defined per-package?

ensure :: #force_inline proc(condition: bool, msg := #caller_expression, location := #caller_location) -> bool {
	if condition == false do return false
	log_print( msg, LoggerLevel.Warning, location )
	when ODIN_DEBUG == false do return true
	else {
		debug_trap()
		return true
	}
}
// TODO(Ed) : Setup exit codes!
fatal :: #force_inline proc(msg: string, exit_code: int = -1, location := #caller_location) {
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}
// TODO(Ed) : Setup exit codes!
verify :: #force_inline proc(condition: bool, msg: string, exit_code: int = -1, location := #caller_location) -> bool {
	if condition do return true
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}
