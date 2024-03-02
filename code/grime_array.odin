// Based on gencpp's and thus zpl's Array implementation
// Made becasue of the map issue with fonts during hot-reload.
// I didn't want to make the HMapZPL impl with the [dynamic] array for now to isolate
// what in the world is going on with the memory...
package sectr

import "core:c/libc"
import "core:mem"
import "core:slice"

Array :: struct ( $ Type : typeid ) {
	allocator : Allocator,
	capacity  : u64,
	num       : u64,
	data      : [^]Type,
}

array_underlying_slice :: proc(slice: []($ Type)) -> Array(Type) {
	if len(slice) == 0 {
			return nil
	}
	array_size := size_of( Array(Type))
	raw_data   := & slice[0]
	array_ptr  := cast( ^Array(Type)) ( uintptr(first_element_ptr) - uintptr(array_size))
	return array_ptr ^
}

array_to_slice :: proc( using self : Array($ Type) ) -> []Type {
	return slice_ptr( data, int(num) )
}

array_grow_formula :: proc( value : u64 ) -> u64 {
	return 2 * value + 8
}

array_init :: proc( $ Type : typeid, allocator : Allocator ) -> ( Array(Type), AllocatorError ) {
	return array_init_reserve( Type, allocator, array_grow_formula(0) )
}

array_init_reserve :: proc( $ Type : typeid, allocator : Allocator, capacity : u64 ) -> ( Array(Type), AllocatorError )
{
	raw_data, result_code := alloc( size_of(Array) + int(capacity) * size_of(Type), allocator = allocator )
	result          := cast(^Array(Type)) raw_data;
	result.data      = cast( [^]Type ) ptr_offset( result, 1 )
	result.allocator = allocator
	result.capacity  = capacity
	return (result ^), result_code
}

array_append :: proc( using self : ^ Array( $ Type), value : Type ) -> AllocatorError
{
	if num == capacity
	{
		grow_result := array_grow( self, capacity )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	data[ num ] = value
	num        += 1
	return AllocatorError.None
}

array_append_slice :: proc( using self : ^ Array( $ Type ), items : []Type ) -> AllocatorError
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

array_append_at :: proc( using self : ^ Array( $ Type ), item : Type, id : u64 ) -> AllocatorError
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

array_append_at_slice :: proc( using self : ^ Array( $ Type ), items : []Type, id : u64 ) -> AllocatorError
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

array_back :: proc( using self : ^ Array( $ Type ) ) -> ^ Type {
	return & data[ num - 1 ]
}

array_clear :: proc( using self : ^ Array( $ Type ), zero_data : b32 ) {
	if zero_data {
		mem.set( raw_data( data ), 0, num )
	}
	num = 0
}

array_fill :: proc( using self : ^ Array( $ Type ), begin, end : u64, value : Type ) -> b32
{
	if begin < 0 || end >= num {
		return false
	}

	// TODO(Ed) : Bench this?
	// data_slice := slice_ptr( ptr_offset( data, begin ), end - begin )
	// slice.fill( data_slice, cast(int) value )

	for id := begin; id < end; id += 1 {
		data[ id ] = value
	}
	return true
}

array_free :: proc( using self : ^ Array( $ Type ) ) {
	free( data, allocator )
	data = nil
}

array_grow :: proc( using self : ^ Array( $ Type ), min_capacity : u64 ) -> AllocatorError
{
	new_capacity := array_grow_formula( capacity )

	if new_capacity < min_capacity {
		new_capacity = min_capacity
	}
	return array_set_capacity( self, new_capacity )
}

array_pop :: proc( using self : ^ Array( $ Type ) ) {
	verify( num != 0, "Attempted to pop an array with no elements" )
	num -= 1
}

array_remove_at :: proc( using self : ^ Array( $ Type ), id : u64 )
{
	verify( id >= num, "Attempted to remove from an index larger than the array" )

	left  = slice_ptr( data, id )
	right = slice_ptr( ptr_offset( memory_after(left), 1), num - len(left) - 1 )
	copy( left, right )

	num -= 1
}

array_reserve :: proc( using self : ^ Array( $ Type ), new_capacity : u64 ) -> AllocatorError
{
	if capacity < new_capacity {
		return array_set_capacity( self, new_capacity )
	}
	return AllocatorError.None
}

array_resize :: proc( array : ^ Array( $ Type ), num : u64 ) -> AllocatorError
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

array_set_capacity :: proc( using self : ^ Array( $ Type ), new_capacity : u64 ) -> AllocatorError
{
	if new_capacity == capacity {
		return AllocatorError.None
	}
	if new_capacity < num {
		num = new_capacity
		return AllocatorError.None
	}

	new_data, result_code := alloc( cast(int) new_capacity * size_of(Type), allocator = allocator )
	if result_code != AllocatorError.None {
		ensure( false, "Failed to allocate for new array capacity" )
		return result_code
	}
	free( data )
	data     = cast( [^] Type ) new_data
	capacity = new_capacity
	return result_code
}
