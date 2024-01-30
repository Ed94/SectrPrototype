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
	tracker   : Tracking_Allocator,
}

tracked_allocator :: proc ( self : ^ TrackedAllocator ) -> Allocator {
	return tracking_allocator( & self.tracker )
}

tracked_allocator_init :: proc( size, internals_size : int, allocator := context.allocator ) -> TrackedAllocator
{
	result : TrackedAllocator

	arena_size     :: size_of( Arena)
	backing_size   := size           + arena_size
	internals_size := internals_size + arena_size
	raw_size       := backing_size + internals_size

	raw_mem, raw_mem_code := alloc( raw_size, mem.DEFAULT_ALIGNMENT, allocator )
	if ( raw_mem_code != mem.Allocator_Error.None )
	{
		// TODO(Ed) : Setup a proper logging interface
		fmt.    printf( "Failed to allocate memory for the TrackingAllocator" )
		runtime.debug_trap()
		os.     exit( -1 )
		// TODO(Ed) : Figure out the error code enums..
	}
	arena_init( & result.backing,   slice_ptr( cast( ^ byte) raw_mem,              backing_size   ) )
	arena_init( & result.internals, slice_ptr( memory_after( result.backing.data), internals_size ) )

	backing_allocator   := arena_allocator( & result.backing )
	internals_allocator := arena_allocator( & result.internals )
	tracking_allocator_init( & result.tracker, backing_allocator, internals_allocator )
	return result
}

tracked_allocator_init_vmem :: proc( vmem : [] byte, internals_size : int ) -> ^ TrackedAllocator
{
	arena_size              :: size_of( Arena)
	tracking_allocator_size :: size_of( Tracking_Allocator )
	backing_size            := len(vmem)    - internals_size
	raw_size                := backing_size + internals_size

	if backing_size < 0 || len(vmem) < raw_size
	{
		// TODO(Ed) : Setup a proper logging interface
		fmt.    printf( "Provided virtual memory slice is not large enough to hold the TrackedAllocator" )
		runtime.debug_trap()
		os.     exit( -1 )
		// TODO(Ed) : Figure out the error code enums..
	}

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
