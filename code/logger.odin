package sectr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:os"
import "core:strings"
import "core:time"
import core_log "core:log"

Max_Logger_Message_Width :: 80

LogLevel :: core_log.Level

Logger :: struct {
	file_path : string,
	file      : os.Handle,
	id        : string,
}

to_odin_logger :: proc( logger : ^ Logger ) -> core_log.Logger {
	return { logger_interface, logger, core_log.Level.Debug, core_log.Default_File_Logger_Opts }
}

init :: proc( logger : ^ Logger,  id : string, file_path : string, file := os.INVALID_HANDLE )
{
	if file == os.INVALID_HANDLE
	{
		logger_file, result_code := os.open( file_path, os.O_RDWR | os.O_CREATE )
		if result_code != os.ERROR_NONE {
				// Log failures are fatal and must never occur at runtime (there is no logging)
				runtime.debug_trap()
				os.     exit( -1 )
				// TODO(Ed) : Figure out the error code enums..
		}
		logger.file = logger_file
	}
	else {
		logger.file = file
	}
	logger.file_path = file_path
	logger.id        = id

	context.logger = { logger_interface, logger, core_log.Level.Debug, core_log.Default_File_Logger_Opts }
	log("Initialized Logger")
	when false {
		log("This sentence is over 80 characters long on purpose to test the ability of this fucking logger to properfly fucking wrap long as fuck logs with a new line and then at the end of that pad it with the appropraite signature.")
	}
}

logger_interface :: proc(
	logger_data :  rawptr,
	level       :  core_log.Level,
	text        :  string,
	options     :  core_log.Options,
	location    := #caller_location )
{
	logger := cast(^ Logger) logger_data

	@static builder_backing : [16 * Kilobyte] byte; {
		mem.set( raw_data( builder_backing[:] ), 0, len(builder_backing) )
	}
	builder := strings.builder_from_bytes( builder_backing[:] )

	first_line_length := len(text) > Max_Logger_Message_Width ? Max_Logger_Message_Width : len(text)
	first_line        := transmute(string) text[ 0 : first_line_length ]
	fmt.sbprintf( & builder, "%-*s ", Max_Logger_Message_Width, first_line )

	// Signature
	{
		when time.IS_SUPPORTED
		{
			if core_log.Full_Timestamp_Opts & options != nil {
				fmt.sbprint( & builder, "[")

				t := time.now()
				y, m,   d := time.date(t)
				h, min, s := time.clock(t)

				if .Date in options {
					fmt.sbprintf( & builder, "%d-%02d-%02d ", y, m, d )
				}
				if .Time in options {
					fmt.sbprintf( & builder, "%02d:%02d:%02d", h, min, s)
				}

				fmt.sbprint( & builder, "] ")
			}
		}
		core_log.do_level_header( options, level, & builder )

		if logger.id != "" {
			fmt.sbprintf( & builder, "[%s] ", logger.id )
		}
		core_log.do_location_header( options, & builder, location  )
	}

	// Oversized message handling
	if len(text) > Max_Logger_Message_Width
	{
		offset := Max_Logger_Message_Width
		bytes  := transmute([]u8) text
		for left := len(bytes) - Max_Logger_Message_Width; left > 0; left -= Max_Logger_Message_Width
		{
			fmt.sbprintf( & builder, "\n" )
			subset_length := len(text) - offset
			if subset_length > Max_Logger_Message_Width {
				subset_length = Max_Logger_Message_Width
			}
			subset := slice_ptr( ptr_offset( raw_data(bytes), offset), subset_length )
			fmt.sbprintf( & builder, "%s", transmute(string)subset )
			offset += Max_Logger_Message_Width
		}
	}

	fmt.fprintln( logger.file, strings.to_string(builder) )
}

log :: proc( msg : string, level := LogLevel.Info, loc := #caller_location ) {
	core_log.log( level, msg, location = loc )
}

logf :: proc( fmt : string, args : ..any,  level := LogLevel.Info, loc := #caller_location  ) {
	core_log.logf( level, fmt, args, location = loc )
}
