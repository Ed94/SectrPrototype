package grime

import "base:runtime"
import "core:io"
import "core:os"
import "core:text/table"

dump_stacktrace :: proc( allocator := context.temp_allocator ) -> string
{
	trace_result := stacktrace()
	lines, error := stacktrace_lines( trace_result )

	padding := "    "

	log_table := table.init( & table.Table{}, context.temp_allocator, context.temp_allocator )
	for line in lines {
		table.row( log_table, padding, line.symbol, " - ", line.location )
	}
	// table.build(log_table)
	// TODO(Ed): regression with the stack trace lib

	writer_builder : StringBuilder
	str_builder_init( & writer_builder, allocator = allocator )

	writer := to_writer( & writer_builder )
	for row in 2 ..< log_table.nr_rows   {
		for col in 0 ..< log_table.nr_cols {
			table.write_table_cell( writer, log_table, row, col )
		}
		io.write_byte( writer, '\n' )
	}

	return to_string( writer_builder )
}

ensure :: #force_inline proc( condition : b32, msg : string, location := #caller_location )
{
	if condition {
		return
	}
	log( msg, LogLevel.Warning, location )
	runtime.debug_trap()
}

// TODO(Ed) : Setup exit codes!
fatal :: #force_inline proc( msg : string, exit_code : int = -1, location := #caller_location )
{
	log( msg, LogLevel.Fatal, location )
	runtime.debug_trap()
	os.exit( exit_code )
}

// TODO(Ed) : Setup exit codes!
verify :: #force_inline proc( condition : b32, msg : string, exit_code : int = -1, location := #caller_location )
{
	if condition {
		return
	}
	log( msg, LogLevel.Fatal, location )
	runtime.debug_trap()
	os.exit( exit_code )
}
