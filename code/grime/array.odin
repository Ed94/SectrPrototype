/*
Based on gencpp's and thus zpl's Array implementation
Made becasue of the map issue with fonts during hot-reload.
I didn't want to make the HMapZPL impl with the [dynamic] array for now to isolate the hot-reload issue (when I was diagnoising)

Update 5-26-2024:
TODO(Ed): Raw_Dynamic_Array is defined within base:runtime/core.odin and exposes what we need for worst case hot-reloads.
So its best to go back to regular dynamic arrays at some point.
*/
package grime

import "core:c/libc"
import "core:mem"
import "core:slice"

ArrayHeader :: struct ( $ Type : typeid ) {
	backing   : Allocator,
	dbg_name  : string,
	fixed_cap : b32,
	capacity  : u64,
	num       : u64,
	data      : [^]Type,
}

Array :: struct ( $ Type : typeid ) {
	using header : ^ArrayHeader(Type),
}

array_underlying_slice :: proc(slice: []($ Type)) -> Array(Type)
{
	if len(slice) == 0 {
			return {nil}
	}
	header_size := size_of( ArrayHeader(Type))
	raw_data    := & slice[0]
	array       := transmute( Array(Type)) ( uintptr(raw_data) - uintptr(header_size))
	return array
}

array_to_slice          :: #force_inline proc( using self : Array($ Type) ) -> []Type { return slice_ptr( data, int(num))      }
array_to_slice_capacity :: #force_inline proc( using self : Array($ Type) ) -> []Type { return slice_ptr( data, int(capacity)) }

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

