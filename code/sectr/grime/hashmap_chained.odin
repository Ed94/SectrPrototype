/*
Separate chaining hashtable with tombstone (vacancy aware)

This is an alternative to odin's map and the zpl hashtable I first used for this codebase.

So this is a hahstable loosely based at what I saw in the raddbg codebase.
It uses a fixed-size lookup table for the base layer of entries that can be chained.
Each slot keeps track of its vacancy (tombstone, is occupied).
If its occupied a new slot is chained using the fixed bucket-size pool allocator which will have its blocks sized to the type of the table.

This is ideal for tables have an indeterminate scope for how entires are added,
and direct pointers are kept across the codebase instead of a key to the slot.
*/
package sectr

import "core:mem"

HTable_Minimum_Capacity :: 4 * Kilobyte

HMapChainedSlot :: struct( $Type : typeid ) {
	using links : DLL_NodePN(HMapChainedSlot(Type)),
	value    : Type,
	key      : u64,
	occupied : b32,
}

HMapChained :: struct( $ Type : typeid ) {
	pool    : Pool,
	lookup  : [] ^HMapChainedSlot(Type),
}

HMapChainedPtr :: struct( $ Type : typeid) {
	using header : ^HMapChained(Type),
}

// Provides the nearest prime number value for the given capacity
hmap_closest_prime :: proc( capacity : uint ) -> uint
{
	prime_table : []uint = {
		53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
		49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
		6291469, 12582917, 25165843, 50331653, 100663319,
		201326611, 402653189, 805306457, 1610612741, 3221225473, 6442450941
	};
	for slot in prime_table {
		if slot >= capacity {
			return slot
		}
	}
	return prime_table[len(prime_table) - 1]
}

hmap_chained_init :: proc( $Type : typeid, lookup_capacity : uint, allocator : Allocator,
	pool_bucket_cap         : uint   = 1 * Kilo,
	pool_bucket_reserve_num : uint   = 0,
	pool_alignment          : uint   = mem.DEFAULT_ALIGNMENT,
	dbg_name                : string = ""
) -> (table : HMapChainedPtr(Type), error : AllocatorError)
{
	header_size := size_of(HMapChained(Type))
	size  := header_size + int(lookup_capacity) * size_of( ^HMapChainedSlot(Type)) + size_of(int)

	raw_mem : rawptr
	raw_mem, error = alloc( size, allocator = allocator )
	if error != AllocatorError.None do return

	table.header      = cast( ^HMapChained(Type)) raw_mem
	table.pool, error = pool_init(
		should_zero_buckets = false,
		block_size          = size_of(HMapChainedSlot(Type)),
		bucket_capacity     = pool_bucket_cap,
		bucket_reserve_num  = pool_bucket_reserve_num,
		alignment           = pool_alignment,
		allocator           = allocator,
		dbg_name            = str_intern(str_fmt("%v: pool", dbg_name)).str
	)
	data        := transmute([^] ^HMapChainedSlot(Type)) (transmute( [^]HMapChained(Type)) table.header)[1:]
	table.lookup = slice_ptr( data, int(lookup_capacity) )
	return
}

hmap_chained_clear :: proc( using self : HMapChainedPtr($Type))
{
	for slot in lookup
	{
		if slot == nil {
			continue
		}
		for probe_slot = slot.next; probe_slot != nil; probe_slot = probe_slot.next {
			slot.occupied = false
		}
		slot.occupied = false
	}
}

hmap_chained_destroy :: proc( using self  : ^HMapChainedPtr($Type)) {
	pool_destroy( pool )
	free( self.header, backing)
	self = nil
}

hmap_chained_lookup_id :: #force_inline proc( using self : HMapChainedPtr($Type), key : u64 ) -> u64
{
	hash_index := key % u64( len(lookup) )
	return hash_index
}

hmap_chained_get :: proc( using self : HMapChainedPtr($Type), key : u64) -> ^Type
{
	// profile(#procedure)
	surface_slot := lookup[hmap_chained_lookup_id(self, key)]

	if surface_slot == nil {
		return nil
	}

	if surface_slot.occupied && surface_slot.key == key {
		return & surface_slot.value
	}

	for slot := surface_slot.next; slot != nil; slot = slot.next {
		if slot.occupied && slot.key == key {
			return & surface_slot.value
		}
	}

	return nil
}

hmap_chained_reload :: proc( self : HMapChainedPtr($Type), allocator : Allocator )
{
	pool_reload(self.pool, allocator)
}

// Returns true if an slot was actually found and marked as vacant
// Entries already found to be vacant will not return true
hmap_chained_remove :: proc( self : HMapChainedPtr($Type), key : u64 ) -> b32
{
	surface_slot := lookup[hmap_chained_lookup_id(self, key)]

	if surface_slot == nil {
		return false
	}

	if surface_slot.occupied && surface_slot.key == key {
		surface_slot.occupied = false
		return true
	}

	for slot := surface_slot.next; slot != nil; slot.next
	{
		if slot.occupied && slot.key == key {
			slot.occupied = false
			return true
		}
	}

	return false
}

// Sets the value to a vacant slot
// Will preemptively allocate the next slot in the hashtable if its null for the slot.
hmap_chained_set :: proc( using self : HMapChainedPtr($Type), key : u64, value : Type ) -> (^ Type, AllocatorError)
{
	// profile(#procedure)
	hash_index   := hmap_chained_lookup_id(self, key)
	surface_slot := lookup[hash_index]
	set_slot :: #force_inline proc( using self : HMapChainedPtr(Type),
		slot  : ^HMapChainedSlot(Type),
		key   : u64,
		value : Type
	) -> (^ Type, AllocatorError )
	{
		error := AllocatorError.None
		if slot.next == nil {
			block        : []byte
			block, error = pool_grab(pool)
			next        := transmute( ^HMapChainedSlot(Type)) & block[0]
			slot.next    = next
			next.prev    = slot
		}
		slot.key      = key
		slot.value    = value
		slot.occupied = true
		return & slot.value, error
	}

	if surface_slot == nil {
		block, error         := pool_grab(pool)
		surface_slot         := transmute( ^HMapChainedSlot(Type)) & block[0]
		surface_slot.key      = key
		surface_slot.value    = value
		surface_slot.occupied = true
		if error != AllocatorError.None {
			ensure(error != AllocatorError.None, "Allocation failure for chained slot in hash table")
			return nil, error
		}
		lookup[hash_index] = surface_slot

		block, error = pool_grab(pool)
		next             := transmute( ^HMapChainedSlot(Type)) & block[0]
		surface_slot.next = next
		next.prev         = surface_slot
		return & surface_slot.value, error
	}

	if ! surface_slot.occupied
	{
		result, error := set_slot( self, surface_slot, key, value)
		return result, error
	}

	slot := surface_slot.next
	for ; slot != nil; slot = slot.next
	{
		if !slot.occupied
		{
			result, error := set_slot( self, surface_slot, key, value)
			return result, error
		}
	}
	ensure(false, "Somehow got to a null slot that wasn't preemptively allocated from a previus set")
	return nil, AllocatorError.None
}
