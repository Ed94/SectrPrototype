package grime

import "core:container/queue"

make_queue :: proc( $QueueType : typeid/Queue($Type), capacity := queue.DEFAULT_CAPACITY, allocator := context.allocator, fixed_cap : bool = false ) -> (result : Queue(Type), error : AllocatorError)
{
	allocator := allocator
	if fixed_cap {
		slice_size     := capacity * size_of(Type)
		raw_mem, error := alloc( slice_size, allocator = allocator )
		backing        := slice_ptr( transmute(^Type) raw_mem, capacity )
		queue.init_from_slice( & result, backing )
		return
	}

	queue.init( & result, capacity, allocator )
	return
}

push_back_slice_queue :: proc( self : ^$QueueType / Queue($Type), slice : []Type ) -> ( error : AllocatorError )
{
	num := cast(uint) len(slice)

	if uint( space_left( self^ )) < num {
		error = queue._grow( self, self.len + num )
		if error != .None do return
	}

	size        := uint(len(self.data))
	insert_from := (self.offset + self.len) % size
	insert_to   := num

	if insert_from + insert_to > size {
		insert_to = size - insert_from
	}

	copy( self.data[ insert_from : ], slice[ : insert_to ])
	copy( self.data[ : insert_from ], slice[ insert_to : ])
	return
}

QueueIterator :: struct( $Type : typeid ) {
	data   : []Type,
	length : uint,
	offset : uint,
	index  : uint,
}

iterator_queue :: proc( queue : $QueueType / Queue($Type) ) -> QueueIterator(Type)
{
	iter := QueueIterator(Type) {
		data   = queue.data[:],
		length = queue.len,
		offset = queue.offset,
		index  = 0,
	}
	return iter
}

next_queue_iterator :: proc( iter : ^QueueIterator($Type) ) -> ^Type
{
	using iter
	front_id := (length + offset        ) % len(data)
	elem_id  := (length + offset - index) % len(data)
	if elem_id == front_id do return nil

	elem  := & data[ elem_id ]
	index += 1
	return elem
}
