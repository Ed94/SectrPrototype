// This is an alternative to Odin's default map type.
// The only reason I may need this is due to issues with allocator callbacks or something else going on
// with hot-reloads...
package sectr

import "core:slice"


// Note(Ed) : See core:hash for hasing procs.

// This might be problematic...
HT_MapProc    :: #type proc( $ Type : typeid, key : u64, value :   Type )
HT_MapMutProc :: #type proc( $ Type : typeid, key : u64, value : ^ Type )

HT_FindResult :: struct {
	hash_index  : i64,
	prev_index  : i64,
	entry_index : i64,
}

HashTable_Entry :: struct ( $ Type : typeid) {
	key   : u64,
	next  : i64,
	value : Type,
}

HashTable :: struct ( $ Type : typeid ) {
	hashes  : Array( i64 ),
	entries : Array( HashTable_Entry(Type) ),
}

hashtable_init :: proc( $ Type : typeid, allocator : Allocator ) -> ( HashTable( Type), AllocatorError ) {
	return hashtable_init_reserve( Type, allocator )
}

hashtable_init_reserve :: proc( $ Type : typeid, allocator : Allocator, num : u64 ) -> ( HashTable( Type), AllocatorError )
{
	result                        : HashTable(Type)
	hashes_result, entries_result : AllocatorError

	result.hashes, hashes_result = array_init_reserve( i64, allocator, num )
	if hashes_result != AllocatorError.None {
		ensure( false, "Failed to allocate hashes array" )
		return result, hashes_result
	}
	array_resize( & result.hashes, num )
	slice.fill( slice_ptr( result.hashes.data, cast(int) result.hashes.num), -1 )

	result.entries, entries_result = array_init_reserve( HashTable_Entry(Type), allocator, num )
	if entries_result != AllocatorError.None {
		ensure( false, "Failed to allocate entries array" )
		return result, entries_result
	}
	return result, AllocatorError.None
}

hashtable_clear :: proc( ht : ^ HashTable( $ Type ) ) {
	using ht
	for id := 0; id < hashes.num; id += 1 {
		hashes[id] = -1
	}

	array_clear( hashes )
	array_clear( entries )
}

hashtable_destroy :: proc( using ht : ^ HashTable( $ Type ) ) {
	if hashes.data != nil && hashes.capacity > 0 {
		array_free( & hashes )
		array_free( & entries )
	}
}

hashtable_get :: proc( ht : ^ HashTable( $ Type ), key : u64 ) -> ^ Type
{
	using ht

	id := hashtable_find( ht, key ).entry_index
	if id >= 0 {
		return & entries.data[id].value
	}

	return nil
}

hashtable_map :: proc( ht : ^ HashTable( $ Type), map_proc : HT_MapProc ) {
	using ht
	ensure( map_proc != nil, "Mapping procedure must not be null" )
	for id := 0; id < entries.num; id += 1 {
		map_proc( Type, entries[id].key, entries[id].value )
	}
}

hashtable_map_mut :: proc( ht : ^ HashTable( $ Type), map_proc : HT_MapMutProc ) {
	using ht
	ensure( map_proc != nil, "Mapping procedure must not be null" )
	for id := 0; id < entries.num; id += 1 {
		map_proc( Type, entries[id].key, & entries[id].value )
	}
}

hashtable_grow :: proc( ht : ^ HashTable( $ Type ) ) -> AllocatorError {
	using ht
	new_num := array_grow_formula( entries.num )
	return hashtable_rehash( ht, new_num )
}

