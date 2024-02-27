// TODO(Ed) : Move this to a grime package problably
package sectr

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:runtime"
import "core:os"

// Initialize a sub-section of our virtual memory as a sub-arena
sub_arena_init :: proc( address : ^ byte, size : int ) -> ( ^ Arena) {
	Arena :: mem.Arena

	arena_size :: size_of( Arena)
	sub_arena  := cast( ^ Arena ) address
	mem_slice  := slice_ptr( ptr_offset( address, arena_size), size )
	arena_init( sub_arena, mem_slice )
	return sub_arena
}

// Helper to get the the beginning of memory after a slice
memory_after :: proc( slice : []byte ) -> ( ^ byte) {
	return ptr_offset( & slice[0], len(slice) )
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
