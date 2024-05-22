/*
The default arena allocator Odin provides does fragmented resizes even for the last most allocated block getting resized.
This is an alternative to alleviates that.

TODO(Ed): Implement? Maybe we should trash this I' haven't seen a need to step away from using odin's
*/
package sectr

import "core:mem"

// Initialize a sub-section of our virtual memory as a sub-arena
sub_arena_init :: proc( address : ^byte, size : int ) -> ( ^ Arena) {
	Arena :: mem.Arena

	arena_size :: size_of( Arena)
	sub_arena  := cast( ^ Arena ) address
	mem_slice  := slice_ptr( ptr_offset( address, arena_size), size )
	arena_init( sub_arena, mem_slice )
	return sub_arena
}

ArenaFixedHeader :: struct {
	data      : []byte,
	offset    : uint,
	peak_used : uint,
}

ArenaFixed :: struct {
	using header : ^ArenaFixedHeader,
}

arena_fixed_init :: proc( backing : []byte ) -> (arena : ArenaFixed) {
	header_size := size_of(ArenaFixedHeader)

	verify(len(backing) >= (header_size + Kilobyte), "Attempted to init an arena with less than kilobyte of memory...")

	arena.header = cast(^ArenaFixedHeader) raw_data(backing)
	using arena.header
	data_ptr := cast([^]byte) (cast( [^]ArenaFixedHeader) arena.header)[ 1:]
	data      = slice_ptr( data_ptr, len(backing) - header_size )
	offset    = 0
	peak_used = 0
	return
}

arena_fixed_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	location       := #caller_location
) -> ([]byte, AllocatorError)
{


	return nil, .Out_Of_Memory
}

