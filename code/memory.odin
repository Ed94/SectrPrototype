package sectr

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:runtime"
import "core:os"

Byte     :: 1
Kilobyte :: 1024 * Byte
Megabyte :: 1024 * Kilobyte
Gigabyte :: 1024 * Megabyte
Terabyte :: 1024 * Gigabyte
Petabyte :: 1024 * Terabyte
Exabyte  :: 1024 * Petabyte

kilobytes :: proc ( kb : $ integer_type ) -> integer_type {
	return kb * Kilobyte
}
megabytes :: proc ( mb : $ integer_type ) -> integer_type {
	return mb * Megabyte
}
gigabyte  :: proc ( gb : $ integer_type ) -> integer_type {
	return gb * Gigabyte
}
terabyte  :: proc ( tb : $ integer_type ) -> integer_type {
	return tb * Terabyte
}

// Initialize a sub-section of our virtual memory as a sub-arena
sub_arena_init :: proc( address : ^ byte, size : int ) -> ( ^ mem.Arena) {
	Arena :: mem.Arena

	arena_size :: size_of( Arena)
	sub_arena  := cast( ^ Arena ) address
	mem_slice  := mem.slice_ptr( mem.ptr_offset( address, arena_size), size )
	mem.arena_init( sub_arena, mem_slice )
	return sub_arena
}

// Helper to get the the beginning of memory after a slice
memory_after :: proc( slice : []byte ) -> ( ^ byte) {
	return mem.ptr_offset( & slice[0], len(slice) )
}

// Since this is a prototype, all memory is always tracked. No arena is is interfaced directly.
TrackedAllocator :: struct {
	backing   : mem.Arena,
	internals : mem.Arena,
	tracker   : mem.Tracking_Allocator,
}

tracked_allocator :: proc ( self : ^ TrackedAllocator ) -> mem.Allocator {
	return mem.tracking_allocator( & self.tracker )
}

tracked_allocator_init :: proc( size, internals_size : int ) -> TrackedAllocator
{
	result : TrackedAllocator

	Arena              :: mem.Arena
	Tracking_Allocator :: mem.Tracking_Allocator
	arena_allocator    :: mem.arena_allocator
	arena_init         :: mem.arena_init
	slice_ptr          :: mem.slice_ptr

	arena_size              :: size_of( Arena)
	backing_size            := size           + arena_size
	internals_size          := internals_size + arena_size
	raw_size                := backing_size + internals_size

	raw_mem, raw_mem_code := mem.alloc( raw_size )
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
	mem.tracking_allocator_init( & result.tracker, backing_allocator, internals_allocator )
	return result
}

tracked_allocator_init_vmem :: proc( vmem : [] byte, internals_size : int ) -> ^ TrackedAllocator
{
	Arena                  :: mem.Arena
	Tracking_Allocator     :: mem.Tracking_Allocator
	arena_allocator        :: mem.arena_allocator
	arena_init             :: mem.arena_init
	tracking_alloator_init :: mem.tracking_allocator_init
	ptr_offset             :: mem.ptr_offset
	slice_ptr              :: mem.slice_ptr

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

	tracking_alloator_init( & result.tracker, arena_allocator( backing ), arena_allocator( internals ) )
	return result
}
