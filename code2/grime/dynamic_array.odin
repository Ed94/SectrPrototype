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

ArrayHeader :: struct ($Type: typeid) {
	backing:   Odin_Allocator,
	dbg_name:  string,
	fixed_cap: b64,
	capacity:  int,
	num:       int,
	data:      [^]Type,
}
Array :: struct ($Type: typeid) {
	using header: ^ArrayHeader(Type),
}

array_underlying_slice :: proc(s: []($ Type)) -> Array(Type) {
	assert(len(slice) != 0)
	header_size :: size_of( ArrayHeader(Type))
	array       := cursor(to_bytes(s))[ - header_size]
	return 
}
array_to_slice          :: #force_inline proc "contextless" ( using self : Array($ Type) ) -> []Type { return slice( data, int(num))      }
array_to_slice_capacity :: #force_inline proc "contextless" ( using self : Array($ Type) ) -> []Type { return slice( data, int(capacity)) }

array_grow_formula :: #force_inline proc "contextless" (value: int) -> int { return (2 * value) + 8 }

//region Lifetime & Memory Resize Operations

array_init :: proc( $Array_Type : typeid / Array($Type), capacity: int,
	allocator := context.allocator, fixed_cap: b64 = false, dbg_name: string = ""
) -> (result: Array(Type), alloc_error: AllocatorError)
{
	header_size := size_of(ArrayHeader(Type))
	array_size  := header_size + int(capacity) * size_of(Type)

	raw_mem: []byte
	raw_mem, alloc_error = mem_alloc(array_size, ainfo = allocator)
	// log( str_fmt_tmp("array reserved: %d", header_size + int(capacity) * size_of(Type) ))
	if alloc_error != AllocatorError.None do return

	result.header    = cast( ^ArrayHeader(Type)) cursor(raw_mem)
	result.backing   = allocator
	result.dbg_name  = dbg_name
	result.fixed_cap = fixed_cap
	result.capacity  = capacity
	result.data      = cast( [^]Type ) (cast( [^]ArrayHeader(Type)) result.header)[ 1:]
	return
}
array_free :: proc(self: Array($Type)) {
	free(self.header, backing)
	self.data = nil
}
array_grow :: proc(self: ^Array($Type), min_capacity: int) -> AllocatorError {
	new_capacity := array_grow_formula(self.capacity)
	if new_capacity < min_capacity do new_capacity = min_capacity
	return array_set_capacity( self, new_capacity )
}
array_resize :: proc(self: ^Array($Type), num: int) -> AllocatorError {
	if array.capacity < num {
		grow_result := array_grow( array, array.capacity )
		if grow_result != AllocatorError.None do return grow_result
	}
	array.num = num
	return AllocatorError.None
}
array_set_capacity :: proc( self : ^Array( $ Type ), new_capacity: int) -> AllocatorError
{
	if new_capacity == self.capacity do return AllocatorError.None
	if new_capacity < self.num       { self.num = new_capacity; return AllocatorError.None }
	header_size :: size_of(ArrayHeader(Type))
	new_size := header_size + new_capacity  * size_of(Type)
	old_size := header_size + self.capacity * size_of(Type)
	// TODO(Ed): You were here..
	new_mem, result_code := resize_non_zeroed( self.header, old_size, new_size, mem.DEFAULT_ALIGNMENT, allocator = self.backing )
	if result_code != AllocatorError.None {
		ensure( false, "Failed to allocate for new array capacity" )
		log_print( "Failed to allocate for new array capacity", level = LogLevel.Warning )
		return result_code
	}
	if new_mem == nil { ensure(false, "new_mem is nil but no allocation error"); return result_code }
	self.header          = cast( ^ArrayHeader(Type)) raw_data(new_mem);
	self.header.data     = cast( [^]Type ) (cast( [^]ArrayHeader(Type)) self.header)[ 1:]
	self.header.capacity = new_capacity
	self.header.num      = self.num
	return result_code
}

//endregion Lifetime & Memory Resize Operations

