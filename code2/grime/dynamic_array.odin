package grime

/*
Based on gencpp's and thus zpl's Array implementation
Made becasue of the map issue with fonts during hot-reload.
I didn't want to make the HMapZPL impl with the [dynamic] array for now to isolate the hot-reload issue (when I was diagnoising)

Update 2024-5-26:
TODO(Ed): Raw_Dynamic_Array is defined within base:runtime/core.odin and exposes what we need for worst case hot-reloads.
So its best to go back to regular dynamic arrays at some point.

Update 2025-5-12:
I can use either... so I'll just keep both
*/

ArrayHeader :: struct ( $ Type : typeid ) {
	backing   : AllocatorInfo,
	dbg_name  : string,
	capacity  : int,
	num       : int,
	data      : [^]Type,
}

Array :: struct ( $ Type : typeid ) {
	using header : ^ArrayHeader(Type),
}

array_underlying_slice :: proc(s: []($ Type)) -> Array(Type) {
	assert(len(slice) != 0)
	header_size :: size_of( ArrayHeader(Type))
	array       := cursor(to_bytes(s))[ - header_size]
	return 
}

array_to_slice          :: #force_inline proc "contextless" ( using self : Array($ Type) ) -> []Type { return slice( data, int(num))      }
array_to_slice_capacity :: #force_inline proc "contextless" ( using self : Array($ Type) ) -> []Type { return slice( data, int(capacity)) }

array_grow_formula :: proc( value : u64 ) -> u64 {
	result := (2 * value) + 8
	return result
}

array_init :: proc( $Array_Type : typeid/Array($Type), capacity : u64,
	allocator := context.allocator, fixed_cap : b32 = false, dbg_name : string = ""
) -> ( result : Array(Type), alloc_error : AllocatorError )
{
	header_size := size_of(ArrayHeader(Type))
	array_size  := header_size + int(capacity) * size_of(Type)

	raw_mem : rawptr
	raw_mem, alloc_error = alloc( array_size, allocator = allocator )
	// log( str_fmt_tmp("array reserved: %d", header_size + int(capacity) * size_of(Type) ))
	if alloc_error != AllocatorError.None do return

	result.header    = cast( ^ArrayHeader(Type)) raw_mem
	result.backing   = allocator
	result.dbg_name  = dbg_name
	result.fixed_cap = fixed_cap
	result.capacity  = capacity
	result.data      = cast( [^]Type ) (cast( [^]ArrayHeader(Type)) result.header)[ 1:]
	return
}
