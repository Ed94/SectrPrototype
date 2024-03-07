/* Virtual Memory OS Interface
This is an alternative to the virtual core library provided by odin, suppport setting the base address among other things.
*/
package sectr

import core_virtual "core:mem/virtual"
import "core:os"

VirtualMemoryRegionHeader :: struct {
	committed     : uint,
	reserved      : uint,
	reserve_start : [^]byte,
}

VirtualMemoryRegion :: struct {
	using base_address : ^VirtualMemoryRegionHeader
}

virtual_get_page_size :: proc "contextless" () -> int {
	@static page_size := 0
	if page_size == 0 {
		page_size = os.get_page_size()
	}
	return page_size
}

virtual_reserve_remaining :: proc "contextless" ( using vmem : VirtualMemoryRegion ) -> uint {
	header_offset := cast(uint) (uintptr(reserve_start) - uintptr(vmem.base_address))
	return reserved - header_offset
}

@(require_results)
virtual_commit :: proc "contextless" ( using vmem : VirtualMemoryRegion, size : uint ) -> ( alloc_error : AllocatorError )
{
	if size < committed {
		return .None
	}

	header_size := size_of(VirtualMemoryRegionHeader)
	page_size   := uint(virtual_get_page_size())
	to_commit   := memory_align_formula( size, page_size )

	alloc_error = core_virtual.commit( base_address, to_commit )
	if alloc_error != .None {
		return alloc_error
	}

	base_address.committed = size
	return alloc_error
}

virtual_decommit :: proc "contextless" ( vmem : VirtualMemoryRegion, size : uint ) {
	core_virtual.decommit( vmem.base_address, size )
}

virtual_protect :: proc "contextless" ( vmem : VirtualMemoryRegion, region : []byte, flags : VirtualProtectFlags ) -> b32
{
	page_size := virtual_get_page_size()

	if len(region) % page_size != 0 {
		return false
	}

	return cast(b32) core_virtual.protect( raw_data(region), len(region), flags )
}

@(require_results)
virtual_reserve :: proc "contextless" ( base_address : uintptr, size : uint ) -> ( VirtualMemoryRegion, AllocatorError ) {
	page_size  := uint(virtual_get_page_size())
	to_reserve := memory_align_formula( size, page_size )
	return virtual__reserve( base_address, to_reserve )
}

@(require_results)
virtual_reserve_and_commit :: proc "contextless" (
	base_address : uintptr, reserve_size, commit_size : uint
) -> ( vmem : VirtualMemoryRegion, alloc_error : AllocatorError )
{
	if reserve_size < commit_size {
		alloc_error = .Invalid_Argument
		return
	}

	vmem, alloc_error = virtual_reserve( base_address, reserve_size )
	if alloc_error != .None {
		return
	}

	alloc_error = virtual_commit( vmem, commit_size )
	return
}

virtual_release :: proc "contextless" ( vmem : VirtualMemoryRegion ) {
	core_virtual.release( vmem.base_address, vmem.reserved )
}

// If the OS is not windows, we just use the library's interface which does not support base_address.
when ODIN_OS != OS_Type.Windows {

virtual__reserve :: proc "contextless" ( base_address : uintptr, size : uint ) -> ( vmem : VirtualMemoryRegion, alloc_error : AllocatorError )
{
	header_size := size_of(VirtualMemoryRegionHeader)

	// Ignoring the base address, add an os specific impl if you want it.
	data : []byte
	data, alloc_error := core_virtual.reserve( header_size + size ) or_return
	alloc_error := core_virtual.commit( header_size )

	vmem.base_address  := cast( ^VirtualMemoryRegionHeader ) raw_data(data)
	vmem.reserve_start  = memory_after_header(vmem.base_address)
	vmem.reserved       = len(data)
	vmem.committed      = header_size
	return
}

} // END: ODIN_OS != runtime.Odin_OS_Type.Windows
