package grime

RingBufferFixed :: struct( $Type: typeid, $Size: u32 ) {
    head  : u32,
    tail  : u32,
    num   : u32,
    items : [Size] Type,
}

ringbuf_fixed_clear :: #force_inline proc "contextless" ( using buffer : ^RingBufferFixed( $Type, $Size)) {
    head = 0
    tail = 0
    num  = 0
}

ringbuf_fixed_is_full :: #force_inline proc "contextless" ( using buffer : RingBufferFixed( $Type, $Size)) -> bool {
	return num == Size
}

ringbuf_fixed_is_empty :: #force_inline proc "contextless" ( using buffer : RingBufferFixed( $Type, $Size)) -> bool {
	return num == 0
}

ringbuf_fixed_peek_front_ref :: #force_inline proc "contextless" ( using buffer : ^RingBufferFixed( $Type, $Size)) -> ^Type {
	assert(num > 0, "Attempted to peek an empty ring buffer")
	return & items[ head ]
}

ringbuf_fixed_peek_front :: #force_inline proc "contextless" ( using buffer : RingBufferFixed( $Type, $Size)) -> Type {
	assert(num > 0, "Attempted to peek an empty ring buffer")
	return items[ head ]
}

ringbuf_fixed_peak_back :: #force_inline proc ( using buffer : RingBufferFixed( $Type, $Size)) -> Type {
	assert(num > 0, "Attempted to peek an empty ring buffer")

	buf_size := u32(Size)
	index    := (tail - 1 + buf_size) % buf_size
	return items[ index ]
}

ringbuf_fixed_push :: #force_inline proc(using buffer: ^RingBufferFixed($Type, $Size), value: Type) {
	if num == Size do head = (head + 1) % Size
	else           do num += 1

	items[ tail ] = value
	tail          = (tail + 1) % Size
}

ringbuf_fixed_push_slice :: proc(buffer: ^RingBufferFixed($Type, $Size), slice: []Type) -> u32
{
	size       := u32(Size)
	slice_size := u32(len(slice))

	// assert( slice_size <= size, "Attempting to append a slice that is larger than the ring buffer!" )
	if slice_size == 0 do return 0

	items_to_add := min( slice_size, size)
	items_added  : u32 = 0

	if items_to_add > Size - buffer.num
	{
			// Some or all existing items will be overwritten
			overwrite_count := items_to_add - (Size - buffer.num)
			buffer.head      = (buffer.head + overwrite_count) % size
			buffer.num       = size
	}
	else
	{
			buffer.num += items_to_add
	}

	if items_to_add <= size
	{
			// Case 1: Slice fits entirely or partially in the buffer
			space_to_end := size - buffer.tail
			first_chunk  := min(items_to_add, space_to_end)

			// First copy: from tail to end of buffer
			copy( buffer.items[ buffer.tail: ] , slice[ :first_chunk ] )

			if first_chunk < items_to_add {
					// Second copy: wrap around to start of buffer
					second_chunk := items_to_add - first_chunk
					copy( buffer.items[:], slice[ first_chunk : items_to_add ] )
			}

			buffer.tail = (buffer.tail + items_to_add) % Size
			items_added = items_to_add
	}
	else
	{
			// Case 2: Slice is larger than buffer, only keep last Size elements
			to_add := slice[ slice_size - size: ]

			// First copy: from start of buffer to end
			first_chunk := min(Size, u32(len(to_add)))
			copy( buffer.items[:], to_add[ :first_chunk ] )

			if first_chunk < Size
			{
					// Second copy: wrap around
					copy( buffer.items[ first_chunk: ], to_add[ first_chunk: ] )
			}

			buffer.head = 0
			buffer.tail = 0
			buffer.num  = Size
			items_added = Size
	}

	return items_added
}

ringbuf_fixed_pop :: #force_inline proc "contextless" ( using buffer : ^RingBufferFixed( $Type, $Size )) -> Type {
    assert(num > 0, "Attempted to pop an empty ring buffer")
    value := items[ head ]
    head   = ( head + 1 ) % Size
    num -= 1
    return value
}

RingBufferFixedIterator :: struct( $Type : typeid) {
	items     : []Type,
	head      : u32,
	tail      : u32,
	index     : u32,
	remaining : u32,
}

iterator_ringbuf_fixed :: proc(buffer: ^RingBufferFixed($Type, $Size)) -> RingBufferFixedIterator(Type)
{
	iter := RingBufferFixedIterator(Type){
		items     = buffer.items[:],
		head      = buffer.head,
		tail      = buffer.tail,
		remaining = buffer.num,
	}

	buff_size := u32(Size)

	if buffer.num > 0 {
			// Start from the last pushed item (one before tail)
			iter.index = (buffer.tail - 1 + buff_size) % buff_size
	} else {
			iter.index = buffer.tail  // This will not be used as remaining is 0
	}

	return iter
}

next_ringbuf_fixed_iterator :: proc(iter : ^RingBufferFixedIterator( $Type)) -> ^Type
{
    using iter
    if remaining == 0 {
        return nil  // If there are no items left to iterate over
    }

		buf_size := cast(u32) len(items)

    result := &items[index]

    // Decrement index and wrap around if necessary
    index = (index - 1 + buf_size) % buf_size

    remaining -= 1
    return result
}
