package grime

// Below should be defined per-package

ensure :: #force_inline proc( condition : b32, msg : string, location := #caller_location ) {
	if condition do return
	log_print( msg, LoggerLevel.Warning, location )
	debug_trap()
}
// TODO(Ed) : Setup exit codes!
fatal :: #force_inline proc( msg : string, exit_code : int = -1, location := #caller_location ) {
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}
// TODO(Ed) : Setup exit codes!
verify :: #force_inline proc( condition : b32, msg : string, exit_code : int = -1, location := #caller_location ) {
	if condition do return
	log_print( msg, LoggerLevel.Fatal, location )
	debug_trap()
	process_exit( exit_code )
}
