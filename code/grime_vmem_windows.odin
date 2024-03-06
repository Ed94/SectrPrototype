/* Windows Virtual Memory
Windows is the only os getting special vmem definitions
since I want full control of it for debug purposes.
*/
package sectr

import "core:mem/virtual"
import win32 "core:sys/windows"

when ODIN_OS == OS_Type.Windows {

@(require_results)
virtual__reserve ::
proc "contextless" ( base_address : uintptr, size : uint ) -> ( vmem : VirtualMemoryRegion, alloc_error : AllocatorError )
{
	header_size :: cast(uint) size_of(VirtualMemoryRegion)

	result := win32.VirtualAlloc( rawptr(base_address), header_size + size, win32.MEM_RESERVE, win32.PAGE_READWRITE )
	if result == nil {
		alloc_error = .Out_Of_Memory
		return
	}

	vmem.base_address  = cast(^VirtualMemoryRegionHeader) result
	vmem.reserve_start = memory_after_header(vmem.base_address)
	vmem.reserved      = size
	vmem.committed     = 0
	alloc_error        = .None
	return
}

} // END: ODIN_OS == runtime.Odin_OS_Type.Windows
