/*
Odin's virtual arena allocator doesn't do what I ideally want for allocation resizing.
(It was also a nice exercise along with making the other allocators)

So this is a virtual memory backed arena allocator designed
to take advantage of one large contigous reserve of memory.
With the expectation that resizes with its interface will only occur using the last allocated block.

All virtual address space memory for this application is managed by a virtual arena.
No other part of the program will directly touch the vitual memory interface direclty other than it.

Thus for the scope of this prototype the Virtual Arena are the only interfaces to dynamic address spaces for the runtime of the client app.
The host application as well ideally (although this may not be the case for a while)
*/
package sectr

import "base:intrinsics"
import "core:mem"
import "core:os"
import "core:slice"
import "core:sync"

VArena_GrowthPolicyEntry :: struct {
	// The upper limit until this policy is no longer valid
	// set to 0 if its desired to be always valid)
	commit_limit   : uint,

	// How much to increment by if the next allocation
	// If the upcoming allocation size is larger than this,
  // then the allocation size is used instead.
	increment : uint,
}

VArena_GrowthPolicyProc :: #type proc( commit_used, committed, reserved, requested_size : uint ) -> uint

VArena :: struct {
	using vmem    : VirtualMemoryRegion,
	commit_used   : uint,
	growth_policy : VArena_GrowthPolicyProc,
	mutex         : sync.Mutex,
}

varena_default_growth_policy :: proc( commit_used, committed, reserved, requested_size : uint ) -> uint
{
	@static commit_limit := uint(1  * Megabyte)
	@static increment    := uint(16 * Kilobyte)
	page_size := uint(virtual_get_page_size())

	if increment < Gigabyte && committed > commit_limit {
		commit_limit *= 2
		increment    *= 2

		increment = clamp( increment, Megabyte, Gigabyte )
	}

	remaining_reserve := reserved - committed
	growth_increment  := max( increment, requested_size )
	growth_increment   = clamp( growth_increment, page_size, remaining_reserve )
	next_commit_size  := memory_align_formula( committed + growth_increment, page_size )
	return next_commit_size
}

varena_allocator :: proc( arena : ^VArena ) -> ( allocator : Allocator ) {
	allocator.procedure = varena_allocator_proc
	allocator.data      = arena
	return
}

// Default growth_policy is nil
varena_init :: proc( base_address : uintptr, to_reserve, to_commit : uint,
	growth_policy : VArena_GrowthPolicyProc
) -> ( arena : VArena, alloc_error : AllocatorError)
{
	page_size := uint(virtual_get_page_size())
	verify( page_size > size_of(VirtualMemoryRegion), "Make sure page size is not smaller than a VirtualMemoryRegion?")
	verify( to_reserve >= page_size, "Attempted to reserve less than a page size" )
	verify( to_commit  >= page_size, "Attempted to commit less than a page size")
	verify( to_reserve >= to_commit, "Attempted to commit more than there is to reserve" )

	vmem : VirtualMemoryRegion
	vmem, alloc_error = virtual_reserve_and_commit( base_address, to_reserve, to_commit )
	if vmem.base_address == nil || alloc_error != .None {
		ensure(false, "Failed to allocate requested virtual memory for virtual arena")
		return
	}

	arena.vmem        = vmem
	arena.commit_used = 0

	if growth_policy == nil {
		arena.growth_policy = varena_default_growth_policy
	}
	else {
		arena.growth_policy = growth_policy
	}
	return
}

varena_alloc :: proc( using self : ^VArena,
	size        : uint,
	alignment   : uint = mem.DEFAULT_ALIGNMENT,
	zero_memory := true,
	location    := #caller_location
) -> ( data : []byte, alloc_error : AllocatorError )
{
	verify( alignment & (alignment - 1) == 0, "Non-power of two alignment", location = location )
	context.user_ptr = self
	page_size := uint(virtual_get_page_size())

	requested_size := size
	if requested_size == 0 {
		return nil, .Invalid_Argument
	}

	sync.mutex_guard( & mutex )

	alignment_offset := uint(0)
	current_offset   := cast(uintptr) reserve_start[ commit_used:]
	mask             := uintptr(alignment - 1)

	if current_offset & mask != 0 {
		alignment_offset = alignment - uint(current_offset & mask)
	}

	size_to_allocate, overflow_signal := intrinsics.overflow_add( requested_size, alignment_offset )
	if overflow_signal {
		alloc_error = .Out_Of_Memory
		return
	}

	to_be_used : uint
	to_be_used, overflow_signal = intrinsics.overflow_add( commit_used, size_to_allocate )
	if overflow_signal || to_be_used > reserved {
		alloc_error = .Out_Of_Memory
		return
	}

	header_offset := uint( uintptr(reserve_start) - uintptr(base_address) )

	commit_left          := committed - commit_used - header_offset
	needs_more_committed := commit_left < size_to_allocate
	if needs_more_committed
	{
		next_commit_size := growth_policy( commit_used, committed, reserved, size_to_allocate )
		alloc_error       = virtual_commit( vmem, next_commit_size )
		if alloc_error != .None {
			return
		}
	}

	aligned_start := uintptr(self.commit_used + alignment_offset)
	data_ptr      := rawptr(uintptr( reserve_start ) + aligned_start)
	data           = byte_slice( data_ptr, int(requested_size) )
	commit_used   += size_to_allocate
	alloc_error    = .None

	if zero_memory {
		slice.zero( data )
	}
	return
}

varena_free_all :: proc( using self : ^VArena )
{
	sync.mutex_guard( & mutex )
	commit_used = 0
}

varena_release :: proc( using self : ^VArena )
{
	sync.mutex_guard( & mutex )

	virtual_release( vmem )
	commit_used = 0
}

varena_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	location       : SourceCodeLocation = #caller_location
) -> ( data : []byte, alloc_error : AllocatorError)
{
	arena := cast( ^VArena) allocator_data

	size      := uint(size)
	alignment := uint(alignment)
	old_size  := uint(old_size)

	switch mode
	{
		case .Alloc, .Alloc_Non_Zeroed:
			return varena_alloc( arena, size, alignment, (mode != .Alloc_Non_Zeroed), location )

		case .Free:
			alloc_error = .Mode_Not_Implemented

		case .Free_All:
			varena_free_all( arena )

		case .Resize, .Resize_Non_Zeroed:
			if old_memory == nil {
				return varena_alloc( arena, size, alignment, (mode != .Resize_Non_Zeroed), location )
			}

			if size == old_size {
				data = byte_slice( old_memory, old_size )
				return
			}

			alignment_offset := uintptr(old_memory) & uintptr(alignment - 1)
			if alignment_offset == 0 && size < old_size {
				data = byte_slice( old_memory, size )
				return
			}

			old_memory_offset := uintptr(old_memory)    + uintptr(old_size)
			current_offset    := uintptr(arena.reserve_start) + uintptr(arena.commit_used)
			verify( old_memory_offset != current_offset, "Cannot resize existing allocation in vitual arena to a larger size unless it was the last allocated" )

			new_region : []byte
			new_region, alloc_error = varena_alloc( arena, size - old_size, alignment, (mode != .Resize_Non_Zeroed), location )
			if new_region == nil || alloc_error != .None {
				data = byte_slice( old_memory, old_size )
				return
			}

			data := byte_slice( old_memory, size )
			return

		case .Query_Features:
		{
			set := cast( ^AllocatorModeSet) old_memory
			if set != nil {
				(set ^) = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Query_Features}
			}
		}
		case .Query_Info:
		{
			alloc_error = .Mode_Not_Implemented
		}
	}
	return
}
