/*
This is an alternative to Odin's default map type.
The only reason I may need this is due to issues with allocator callbacks or something else going on
with hot-reloads...
---------------------------------------------------------------------------------------------------------
5-21-2024 Update: Still haven't taken the time to see why but just to add the original case for the above
was I believe exclusively when I didn't set the base addresss of vmem
OR when I was attempting to use Casey's brute force replay feature with memory.
5-26-2024 Update:
TODO(Ed): There is a Raw_Map structure defined in base:runtime/core.odin
We can use the regulare dynamic 
---------------------------------------------------------------------------------------------------------

This implementation uses two ZPL-Based Arrays to hold entires and the actual hash table.
Instead of using separate chains, it maintains linked entries within the array.
Each entry contains a next field, which is an index pointing to the next entry in the same array.

Growing this hashtable is destructive, so it should usually be kept to a fixed-size unless
the populating operations only occur in one place and from then on its read-only.
*/
package grime

import "core:slice"

// Note(Ed) : See core:hash for hasing procs.

HMapZPL_MapProc    :: #type proc( $ Type : typeid, key : u64, value :   Type )
HMapZPL_MapMutProc :: #type proc( $ Type : typeid, key : u64, value : ^ Type )

HMapZPL_CritialLoadScale :: 0.70
HMapZPL_HashToEntryRatio :: 1.50

HMapZPL_FindResult :: struct {
	hash_index  : i64,
	prev_index  : i64,
	entry_index : i64,
}

HMapZPL_Entry :: struct ( $ Type : typeid) {
	key   : u64,
	next  : i64,
	value : Type,
}

HMapZPL :: struct ( $ Type : typeid ) {
	table   : Array( i64 ),
	entries : Array( HMapZPL_Entry(Type) ),
}

hmap_zpl_init :: proc
( $HMapZPL_Type : typeid / HMapZPL($Type), num : u64, allocator := context.allocator, dbg_name : string = "" ) -> ( HMapZPL( Type), AllocatorError )
{
	result                       : HMapZPL(Type)
	table_result, entries_result : AllocatorError

	result.table, table_result = make( Array(i64), num, dbg_name = dbg_name, allocator = allocator )
	if table_result != AllocatorError.None {
		ensure( false, "Failed to allocate table array" )
		return result, table_result
	}
	array_resize( & result.table, num )
	slice.fill( slice_ptr( result.table.data, cast(int) result.table.num), -1 )

	result.entries, entries_result = make( Array( HMapZPL_Entry(Type) ), num, dbg_name = dbg_name, allocator = allocator )
	if entries_result != AllocatorError.None {
		ensure( false, "Failed to allocate entries array" )
		return result, entries_result
	}
	return result, AllocatorError.None
}

hmap_zpl_clear :: proc( using self : ^ HMapZPL( $ Type ) ) {
	for id := 0; id < int(table.num); id += 1 {
		table.data[id] = -1
	}

	// array_clear( table )
	array_clear( entries )
}

hmap_zpl_destroy :: proc( using self : ^ HMapZPL( $ Type ) ) {
	if table.data != nil && table.capacity > 0 {
		array_free( table )
		array_free( entries )
	}
}

hmap_zpl_get :: proc ( using self : ^ HMapZPL( $ Type ), key : u64 ) -> ^ Type
{
	// profile(#procedure)
	id := hmap_zpl_find( self, key ).entry_index
	if id >= 0 {
		return & entries.data[id].value
	}

	return nil
}

hmap_zpl_map :: proc( using self : ^ HMapZPL( $ Type), map_proc : HMapZPL_MapProc ) {
	ensure( map_proc != nil, "Mapping procedure must not be null" )
	for id := 0; id < entries.num; id += 1 {
		map_proc( Type, entries[id].key, entries[id].value )
	}
}

hmap_zpl_map_mut :: proc( using self : ^ HMapZPL( $ Type), map_proc : HMapZPL_MapMutProc ) {
	ensure( map_proc != nil, "Mapping procedure must not be null" )
	for id := 0; id < entries.num; id += 1 {
		map_proc( Type, entries[id].key, & entries[id].value )
	}
}

hmap_zpl_grow :: proc( using self : ^ HMapZPL( $ Type ) ) -> AllocatorError {
	new_num : u64 = cast(u64) hmap_closest_prime( cast(uint) array_grow_formula( entries.num ) )
	return hmap_zpl_rehash( self, new_num )
}