array_append_array :: proc( using self: ^Array( $ Type), other : Array(Type)) -> AllocatorError
{
	if num + other.num > capacity
	{
		grow_result := array_grow( self, num + other.num )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	// Note(Ed) : Original code from gencpp
	// libc.memcpy( ptr_offset(data, num), raw_data(items), len(items) * size_of(Type) )

	target := ptr_offset( data, num )

	dst_slice := slice_ptr(target, int(capacity - num))
	src_slice := array_to_slice(other)
	copy( dst_slice, src_slice )

	num += other.num
	return AllocatorError.None
}

array_append_slice :: proc( using self : ^Array( $ Type ), items : []Type ) -> AllocatorError
{
	items_num :=u64(len(items))
	if num + items_num > capacity
	{
		grow_result := array_grow( self, num + items_num )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	target := ptr_offset( data, num )
	copy( slice_ptr(target, int(capacity - num)), items )

	num += items_num
	return AllocatorError.None
}

array_append_value :: proc( self : ^Array( $ Type), value : Type ) -> AllocatorError
{
	// profile(#procedure)
	if self.header.num == self.header.capacity
	{
		grow_result := array_grow( self, self.header.capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	self.header.data[ self.header.num ] = value
	self.header.num        += 1
	return AllocatorError.None
}

array_append_at_value :: proc( using self : ^Array( $ Type ), item : Type, id : u64 ) -> AllocatorError
{
	id := id
	if id >= num {
		id = num - 1
	}
	if id < 0 {
		id = 0
	}

	if capacity < num + 1
	{
		grow_result := array_grow( self, capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	target := & data[id]
	libc.memmove( ptr_offset(target, 1), target, uint(num - id) * size_of(Type) )

	data[id] = item
	num     += 1
	return AllocatorError.None
}

array_append_at_slice :: proc( using self : ^Array( $ Type ), items : []Type, id : u64 ) -> AllocatorError
{
	id := id
	if id >= num {
		return array_append_slice( items )
	}
	if len(items) > capacity
	{
		grow_result := array_grow( self, capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	// Note(Ed) : Original code from gencpp
	// target := ptr_offset( data, id + len(items) )
	// src    := ptr_offset( data, id )
	// libc.memmove( target, src, num - id * size_of(Type) )
	// libc.memcpy ( src, raw_data(items), len(items) * size_of(Type) )

	// TODO(Ed) : VERIFY VIA DEBUG THIS COPY IS FINE
	ensure(false, "time to check....")
	target := & data[id + len(items)]
	dst    := slice_ptr( target, num - id - len(items) )
	src    := slice_ptr( & data[id], num - id )
	copy( dst, src )
	copy( src, items )

	num += len(items)
	return AllocatorError.None
}

array_back :: proc( self : Array($Type) ) -> Type {
	value := self.data[self.num - 1]
	return value
}

// array_push_back :: proc( using self : Array( $ Type)) -> b32 {
// 	if num == capacity {
// 		return false
// 	}

// 	data[ num ] = value
// 	num        += 1
// 	return true
// }

array_clear :: proc "contextless" ( using self : Array( $ Type ), zero_data : b32 = false ) {
	if zero_data {
		mem.set( data, 0, int(num * size_of(Type)) )
	}
	header.num = 0
}

array_fill :: proc( using self : Array( $ Type ), begin, end : u64, value : Type ) -> b32
{
	if begin < 0 || end >= num {
		return false
	}

	// data_slice := slice_ptr( ptr_offset( data, begin ), end - begin )
	// slice.fill( data_slice, cast(int) value )

	for id := begin; id < end; id += 1 {
		data[ id ] = value
	}
	return true
}

array_free :: proc( using self : Array( $ Type ) ) {
	free( self.header, backing )
	self.data = nil
}

array_grow :: proc( using self : ^Array( $ Type ), min_capacity : u64 ) -> AllocatorError
{
	new_capacity := array_grow_formula( capacity )

	if new_capacity < min_capacity {
		new_capacity = min_capacity
	}
	return array_set_capacity( self, new_capacity )
}

array_pop :: proc( self : Array( $ Type ) ) {
	verify( self.num != 0, "Attempted to pop an array with no elements" )
	self.num -= 1
}

array_remove_at :: proc( using self : Array( $ Type ), id : u64 )
{
	verify( id < header.num, "Attempted to remove from an index larger than the array" )

	left  := & data[id]
	right := & data[id + 1]
	libc.memmove( left, right, uint(num - id) * size_of(Type) )

	header.num -= 1
}

array_reserve :: proc( using self : ^Array( $ Type ), new_capacity : u64 ) -> AllocatorError
{
	if capacity < new_capacity {
		return array_set_capacity( self, new_capacity )
	}
	return AllocatorError.None
}

array_resize :: proc( array : ^Array( $ Type ), num : u64 ) -> AllocatorError
{
	if array.capacity < num
	{
		grow_result := array_grow( array, array.capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	array.num = num
	return AllocatorError.None
}

array_set_capacity :: proc( self : ^Array( $ Type ), new_capacity : u64 ) -> AllocatorError
{
	if new_capacity == self.capacity {
		return AllocatorError.None
	}
	if new_capacity < self.num {
		self.num = new_capacity
		return AllocatorError.None
	}

	header_size :: size_of(ArrayHeader(Type))

	new_size := header_size + (cast(int) new_capacity ) * size_of(Type)
	old_size := header_size + (cast(int) self.capacity) * size_of(Type)

	new_mem, result_code := resize_non_zeroed( self.header, old_size, new_size, mem.DEFAULT_ALIGNMENT, allocator = self.backing )

	if result_code != AllocatorError.None {
		ensure( false, "Failed to allocate for new array capacity" )
		log( "Failed to allocate for new array capacity", level = LogLevel.Warning )
		return result_code
	}
	if new_mem == nil {
		ensure(false, "new_mem is nil but no allocation error")
		return result_code
	}

	self.header          = cast( ^ArrayHeader(Type)) raw_data(new_mem);
	self.header.data     = cast( [^]Type ) (cast( [^]ArrayHeader(Type)) self.header)[ 1:]
	self.header.capacity = new_capacity
	self.header.num      = self.num
	return result_code
}

array_block_size :: proc "contextless" ( self : Array( $Type ) ) -> u64 {
	header_size :: size_of(ArrayHeader(Type))
	block_size  := cast(u64) (header_size + self.capacity * size_of(Type))
	return block_size
}

array_memtracker_entry :: proc( self : Array( $Type ), name : string ) -> MemoryTrackerEntry {
	header_size :: size_of(ArrayHeader(Type))
	block_size  := cast(uintptr) (header_size + (cast(uintptr) self.capacity) * size_of(Type))

	block_start := transmute(^u8) self.header
	block_end   := ptr_offset( block_start, block_size )

	tracker_entry := MemoryTrackerEntry { name, block_start, block_end }
	return tracker_entry
}
