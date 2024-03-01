// This was an attempt to learn Ryan's hash table implementation used with the UI module of the RAD Debugger.
// Its not completed
package sectr

HMapRJF :: struct ( $ Type : typeid ) {
	slots      : Array ( DLL_NodeFL( Type ) ),
	size       : u64,
	first_free : ^ Type,
}

rjf_hmap_init :: proc( $ Type : typeid, allocator : Allocator, size : u64 ) -> ( HMapRJF( Type ), AllocatorError ) {
	result      : HMapRJF( Type )
	alloc_error : AllocatorError

	result.slots, alloc_error := array_init_reserve( Type, allocator, size )
	if alloc_error != AllocatorError.None {
		ensure( false, "Failed to allocate slots array" )
		return result, alloc_error
	}
	array_resize( & result.slots, size )

	return result, AllocatorError.None
}

rjf_hmap_slot_index :: #force_inline proc ( using self : HMapRJF( $ Type ), key : u64 ) -> u64 {
	return key % size
}

rjf_hmap_get_slot :: #force_inline proc ( using self : HMapRJF ( $ Type ), key : u64 ) -> ^ DLL_NodeFL ( Type ) {
	slot_index := key % size
	return & slots[ slot_index ]
}

rjf_hmap_insert :: proc ( using self : HMapRJF ( $ Type ), key : u64, value : ^ Type ) {
	slot_index := key % size
	slot := & slots[ slot_index ]

	dll_insert_raw( nil, slot.first, slot.last, slot.last, value )
}
