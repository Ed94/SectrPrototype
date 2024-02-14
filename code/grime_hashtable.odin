// This is an alternative to Odin's default map type.
// The only reason I may need this is due to issues with allocator callbacks or something else going on
// with hot-reloads...
package sectr

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
	next  : u64,
	value : Type,
}

HashTable :: struct ( $ Type : typeid) {
	hashes  : Array( i64 ),
	entries : Array( HashTable_Entry(Type) ),
}

hashtable_init :: proc( $ Type : typeid, allocator : Allocator ) -> ( HashTable( Type), AllocatorError ) {
	return hashtable_init_reserve( Type, allocator )
}

hashtable_init_reserve :: proc ( $ Type : typeid, allcoator : Allocator, num : u64 ) -> ( HashTable( Type), AllocatorError )
{
	result                        : HashTable(Type)
	hashes_result, entries_result : AllocatorError

	result.hashes, hashes_result = array_init_reserve( i64, allocator, num )
	if hashes_result != AllocatorError.None {
		ensure( false, "Failed to allocate hashes array" )
		return result, hashes_result
	}

	result.entries, entries_result = array_init_reserve( allocator, num )
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

hashtable_destroy :: proc( ht : ^ HashTable( $ Type ) ) {
	if hashes.data && hashes.capacity {
		array_free( hashes )
		array_free( entries )
	}
}

hashtable_get :: proc( ht : ^ HashTable( $ Type ), key : u64 ) -> ^ Type
{
	using ht

	id := hashtable_find( key ).entry_index
	if id >= 0 {
		return & entries[id].value
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
	new_num := array_grow_formula( entries.num )
	return rehash( ht, new_num )
}

hashtable_rehash :: proc ( ht : ^ HashTabe( $ Type ), new_num : i64 ) -> AllocatorError
{
	last_added_index : i64

	new_ht, init_result := hashtable_init_reserve( Type, ht.hashes.allocator, new_num )
	if init_result != AllocatorError.None {
		ensure( false, "New hashtable failed to allocate" )
		return init_result
	}

	for id := 0; id < new_ht.hashes.num; id += 1 {
		new_ht.hashes[id] = -1
	}

	for id := 0; id < ht.entries.num; id += 1 {
		find_result : HT_FindResult

		if new_ht.hashes.num == 0 {
			hashtable_grow( new_ht )
		}

		entry            = & entries[id]
		find_result      = hashtable_find( & new_ht, entry.key )
		last_added_index = hashtable_add_entry( & new_ht, entry.key )

		if find_result.prev_index < 0 {
			new_ht.hashes[ find_result.hash_index ] = last_added_index
		}
		else {
			new_ht.hashes[ find_result.prev_index ].next = last_added_index
		}

		new_ht.entries[ last_added_index ].next  = find_result.entry_index
		new_ht.entries[ last_added_index ].value = entry.value
	}

	hashtable_destroy( ht )

	(ht ^) = new_ht
	return AllocatorError.None
}

hashtable_rehash_fast :: proc ( ht : ^ HashTable( $ Type ) )
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

hashtable_remove :: proc ( ht : ^ HashTable( $ Type ), key : u64 ) {
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

hashtable_set :: proc( ht : ^ HashTable( $ Type), key : u64, value : Type ) -> AllocatorError
{
	using ht

	id          := 0
	find_result : HT_FindResult

	if hashes.num == 0
	{
		grow_result := hashtable_grow( ht )
		if grow_result != AllocatorError.None {
			return grow_result
		}
	}

	find_result = hashtable_find( key )
	if find_result.entry_index >= 0 {
		id = find_result.entry_index
	}
	else
	{
		id = hashtable_add_entry( ht, key )
		if find_result.prev_index >= 0 {
			entries[ find_result.prev_index ].next = id
		}
		else {
			hashes[ find_result.hash_index ] = id
		}
	}

	entries[id].value = value

	if hashtable_full( ht ) {
		return hashtable_grow( ht )
	}

	return AllocatorError.None
}

hashtable_slot :: proc( ht : ^ HashTable( $ Type), key : u64 ) -> i64 {
	using ht
	for id := 0; id < hashes.num; id += 1 {
		if hashes[id] == key                {
			return id
		}
	}
	return -1
}

hashtable_add_entry :: proc( ht : ^ HashTable( $ Type), key : u64 ) -> i64 {
	using ht
	entry : HashTable_Entry = { key, -1 }
	id    := entries.num
	array_append( entries, entry )
	return id
}

hashtable_find :: proc( ht : ^ HashTable( $ Type), key : u64 ) -> HT_FindResult
{
	using ht
	find_result : HT_FindResult = { -1, -1, -1 }

	if hashes.num > 0 {
		result.hash_index  = key % hash.num
		result.entry_index = hashes[ result.hash_index ]

		for ; result.entry_index >= 0;                {
			if entries[ result.entry_index ].key == key {
				break
			}

			result.prev_index  = result.entry_index
			result.entry_index = entries[ result.entry_index ].next
		}
	}
	return result
}

hashtable_full :: proc( ht : ^ HashTable( $ Type) ) -> b32 {
	return 0.75 * hashes.num < entries.num
}
