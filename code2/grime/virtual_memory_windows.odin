package grime

import "core:mem"
import win32 "core:sys/windows"

@(require_results)
virtual_resreve__platform_impl :: proc "contextless" ( base_address : uintptr, size : uint ) -> ( vmem : VirtualMemoryRegion, alloc_error : AllocatorError )
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
