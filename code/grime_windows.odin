package sectr

import "core:c"
import "core:c/libc"
import "core:fmt"
import "core:mem"
import core_virtual "core:mem/virtual"
import "core:strings"
import win32 "core:sys/windows"

when ODIN_OS == OS_Type.Windows {

thread__highres_wait :: proc( desired_ms : f64, loc := #caller_location ) -> b32
{
	// label_backing : [1 * Megabyte]u8
	// label_arena   : Arena
	// arena_init( & label_arena, slice_ptr( & label_backing[0], len(label_backing)) )
	// label_u8  := str_fmt_tmp( "SECTR: WAIT TIMER")//, allocator = arena_allocator( &label_arena) )
	// label_u16 := win32.utf8_to_utf16( label_u8, context.temp_allocator) //arena_allocator( & label_arena) )

	timer := win32.CreateWaitableTimerExW( nil, nil, win32.CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, win32.TIMER_ALL_ACCESS )
	if timer == nil {
		msg := str_fmt_tmp("Failed to create win32 timer - ErrorCode: %v", win32.GetLastError() )
		log( msg, LogLevel.Warning, loc)
		return false
	}

	due_time := win32.LARGE_INTEGER(desired_ms * MS_To_NS)
	result := win32.SetWaitableTimerEx( timer, & due_time, 0, nil, nil, nil, 0 )
	if ! result {
		msg := str_fmt_tmp("Failed to set win32 timer - ErrorCode: %v", win32.GetLastError() )
		log( msg, LogLevel.Warning, loc)
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
			msg := str_fmt_tmp("Failed to wait for win32 timer - Error: WAIT_ABANDONED" )
			log( msg, LogLevel.Error, loc)
			return false

		case WAIT_IO_COMPLETION:
			msg := str_fmt_tmp("Waited for win32 timer: Ended by APC queued to the thread" )
			log( msg, LogLevel.Error, loc)
			return false

		case WAIT_OBJECT_0:
			msg := str_fmt_tmp("Waited for win32 timer- Reason : WAIT_OBJECT_0" )
			log( msg, loc = loc)
			return false

		case WAIT_FAILED:
			msg := str_fmt_tmp("Waited for win32 timer failed - ErrorCode: $v", win32.GetLastError() )
			log( msg, LogLevel.Error, loc)
			return false
	}

	return true
}

set__scheduler_granularity :: proc "contextless" ( desired_ms : u32 ) -> b32 {
	return win32.timeBeginPeriod( desired_ms ) == win32.TIMERR_NOERROR
}

WIN32_ERROR_INVALID_ADDRESS :: 487
WIN32_ERROR_COMMITMENT_LIMIT :: 1455

@(require_results)
virtual__reserve :: proc "contextless" ( base_address : uintptr, size : uint ) -> ( vmem : VirtualMemoryRegion, alloc_error : AllocatorError )
{
	header_size := cast(uint) memory_align_formula(size_of(VirtualMemoryRegionHeader), mem.DEFAULT_ALIGNMENT)

	result := win32.VirtualAlloc( rawptr(base_address), header_size + size, win32.MEM_RESERVE, win32.PAGE_READWRITE )
	if result == nil {
		alloc_error = .Out_Of_Memory
		return
	}
	result = win32.VirtualAlloc( rawptr(base_address), header_size, win32.MEM_COMMIT, win32.PAGE_READWRITE )
	if result == nil
	{
		switch err := win32.GetLastError(); err
		{
			case 0:
				alloc_error = .Invalid_Argument
				return

			case WIN32_ERROR_INVALID_ADDRESS, WIN32_ERROR_COMMITMENT_LIMIT:
				alloc_error = .Out_Of_Memory
				return
		}

		alloc_error = .Out_Of_Memory
		return
	}

	vmem.base_address  = cast(^VirtualMemoryRegionHeader) result
	vmem.reserve_start  = cast([^]byte) (uintptr(vmem.base_address) + uintptr(header_size))
	vmem.reserved      = size
	vmem.committed     = header_size
	alloc_error        = .None
	return
}

} // END: ODIN_OS == runtime.Odin_OS_Type.Windows
