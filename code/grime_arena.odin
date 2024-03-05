/*
The default arena allocator Odin provides does fragmented resizes even for the last most allocated block getting resized.
This is an alternative to alleviates that.
*/
package sectr

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

