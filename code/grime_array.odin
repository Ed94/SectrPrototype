// Based on gencpp's and thus zpl's Array implementation
// Made becasue of the map issue with fonts during hot-reload.
// I didn't want to make the HashTable impl with the [dynamic] array for now to isolate
// what in the world is going on with the memory...
package sectr

import "core:c/libc"
import "core:mem"

Array :: struct ( $ Type : typeid ) {
	allocator : Allocator,
	capacity  : u64,
	num       : u64,
	data      : [^]Type,
}

array_to_slice :: proc ( arr : Array( $ Type) ) -> []Type {
	using arr; return slice_ptr( data, num )
}

array_grow_formula :: proc( value : u64 ) -> u64 {
	return 2 * value + 8
}

array_init :: proc( $ Type : typeid, allocator : Allocator ) -> ( Array(Type), AllocatorError ) {
	return array_init_reserve( Type, allocator, array_grow_formula(0) )
}

array_init_reserve :: proc( $ Type : typeid, allocator : Allocator, capacity : u64 ) -> ( Array(Type), AllocatorError )
{
	raw_data, result_code = alloc( capacity * size_of(Type), allocator = allocator )
	result : Array( Type)
	result.data      = cast( [^] Type ) raw_data
	result.allocator = allocator
	result.capacity  = capacity
	return result, result_code
}

array_append :: proc( array : ^ Array( $ Type), value : Type ) -> AllocatorError
{
	using array
	if num == capacity
	{
		grow_result := array_grow( array, capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	data[ num ] = value
	num        += 1
	return AllocatorError.None
}

array_append_slice :: proc( array : ^ Array( $ Type ), items : []Type ) -> AllocatorError
{
	using array
	if num + len(items) > capacity
	{
		grow_result := array_grow( array, capacity )
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

array_append_at :: proc( array : ^ Array( $ Type ), item : Type, id : u64 ) -> AllocatorError
{
	id := id
	using array

	if id >= num {
		id = num - 1
	}
	if id < 0 {
		id = 0
	}

	if capacity < num + 1
	{
		grow_result := array_grow( array, capacity )
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

array_append_at_slice :: proc ( array : ^ Array( $ Type ), items : []Type, id : u64 ) -> AllocatorError
{
	id := id
	using array

	if id >= num {
		return array_append_slice( items )
	}
	if len(items) > capacity
	{
		grow_result := array_grow( array, capacity )
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

array_back :: proc( array : ^ Array( $ Type ) ) -> ^ Type {
	using array; return & data[ num - 1 ]
}

array_clear :: proc ( array : ^ Array( $ Type ) ) {
	array.num = 0
}

array_fill :: proc ( array : ^ Array( $ Type ), begin, end : u64, value : Type ) -> b32
{
	using array

	if begin < 0 || end >= num {
		return false
	}

	for id := begin; id < end; id += 1 {
		data[ id ] = value
	}
	return true
}

array_free :: proc( array : ^ Array( $ Type ) ) {
	using array
	free( data, allocator )
	data = nil
}

array_grow :: proc( array : ^ Array( $ Type ), min_capacity : u64 ) -> AllocatorError
{
	using array
	new_capacity = grow_formula( capacity )

	if new_capacity < min_capacity {
		new_capacity = min_capacity
	}

	return array_set_capacity( array, new_capacity )
}

array_pop :: proc( array : ^ Array( $ Type ) ) {
	verify( array.num == 0, "Attempted to pop an array with no elements" )
	array.num -= 1
}

array_remove_at :: proc( array : ^ Array( $ Type ), id : u64 )
{
	using array
	verify( id >= num, "Attempted to remove from an index larger than the array" )

	left  = slice_ptr( data, id )
	right = slice_ptr( ptr_offset( memory_after(left), 1), num - len(left) - 1 )
	copy( left, right )

	num -= 1
}

array_reserve :: proc( array : ^ Array( $ Type ), new_capacity : u64 ) -> AllocatorError
{
	using array
	if capacity < new_capacity {
		return array_set_capacity( array, new_capacity )
	}
	return AllocatorError.None
}

array_resize :: proc ( array : ^ Array( $ Type ), num : u64 ) -> AllocatorError
{
	if array.capacity < num
	{
		grow_result := array_grow( array, capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	array.num = num
	return AllocatorError.None
}

array_set_capacity :: proc( array : ^ Array( $ Type ), new_capacity : u64 ) -> AllocatorError
{
	using array
	if new_capacity == capacity {
		return true
	}
	if new_capacity < num {
		num = new_capacity
		return true
	}

	raw_data, result_code = alloc( new_capacity * size_of(Type), allocator = allocator )
	data     = cast( [^] Type ) raw_data
	capacity = new_capacity
	return result_code
}
