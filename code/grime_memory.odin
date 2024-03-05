// TODO(Ed) : Move this to a grime package problably
package sectr

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:runtime"
import "core:os"

kilobytes :: #force_inline proc "contextless" ( kb : $ integer_type ) -> integer_type {
	return kb * Kilobyte
}
megabytes :: #force_inline proc "contextless" ( mb : $ integer_type ) -> integer_type {
	return mb * Megabyte
}
gigabytes  :: #force_inline proc "contextless" ( gb : $ integer_type ) -> integer_type {
	return gb * Gigabyte
}
terabytes  :: #force_inline proc "contextless" ( tb : $ integer_type ) -> integer_type {
	return tb * Terabyte
}

// See: core/mem.odin, I wanted to study it an didn't like the naming.
@(require_results)
calc_padding_with_header :: proc "contextless" (pointer: uintptr, alignment: uintptr, header_size: int) -> int
{
	alignment_offset := pointer & (alignment - 1)

	initial_padding := uintptr(0)
	if alignment_offset != 0 {
			initial_padding = alignment - alignment_offset
	}

	header_space_adjustment := uintptr(header_size)
	if initial_padding < header_space_adjustment
	{
			additional_space_needed := header_space_adjustment - initial_padding
			unaligned_extra_space   := additional_space_needed & (alignment - 1)

			if unaligned_extra_space > 0 {
					initial_padding += alignment * (1 + (additional_space_needed / alignment))
			}
			else {
					initial_padding += alignment * (additional_space_needed / alignment)
			}
	}

	return int(initial_padding)
}

// Helper to get the the beginning of memory after a slice
memory_after :: proc( slice : []byte ) -> ( ^ byte) {
	return ptr_offset( & slice[0], len(slice) )
}

memory_after_header :: proc( header : ^($ Type) ) -> ( [^]byte) {
	return cast( [^]byte) (cast( [^]Type) header)[ 1:]
}

// Initialize a sub-section of our virtual memory as a sub-arena
sub_arena_init :: proc( address : ^ byte, size : int ) -> ( ^ Arena) {
	Arena :: mem.Arena

	arena_size :: size_of( Arena)
	sub_arena  := cast( ^ Arena ) address
	mem_slice  := slice_ptr( ptr_offset( address, arena_size), size )
	arena_init( sub_arena, mem_slice )
	return sub_arena
}


// Since this is a prototype, all memory is always tracked. No arena is is interfaced directly.
TrackedAllocator :: struct {
	backing   : Arena,
	internals : Arena,
	tracker   : TrackingAllocator,
}

tracked_allocator :: proc( self : ^ TrackedAllocator ) -> Allocator {
	return tracking_allocator( & self.tracker )
}

// TODO(Ed): These allocators are bad... not sure why.
tracked_allocator_init :: proc( size, internals_size : int, allocator := context.allocator ) -> TrackedAllocator
{
	result : TrackedAllocator

	arena_size     :: size_of( Arena)
	backing_size   := size           + arena_size
	internals_size := internals_size + arena_size
	raw_size       := backing_size + internals_size

	raw_mem, raw_mem_code := alloc( raw_size, mem.DEFAULT_ALIGNMENT, allocator )
	verify( raw_mem_code == AllocatorError.None, "Failed to allocate memory for the TrackingAllocator" )

	backing_slice   := slice_ptr( cast( ^ byte) raw_mem,        backing_size )
	internals_slice := slice_ptr( memory_after( backing_slice), internals_size )

	arena_init( & result.backing,   backing_slice )
	arena_init( & result.internals, internals_slice )

	backing_allocator   := arena_allocator( & result.backing )
	internals_allocator := arena_allocator( & result.internals )
	tracking_allocator_init( & result.tracker, backing_allocator, internals_allocator )
	{
		tracker_arena := cast(^Arena) result.tracker.backing.data
		arena_len     := len( tracker_arena.data )
		verify( arena_len == len(result.backing.data), "BAD SIZE ON TRACKER'S ARENA" )
	}
	return result
}

arena_allocator_init_vmem :: proc( vmem : [] byte ) -> ^ Arena
{
	arena_size   :: size_of( Arena)
	backing_size := len(vmem)

	result       := cast( ^ Arena) & vmem[0]
	result_slice := slice_ptr( & vmem[0], arena_size )

	backing_slice := slice_ptr( memory_after( result_slice), backing_size )
	arena_init( result, backing_slice )
	return result
}

tracked_allocator_init_vmem :: proc( vmem : [] byte, internals_size : int ) -> ^ TrackedAllocator
{
	arena_size              :: size_of( Arena)
	tracking_allocator_size :: size_of( TrackingAllocator )
	backing_size            := len(vmem)    - internals_size
	raw_size                := backing_size + internals_size

	verify( backing_size >= 0 && len(vmem) >= raw_size, "Provided virtual memory slice is not large enough to hold the TrackedAllocator" )

	result       := cast( ^ TrackedAllocator) & vmem[0]
	result_slice := slice_ptr( & vmem[0], tracking_allocator_size )

	backing_slice   := slice_ptr( memory_after( result_slice ), backing_size )
	internals_slice := slice_ptr( memory_after( backing_slice), internals_size )
	backing         := & result.backing
	internals       := & result.internals
	arena_init( backing,   backing_slice )
	arena_init( internals, internals_slice )

	tracking_allocator_init( & result.tracker, arena_allocator( backing ), arena_allocator( internals ) )
	return result
}