hashtable_rehash :: proc( ht : ^ HashTable( $ Type ), new_num : u64 ) -> AllocatorError
{
	last_added_index : i64

	new_ht, init_result := hashtable_init_reserve( Type, ht.hashes.allocator, new_num )
	if init_result != AllocatorError.None {
		ensure( false, "New hashtable failed to allocate" )
		return init_result
	}

	for id : u64 = 0; id < ht.entries.num; id += 1 {
		find_result : HT_FindResult

		entry           := & ht.entries.data[id]
		find_result      = hashtable_find( & new_ht, entry.key )
		last_added_index = hashtable_add_entry( & new_ht, entry.key )

		if find_result.prev_index < 0 {
			new_ht.hashes.data[ find_result.hash_index ] = last_added_index
		}
		else {
			new_ht.entries.data[ find_result.prev_index ].next = last_added_index
		}

		new_ht.entries.data[ last_added_index ].next  = find_result.entry_index
		new_ht.entries.data[ last_added_index ].value = entry.value
	}

	hashtable_destroy( ht )

	(ht ^) = new_ht
	return AllocatorError.None
}

hashtable_rehash_fast :: proc( ht : ^ HashTable( $ Type ) )
{
	using ht
	for id := 0; id < entries.num; id += 1 {
		entries[id].Next = -1;
	}
	for id := 0; id < hashes.num; id += 1 {
		hashes[id] = -1
	}
	for id := 0; id < entries.num; id += 1 {
		entry       := & entries[id]
		find_result := hashtable_find( entry.key )

		if find_result.prev_index < 0 {
			hashes[ find_result.hash_index ] = id
		}
		else {
			entries[ find_result.prev_index ].next = id
		}
	}
}

hashtable_remove :: proc( ht : ^ HashTable( $ Type ), key : u64 ) {
	using ht
	find_result := hashtable_find( key )

	if find_result.entry_index >= 0 {
		array_remove_at( & ht.entries, find_result.entry_index )
		hashtable_rehash_fast( ht )
	}
}

hashtable_remove_entry :: proc( ht : ^ HashTable( $ Type ), id : i64 ) {
	array_remove_at( & ht.entries, id )
}

hashtable_set :: proc( ht : ^ HashTable( $ Type), key : u64, value : Type ) -> (^ Type, AllocatorError)
{
	using ht

	id          : i64 = 0
	find_result : HT_FindResult

	if hashtable_full( ht )
	{
		grow_result := hashtable_grow(ht)
		if grow_result != AllocatorError.None {
				return nil, grow_result
		}
	}

	find_result = hashtable_find( ht, key )
	if find_result.entry_index >= 0 {
		id = find_result.entry_index
	}
	else
	{
		id = hashtable_add_entry( ht, key )
		if find_result.prev_index >= 0 {
			entries.data[ find_result.prev_index ].next = id
		}
		else {
			hashes.data[ find_result.hash_index ] = id
		}
	}

	entries.data[id].value = value

	if hashtable_full( ht ) {
		return & entries.data[id].value, hashtable_grow( ht )
	}

	return & entries.data[id].value, AllocatorError.None
}

hashtable_slot :: proc( ht : ^ HashTable( $ Type), key : u64 ) -> i64 {
	using ht
	for id : i64 = 0; id < hashes.num; id += 1 {
		if hashes.data[id] == key                {
			return id
		}
	}
	return -1
}

hashtable_add_entry :: proc( ht : ^ HashTable( $ Type), key : u64 ) -> i64 {
	using ht
	entry : HashTable_Entry(Type) = { key, -1, {} }
	id    := cast(i64) entries.num
	array_append( & entries, entry )
	return id
}

hashtable_find :: proc( ht : ^ HashTable( $ Type), key : u64 ) -> HT_FindResult
{
	using ht
	result : HT_FindResult = { -1, -1, -1 }

	if hashes.num > 0 {
		result.hash_index  = cast(i64)( key % hashes.num )
		result.entry_index = hashes.data[ result.hash_index ]

		for ; result.entry_index >= 0;                     {
			if entries.data[ result.entry_index ].key == key {
				break
			}

			result.prev_index  = result.entry_index
			result.entry_index = entries.data[ result.entry_index ].next
		}
	}
	return result
}

hashtable_full :: proc( using ht : ^ HashTable( $ Type) ) -> b32 {
	result : b32 = entries.num > u64(0.75 * cast(f64) hashes.num)
	return result
}
