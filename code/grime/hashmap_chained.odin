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
package grime

import "base:runtime"
import "core:mem"
import "core:strings"

HTable_Minimum_Capacity :: 4 * Kilobyte

HMapChainedSlot :: struct( $Type : typeid ) {
	using links : DLL_NodePN(HMapChainedSlot(Type)),
	value    : Type,
	key      : u64,
	occupied : b32,
}

HMapChainedHeader :: struct( $ Type : typeid ) {
	tracker  : MemoryTracker,
	pool     : Pool,
	lookup   : [] ^HMapChainedSlot(Type),
	dbg_name : string,
}

HMapChained :: struct( $ Type : typeid) {
	using header : ^HMapChainedHeader(Type),
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

hmap_chained_init :: proc( $HMapChainedType : typeid/HMapChained($Type), lookup_capacity : uint,
  allocator               := context.allocator,
	pool_bucket_cap         : uint   = 0,
	pool_bucket_reserve_num : uint   = 0,
	pool_alignment          : uint   = mem.DEFAULT_ALIGNMENT,
	dbg_name                : string = "",
	enable_mem_tracking     : b32    = false,
) -> (table : HMapChained(Type), error : AllocatorError)
{
	header_size := size_of(HMapChainedHeader(Type))
	size  := header_size + int(lookup_capacity) * size_of( ^HMapChainedSlot(Type)) + size_of(int)

	raw_mem : rawptr
	raw_mem, error = alloc( size, allocator = allocator )
	if error != AllocatorError.None do return

	pool_bucket_cap := pool_bucket_cap
	if pool_bucket_cap == 0 {
		pool_bucket_cap = cast(uint) int(lookup_capacity) * size_of( HMapChainedSlot(Type)) //* 2
	}

	table.header      = cast( ^HMapChainedHeader(Type)) raw_mem
	table.pool, error = pool_init(
		should_zero_buckets = false,
		block_size          = size_of(HMapChainedSlot(Type)),
		bucket_capacity     = pool_bucket_cap,
		bucket_reserve_num  = pool_bucket_reserve_num,
		alignment           = pool_alignment,
		allocator           = allocator,
		dbg_name            = strings.clone(str_fmt_tmp("%v: pool", dbg_name), allocator = allocator),
		enable_mem_tracking = enable_mem_tracking,
	)
	data          := transmute(^^HMapChainedSlot(Type)) memory_after_header(table.header)
	table.lookup   = slice_ptr( data, int(lookup_capacity) )
	table.dbg_name = dbg_name

	if Track_Memory && enable_mem_tracking {
		memtracker_init( & table.tracker, allocator, Kilobyte * 16, dbg_name )
	}

	return
}

hmap_chained_clear :: proc( using self : HMapChained($Type))
{
	for slot in lookup
	{
		if slot == nil {
			continue
		}
		for probe_slot := slot.next; probe_slot != nil; probe_slot = probe_slot.next {
			slot.occupied = false
		}
		slot.occupied = false
	}
}

hmap_chained_destroy :: proc( using self  : ^HMapChained($Type)) {
	pool_destroy( pool )
	free( self.header, self.pool.backing)
	self.header = nil
}

hmap_chained_lookup_id :: #force_inline proc( using self : HMapChained($Type), key : u64 ) -> u64
{
	hash_index := key % u64( len(lookup) )
	return hash_index
}

hmap_chained_get :: proc( using self : HMapChained($Type), key : u64) -> ^Type
{
	// profile(#procedure)
	hash_index   := hmap_chained_lookup_id(self, key)
	surface_slot := lookup[hash_index]

	if surface_slot == nil {
		return nil
	}

	if surface_slot.occupied && surface_slot.key == key {
		return & surface_slot.value
	}

	for slot := surface_slot.next; slot != nil; slot = slot.next
	{
		if slot.occupied && slot.key == key {
			if self.dbg_name != "" && self.tracker.entries.header != nil {
				log_fmt( "%v: Retrieved %v in lookup[%v] which shows key as %v", self.dbg_name, key, hash_index, slot.key )
			}
			return & slot.value
		}
	}

	return nil
}

hmap_chained_reload :: proc( self : HMapChained($Type), allocator : Allocator )
{
	pool_reload(self.pool, allocator)
}

// Returns true if an slot was actually found and marked as vacant
// Entries already found to be vacant will not return true
hmap_chained_remove :: proc( self : HMapChained($Type), key : u64 ) -> b32
{
	hash_index   := hmap_chained_lookup_id(self, key)
	surface_slot := self.lookup[hash_index]

	if surface_slot == nil {
		return false
	}

	if surface_slot.occupied && surface_slot.key == key {
		surface_slot.occupied = false
		surface_slot.value    = {}
		surface_slot.key      = {}
		if self.dbg_name != "" && self.tracker.entries.header != nil {
			logf( "%v: Removed %v in lookup[%v]", self.dbg_name, key, hash_index )
		}
		return true
	}

	nest_id : i32 = 1
	for slot := surface_slot.next; slot != nil; slot = slot.next
	{
		if slot.occupied && slot.key == key {
			slot.occupied = false
			slot.value    = {}
			slot.key      = {}
			if self.dbg_name != "" && self.tracker.entries.header != nil {
				logf( "%v: Removed %v in lookup[%v] nest_id: %v", self.dbg_name, key, hash_index, nest_id )
			}
			return true
		}
	}

	return false
}

// Sets the value to a vacant slot
// Will preemptively allocate the next slot in the hashtable if its null for the slot.
hmap_chained_set :: proc( self : HMapChained($Type), key : u64, value : Type ) -> (^ Type, AllocatorError)
{
	// profile(#procedure)
	using self
	hash_index   := hmap_chained_lookup_id(self, key)
	surface_slot := lookup[hash_index]

	slot_size := size_of(HMapChainedSlot(Type))
	if surface_slot == nil
	{
		raw_mem, error := alloc( size_of(HMapChainedSlot(Type)), allocator = pool.backing)
		block := slice_ptr(transmute([^]byte) raw_mem, slot_size)
		// block, error := pool_grab(pool, false)
		surface_slot := transmute( ^HMapChainedSlot(Type)) raw_data(block)
		surface_slot^ = {}

		surface_slot.key      = key
		surface_slot.value    = value
		surface_slot.occupied = true

		lookup[hash_index] = surface_slot

		if Track_Memory && tracker.entries.header != nil {
			memtracker_register_auto_name_slice( & self.tracker, block)
		}
		return & surface_slot.value, error
	}

	if ! surface_slot.occupied || surface_slot.key == key
	{
		surface_slot.key      = key
		surface_slot.value    = value
		surface_slot.occupied = true
		if dbg_name != "" && tracker.entries.header != nil {
			log_fmt( "%v: Set     %v in lookup[%v]", self.dbg_name, key, hash_index )
		}

		return & surface_slot.value, .None
	}

	slot : ^HMapChainedSlot(Type) = surface_slot
	nest_id : i32 = 1
	for ;; slot = slot.next
	{
		error : AllocatorError
		if slot.next == nil
		{
			raw_mem : rawptr
			block        : []byte
			raw_mem, error = alloc( size_of(HMapChainedSlot(Type)), allocator = pool.backing)
			block          = slice_ptr(transmute([^]byte) raw_mem, slot_size)
			// block, error = pool_grab(pool, false)
			next        := transmute( ^HMapChainedSlot(Type)) raw_data(block)

			slot.next      = next
			slot.next^     = {}
			slot.next.prev = slot
			if Track_Memory && tracker.entries.header != nil {
				memtracker_register_auto_name_slice( & self.tracker, block)
			}
		}

		if ! slot.next.occupied || slot.next.key == key
		{
			slot.next.key      = key
			slot.next.value    = value
			slot.next.occupied = true
			if dbg_name != "" && tracker.entries.header != nil {
				log_fmt( "%v: Set     %v in lookup[%v] nest_id: %v", self.dbg_name, key, hash_index, nest_id )
			}
			return & slot.next.value, .None
		}

		nest_id += 1
	}
	ensure(false, "Somehow got to a null slot that wasn't preemptively allocated from a previus set")
	return nil, AllocatorError.None
}