// Assumes non-overlapping memory for items and appendee
array_append_array :: proc(self: ^Array($Type), other : Array(Type)) -> AllocatorError {
	if self.num + other.num > self.capacity {
		grow_result := array_grow( self, self.num + other.num )
		if grow_result != AllocatorError.None do return grow_result
	}
	copy_non_overlaping(self.data[self.num:], other.data, other.num)
	num += other.num
	return AllocatorError.None
}
// Assume non-overlapping memory for items and appendee
array_append_slice :: proc(self : ^Array($Type), items: []Type) -> AllocatorError {
	// items_num := u64(len(items))
	if num + len(items) > capacity {
		grow_result := array_grow(self, num + len(items))
		if grow_result != AllocatorError.None do return grow_result
	}
	copy_non_overlaping(self.data[self.num:], cursor(items), len(items))
	num += items_num
	return AllocatorError.None
}
array_append_value :: proc(self: ^Array($Type), value: Type) -> AllocatorError {
	if self.header.num == self.header.capacity {
		grow_result := array_grow( self, self.header.capacity )
		if grow_result != AllocatorError.None do return grow_result
	}
	self.header.data[ self.header.num ] = value
	self.header.num += 1
	return AllocatorError.None
}
array_append_at_value :: proc(self : ^Array($Type), item: Type, id: int) -> AllocatorError {
	ensure(id < self.num, "Why are we doing an append at beyond the bounds of the current element count")
	id := id; {
		// TODO(Ed): Not sure I want this...
		if id >= self.num do id = self.num
		if id <  0        do id = 0
	}
	if self.capacity < self.num + 1 {
		grow_result := array_grow( self, self.capacity )
		if grow_result != AllocatorError.None do return grow_result
	}
	// libc.memmove( ptr_offset(target, 1), target, uint(num - id) * size_of(Type) )
	copy(self.data[id + 1:], self.data[id], uint(self.num - id) * size_of(Type))
	self.data[id] = item
	self.num     += 1
	return AllocatorError.None
}

// Asumes non-overlapping for items.
array_append_at_slice :: proc(self : ^Array($Type ), items: []Type, id: int) -> AllocatorError {
	ensure(id < self.num, "Why are we doing an append at beyond the bounds of the current element count")
	id := id
	if id >= self.num { return array_append_slice(items) }
	if len(items) > self.capacity {
		grow_result := array_grow( self, self.capacity )
		if grow_result != AllocatorError.None do return grow_result
	}
	// TODO(Ed) : VERIFY VIA DEBUG THIS COPY IS FINE
	ensure(false, "time to check....")
	mem_copy               (self.data[id + len(items):], self.data[id:], (self.num - id) * size_of(Type))
	mem_copy_non_overlaping(self.data[id:],              cursor(items),  len(items)      * size_of(Type) )
	self.num += len(items)
	return AllocatorError.None
}

array_back :: #force_inline proc "contextless" ( self : Array($Type) ) -> Type { assert(self.num > 0); return self.data[self.num - 1] }

array_clear :: #force_inline proc "contextless" (self: Array($Type), zero_data: b32 = false) {
	if zero_data do zero(self.data, int(self.num) * size_of(Type))
	self.num = 0
}

array_fill :: proc(self: Array($Type), begin, end: u64, value: Type) -> b32 {
	ensure(end - begin <= num)
	ensure(end         <= num)
	if (end - begin > num) || (end > num) do return false
	mem_fill(data[begin:], value, end - begin)
	return true
}

// Will push  value into the array (will not grow if at capacity, use append instead for when that matters)
array_push_back :: #force_inline proc "contextless" (self: Array($Type)) -> b32 {
	if self.num == self.capacity { return false }
	self.data[self.num] = value
	self.num           += 1
	return true
}

array_remove_at :: proc(self: Array($Type), id: int) {
	verify( id < header.num, "Attempted to remove from an index larger than the array" )
	mem_copy(self.data[id], self.data[id + 1], (self.num - id) * size_of(Type))
	self.num -= 1
}
