package grime

import "base:runtime"
import "core:container/queue"

// Note(Ed): Fixed size queue DOES NOT act as a RING BUFFER
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
	if len(slice) == 0 do return
	queue.push_back_elems( self, ..slice )

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
	data_size := cast(uint) len(data)

	front_id := (length + offset            ) % data_size
	elem_id  := (length + offset - index -1 ) % data_size
	if elem_id == front_id do return nil

	elem  := & data[ elem_id ]
	index += 1
	return elem
}
