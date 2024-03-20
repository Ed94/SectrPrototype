// Based on gencpp's and thus zpl's Array implementation
// Made becasue of the map issue with fonts during hot-reload.
// I didn't want to make the HMapZPL impl with the [dynamic] array for now to isolate
package sectr

import "core:c/libc"
import "core:mem"
import "core:slice"

// Array :: struct ( $ Type : typeid ) {
// 	bakcing : Allocator,
// 	capacity  : u64,
// 	num       : u64,
// 	data      : [^]Type,
// }

ArrayHeader :: struct ( $ Type : typeid ) {
	backing   : Allocator,
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
			return nil
	}
	array_size := size_of( Array(Type))
	raw_data   := & slice[0]
	array_ptr  := cast( ^Array(Type)) ( uintptr(first_element_ptr) - uintptr(array_size))
	return array_ptr ^
}

array_to_slice_num :: proc( using self : Array($ Type) ) -> []Type {
	return slice_ptr( data, int(num) )
}

array_to_slice :: proc( using self : Array($ Type) ) -> []Type {
	return slice_ptr( data, int(capacity))
}

array_grow_formula :: proc( value : u64 ) -> u64 {
	return 2 * value + 8
}

array_init :: proc( $ Type : typeid, allocator : Allocator ) -> ( Array(Type), AllocatorError ) {
	return array_init_reserve( Type, allocator, array_grow_formula(0) )
}

array_init_reserve :: proc
( $ Type : typeid, allocator : Allocator, capacity : u64 ) -> ( result : Array(Type), alloc_error : AllocatorError )
{
	header_size := size_of(ArrayHeader(Type))
	array_size  := header_size + int(capacity) * size_of(Type)

	raw_mem : rawptr
	raw_mem, alloc_error = alloc( array_size, allocator = allocator )
	log( str_fmt_tmp("array reserved: %d", header_size + int(capacity) * size_of(Type) ))
	if alloc_error != AllocatorError.None do return

	result.header    = cast( ^ArrayHeader(Type)) raw_mem;
	result.backing   = allocator
	result.capacity  = capacity
	result.data      = cast( [^]Type ) (cast( [^]ArrayHeader(Type)) result.header)[ 1:]
	return
}

array_append :: proc( self : ^Array( $ Type), value : Type ) -> AllocatorError
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

array_append_slice :: proc( using self : ^Array( $ Type ), items : []Type ) -> AllocatorError
{
	if num + len(items) > capacity
	{
		grow_result := array_grow( self, capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	// Note(Ed) : Original code from gencpp
	// libc.memcpy( ptr_offset(data, num), raw_data(items), len(items) * size_of(Type) )

	// TODO(Ed) : VERIFY VIA DEBUG THIS COPY IS FINE.
	target := ptr_offset( data, num )
	copy( slice_ptr(target, capacity - num), items )

	num += len(items)
	return AllocatorError.None
}

array_append_at :: proc( using self : ^Array( $ Type ), item : Type, id : u64 ) -> AllocatorError
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

	// TODO(Ed) : VERIFY VIA DEBUG THIS COPY IS FINE.
	dst = slice_ptr( ptr_offset(target) + 1, num - id - 1 )
	src = slice_ptr( target, num - id )
	copy( dst, src )

	// Note(Ed) : Original code from gencpp
	// libc.memmove( ptr_offset(target, 1), target, (num - idx) * size_of(Type) )
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
	target := & data[id + len(items)]
	dst    := slice_ptr( target, num - id - len(items) )
	src    := slice_ptr( & data[id], num - id )
	copy( dst, src )
	copy( src, items )

	num += len(items)
	return AllocatorError.None
}

array_push_back :: proc( using self : Array( $ Type)) -> b32 {
	if num == capacity {
		return false
	}

	data[ num ] = value
	num        += 1
	return true
}

array_clear :: proc( using self : Array( $ Type ), zero_data : b32 ) {
	if zero_data {
		mem.set( raw_data( data ), 0, num )
	}
	num = 0
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
	free( data, backing )
	self.data = nil
}

array_grow :: proc( using self : ^Array( $ Type ), min_capacity : u64 ) -> AllocatorError
{
	// profile(#procedure)
	new_capacity := array_grow_formula( capacity )

	if new_capacity < min_capacity {
		new_capacity = min_capacity
	}
	return array_set_capacity( self, new_capacity )
}

array_pop :: proc( using self : Array( $ Type ) ) {
	verify( num != 0, "Attempted to pop an array with no elements" )
	num -= 1
}

array_remove_at :: proc( using self : Array( $ Type ), id : u64 )
{
	verify( id >= num, "Attempted to remove from an index larger than the array" )

	left  = slice_ptr( data, id )
	right = slice_ptr( ptr_offset( memory_after(left), 1), num - len(left) - 1 )
	copy( left, right )

	num -= 1
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

	// new_mem, result_code := resize( self.header, old_size, new_size, allocator = self.backing )
	new_mem, result_code := resize_non_zeroed( self.header, old_size, new_size, mem.DEFAULT_ALIGNMENT, allocator = self.backing )

	if result_code != AllocatorError.None {
		ensure( false, "Failed to allocate for new array capacity" )
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
