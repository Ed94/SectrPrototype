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

import "base:runtime"
import "core:mem"
import "core:slice"
import "core:strings"

StringKey   :: distinct u64
RunesCached :: []rune

StrRunesPair :: struct {
	str   : string,
	runes : []rune,
}
to_str_runes_pair_via_string :: #force_inline proc ( content : string ) -> StrRunesPair { return { content, to_runes(content) }  }
to_str_runes_pair_via_runes  :: #force_inline proc ( content : []rune ) -> StrRunesPair { return { to_string(content), content } }

StringCache :: struct {
	slab      : Slab,
	table     : HMapZPL(StrRunesPair),
}

str_cache_init :: proc( /*allocator : Allocator*/ ) -> ( cache : StringCache ) {
	alignment := uint(mem.DEFAULT_ALIGNMENT)

	policy     : SlabPolicy
	policy_ptr := & policy
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,             16, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,             32, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,             64, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,            128, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,            256, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,            512, alignment })
	push( policy_ptr, SlabSizeClass {   1 * Megabyte,   1 * Kilobyte, alignment })
	push( policy_ptr, SlabSizeClass {   4 * Megabyte,   4 * Kilobyte, alignment })
	push( policy_ptr, SlabSizeClass {  16 * Megabyte,  16 * Kilobyte, alignment })
	push( policy_ptr, SlabSizeClass {  32 * Megabyte,  32 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte,  64 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte, 128 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte, 256 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte, 512 * Kilobyte, alignment })
	// push( policy_ptr, SlabSizeClass {  64 * Megabyte,   1 * Megabyte, alignment })

	header_size :: size_of( Slab )

	@static dbg_name := "StringCache slab"

	state := get_state()

	alloc_error : AllocatorError
	cache.slab, alloc_error = slab_init( & policy, allocator = persistent_allocator(), dbg_name = dbg_name )
	verify(alloc_error == .None, "Failed to initialize the string cache" )

	cache.table, alloc_error = zpl_hmap_init_reserve( StrRunesPair, persistent_allocator(), 4 * Megabyte, dbg_name )
	return
}

str_intern_key    :: #force_inline proc( content : string ) ->  StringKey      { return cast(StringKey) crc32( transmute([]byte) content ) }
str_intern_lookup :: #force_inline proc( key : StringKey )  -> (^StrRunesPair) { return zpl_hmap_get( & get_state().string_cache.table, transmute(u64) key ) }

str_intern :: proc(
	content : string
) -> StrRunesPair
{
	// profile(#procedure)
	cache := & get_state().string_cache

	key    := str_intern_key(content)
	result := zpl_hmap_get( & cache.table, transmute(u64) key )
	if result != nil {
		return (result ^)
	}

	// profile_begin("new entry")
	{
		length := len(content)
		// str_mem, alloc_error := alloc( length, mem.DEFAULT_ALIGNMENT )
		str_mem, alloc_error := slab_alloc( cache.slab, uint(length), uint(mem.DEFAULT_ALIGNMENT), zero_memory = false )
		verify( alloc_error == .None, "String cache had a backing allocator error" )

		// copy_non_overlapping( str_mem, raw_data(content), length )
		copy_non_overlapping( raw_data(str_mem), raw_data(content), length )

		runes : []rune
		// runes, alloc_error = to_runes( content, persistent_allocator() )
		runes, alloc_error = to_runes( content, slab_allocator(cache.slab) )
		verify( alloc_error == .None, "String cache had a backing allocator error" )

		slab_validate_pools( get_state().persistent_slab )

		// result, alloc_error = zpl_hmap_set( & cache.table, key, StrRunesPair { transmute(string) byte_slice(str_mem, length), runes } )
		result, alloc_error = zpl_hmap_set( & cache.table, transmute(u64) key, StrRunesPair { transmute(string) str_mem, runes } )
		verify( alloc_error == .None, "String cache had a backing allocator error" )

		slab_validate_pools( get_state().persistent_slab )
	}
	// profile_end()

	return (result ^)
}

// runes_intern :: proc( content : []rune ) -> StrRunesPair
// {
// 	cache := get_state().string_cache
// }
