package grime

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:mem"
import core_virtual "core:mem/virtual"
import "core:strings"
import win32 "core:sys/windows"

thread__highres_wait :: proc( desired_ms : f64, loc := #caller_location ) -> b32
{
	// label_backing : [1 * Megabyte]u8
	// label_arena   : Arena
	// arena_init( & label_arena, slice_ptr( & label_backing[0], len(label_backing)) )
	// label_u8  := str_fmt_tmp( "SECTR: WAIT TIMER")//, allocator = arena_allocator( &label_arena) )
	// label_u16 := win32.utf8_to_utf16( label_u8, context.temp_allocator) //arena_allocator( & label_arena) )

	timer := win32.CreateWaitableTimerExW( nil, nil, win32.CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, win32.TIMER_ALL_ACCESS )
	if timer == nil {
		msg := str_pfmt("Failed to create win32 timer - ErrorCode: %v", win32.GetLastError() )
		log_print( msg, LoggerLevel.Warning, loc)
		return false
	}

	due_time := win32.LARGE_INTEGER(desired_ms * MS_To_NS)
	result := win32.SetWaitableTimerEx( timer, & due_time, 0, nil, nil, nil, 0 )
	if ! result {
		msg := str_pfmt("Failed to set win32 timer - ErrorCode: %v", win32.GetLastError() )
		log_print( msg, LoggerLevel.Warning, loc)
		return false
	}

	WAIT_ABANDONED     : win32.DWORD : 0x00000080
	WAIT_IO_COMPLETION : win32.DWORD : 0x000000C0
	WAIT_OBJECT_0      : win32.DWORD : 0x00000000
	WAIT_TIMEOUT       : win32.DWORD : 0x00000102
	WAIT_FAILED        : win32.DWORD : 0xFFFFFFFF

	wait_result := win32.WaitForSingleObjectEx( timer, win32.INFINITE, win32.BOOL(true) )
	switch wait_result
	{
		case WAIT_ABANDONED:
			msg := str_pfmt("Failed to wait for win32 timer - Error: WAIT_ABANDONED" )
			log_print( msg, LoggerLevel.Error, loc)
			return false

		case WAIT_IO_COMPLETION:
			msg := str_pfmt("Waited for win32 timer: Ended by APC queued to the thread" )
			log_print( msg, LoggerLevel.Error, loc)
			return false

		case WAIT_OBJECT_0:
			msg := str_pfmt("Waited for win32 timer- Reason : WAIT_OBJECT_0" )
			log_print( msg, loc = loc)
			return false

		case WAIT_FAILED:
			msg := str_pfmt("Waited for win32 timer failed - ErrorCode: $v", win32.GetLastError() )
			log_print( msg, LoggerLevel.Error, loc)
			return false
	}

	return true
}

set__scheduler_granularity :: proc "contextless" ( desired_ms : u32 ) -> b32 {
	return win32.timeBeginPeriod( desired_ms ) == win32.TIMERR_NOERROR
}

WIN32_ERROR_INVALID_ADDRESS :: 487
WIN32_ERROR_COMMITMENT_LIMIT :: 1455