hmap_zpl_rehash :: proc( ht : ^ HMapZPL( $ Type ), new_num : u64 ) -> AllocatorError
{
	profile(#procedure)
	// For now the prototype should never allow this to happen.
	ensure( false, "ZPL HMAP IS REHASHING" )
	last_added_index : i64

	new_ht, init_result := hmap_zpl_init( HMapZPL(Type), new_num, ht.table.backing, ht.table.dbg_name )
	if init_result != AllocatorError.None {
		ensure( false, "New hmap_zpl failed to allocate" )
		return init_result
	}

	for id : u64 = 0; id < ht.entries.num; id += 1 {
		find_result : HMapZPL_FindResult

		entry           := & ht.entries.data[id]
		find_result      = hmap_zpl_find( & new_ht, entry.key )
		last_added_index = hmap_zpl_add_entry( & new_ht, entry.key )

		if find_result.prev_index < 0 {
			new_ht.table.data[ find_result.hash_index ] = last_added_index
		}
		else {
			new_ht.entries.data[ find_result.prev_index ].next = last_added_index
		}

		new_ht.entries.data[ last_added_index ].next  = find_result.entry_index
		new_ht.entries.data[ last_added_index ].value = entry.value
	}

	hmap_zpl_destroy( ht )

	(ht ^) = new_ht
	return AllocatorError.None
}

hmap_zpl_rehash_fast :: proc( using self : ^ HMapZPL( $ Type ) )
{
	for id : i64 = 0; id < i64(entries.num); id += 1 {
		entries.data[id].next = -1;
	}
	for id : i64 = 0; id < i64(table.num); id += 1 {
		table.data[id] = -1
	}
	for id : i64 = 0; id < i64(entries.num); id += 1 {
		entry       := & entries.data[id]
		find_result := hmap_zpl_find( self, entry.key )

		if find_result.prev_index < 0 {
			table.data[ find_result.hash_index ] = id
		}
		else {
			entries.data[ find_result.prev_index ].next = id
		}
	}
}

// Used when the address space of the allocator changes and the backing reference must be updated
hmap_zpl_reload :: proc( using self : ^HMapZPL($Type), new_backing : Allocator ) {
	table.backing   = new_backing
	entries.backing = new_backing
}

hmap_zpl_remove :: proc( self : ^ HMapZPL( $ Type ), key : u64 ) {
	find_result := hmap_zpl_find( self, key )

	if find_result.entry_index >= 0 {
		array_remove_at( self.entries, u64(find_result.entry_index) )
		hmap_zpl_rehash_fast( self )
	}
}

hmap_zpl_remove_entry :: proc( using self : ^ HMapZPL( $ Type ), id : i64 ) {
	array_remove_at( & entries, id )
}

hmap_zpl_set :: proc( using self : ^ HMapZPL( $ Type), key : u64, value : Type ) -> (^ Type, AllocatorError)
{
	// profile(#procedure)
	id          : i64 = 0
	find_result : HMapZPL_FindResult

	if hmap_zpl_full( self )
	{
		grow_result := hmap_zpl_grow( self )
		if grow_result != AllocatorError.None {
				return nil, grow_result
		}
	}

	find_result = hmap_zpl_find( self, key )
	if find_result.entry_index >= 0 {
		id = find_result.entry_index
	}
	else
	{
		id = hmap_zpl_add_entry( self, key )
		if find_result.prev_index >= 0 {
			entries.data[ find_result.prev_index ].next = id
		}
		else {
			table.data[ find_result.hash_index ] = id
		}
	}

	entries.data[id].value = value

	if hmap_zpl_full( self ) {
		alloc_error := hmap_zpl_grow( self )
		return & entries.data[id].value, alloc_error
	}

	return & entries.data[id].value, AllocatorError.None
}

hmap_zpl_slot :: proc( using self : ^ HMapZPL( $ Type), key : u64 ) -> i64 {
	for id : i64 = 0; id < table.num; id += 1 {
		if table.data[id] == key                {
			return id
		}
	}
	return -1
}

hmap_zpl_add_entry :: proc( using self : ^ HMapZPL( $ Type), key : u64 ) -> i64 {
	entry : HMapZPL_Entry(Type) = { key, -1, {} }
	id    := cast(i64) entries.num
	array_append( & entries, entry )
	return id
}

hmap_zpl_find :: proc( using self : ^ HMapZPL( $ Type), key : u64 ) -> HMapZPL_FindResult
{
	// profile(#procedure)
	result : HMapZPL_FindResult = { -1, -1, -1 }

	if table.num > 0 {
		result.hash_index  = cast(i64)( key % table.num )
		result.entry_index = table.data[ result.hash_index ]

		verify( result.entry_index < i64(entries.num), "Entry index is larger than the number of entries" )

		for ; result.entry_index >= 0; {
			entry := & entries.data[ result.entry_index ]
			if entry.key == key {
				break
			}

			result.prev_index  = result.entry_index
			result.entry_index = entry.next
		}
	}
	return result
}

hmap_zpl_full :: proc( using self : ^ HMapZPL( $ Type) ) -> b32 {
	critical_load := u64(HMapZPL_CritialLoadScale * cast(f64) table.num)
	result : b32 = entries.num > critical_load
	return result
}
