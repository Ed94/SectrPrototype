/*
This is a quick and dirty string table.
IT uses the HMapZPL for the hashtable of strings, and the string's content is stored in a dedicated slab.

Future Plans (IF needed for performance):
The goal is to eventually swap out the slab with possilby a dedicated growing vmem arena for the strings.
The table would be swapped with a table stored in the general slab and uses either linear probing or open addressing

If linear probing, the hash node list per table bucket is store with the strigns in the same arena.
If open addressing, we just keep the open addressed array of node slots in the general slab (but hopefully better perf)
*/
package sectr

import "core:mem"
import "core:slice"
import "core:strings"

StringCached :: struct {
	str   : string,
	runes : []rune,
}

StringCache :: struct {
	slab      : Slab,
	table     : HMapZPL(StringCached),
}

str_cache_init :: proc( /*allocator : Allocator*/ ) -> ( cache : StringCache ) {
	alignment := uint(mem.DEFAULT_ALIGNMENT)

	policy     : SlabPolicy
	policy_ptr := & policy
	push( policy_ptr, SlabSizeClass {   8 * Megabyte,             16, alignment })
	push( policy_ptr, SlabSizeClass {   8 * Megabyte,             32, alignment })
	push( policy_ptr, SlabSizeClass {  16 * Megabyte,             64, alignment })
	push( policy_ptr, SlabSizeClass {  16 * Megabyte,            128, alignment })
	push( policy_ptr, SlabSizeClass {  16 * Megabyte,            256, alignment })
	push( policy_ptr, SlabSizeClass {  16 * Megabyte,            512, alignment })
	push( policy_ptr, SlabSizeClass {  32 * Megabyte,   1 * Kilobyte, alignment })
	push( policy_ptr, SlabSizeClass {  32 * Megabyte,   4 * Kilobyte, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Megabyte,  16 * Kilobyte, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Megabyte,  32 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte,  64 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte, 128 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte, 256 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte, 512 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte,   1 * Megabyte, alignment })

	header_size :: size_of( Slab )

	alloc_error : AllocatorError
	cache.slab, alloc_error = slab_init( & policy, allocator = persistent_allocator() )
	verify(alloc_error == .None, "Failed to initialize the string cache" )

	cache.table, alloc_error = zpl_hmap_init_reserve( StringCached, general_slab_allocator(), 64 * Kilobyte )
	return
}

// str_cache_intern_string :: proc(
	// cache : ^StringCache,
str_intern :: proc(
	content : string
) -> StringCached
{
	cache := get_state().string_cache

	key    := u64( crc32( transmute([]byte) content ))
	result := zpl_hmap_get( & cache.table, key )
	if result != nil {
		return (result ^)
	}

	length := len(content)
	str_mem, alloc_error := slab_alloc( cache.slab, uint(length), uint(mem.DEFAULT_ALIGNMENT) )
	verify( alloc_error == .None, "String cache had a backing allocator error" )

	copy_non_overlapping( raw_data(str_mem), raw_data(content), length )

	runes : []rune
	runes, alloc_error = to_runes( content, slab_allocator(cache.slab) )
	verify( alloc_error == .None, "String cache had a backing allocator error" )

	result, alloc_error = zpl_hmap_set( & cache.table, key, StringCached { transmute(string) str_mem, runes } )
	verify( alloc_error == .None, "String cache had a backing allocator error" )

	return (result ^)
}
