/*
String Intering Table using its own dedicated slab & chained hashtable

If linear probing, the hash node list per table bucket is store with the strigns in the same arena.
If open addressing, we just keep the open addressed array of node slots in the general slab (but hopefully better perf)

TODO(Ed): Move the string cache to its own virtual arena?
Its going to be used heavily and we can better utilize memory that way.
The arena can deal with alignment just fine or we can pad in a min amount per string.
*/
package grime

import "base:runtime"
import "core:mem"
import "core:slice"
import "core:strings"

StringKey   :: distinct u64
RunesCached :: []rune

// Note(Ed): No longer using for caching but could still be useful in the future
StrRunesPair :: struct {
	str   : string,
	runes : []rune,
}
to_str_runes_pair_via_string :: #force_inline proc ( content : string ) -> StrRunesPair { return { content, to_runes(content) }  }
to_str_runes_pair_via_runes  :: #force_inline proc ( content : []rune ) -> StrRunesPair { return { to_string(content), content } }

StrCached :: string

StringCache :: struct {
	slab      : Slab,
	table     : HMapChained(StrCached),
}

// This is the default string cache for the runtime module.
Module_String_Cache : ^StringCache

str_cache_init :: proc( table_allocator, slabs_allocator : Allocator ) -> (cache : StringCache)
{
	// alignment := uint(mem.DEFAULT_ALIGNMENT)
	alignment := uint(64)

	policy     : SlabPolicy
	policy_ptr := & policy
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,              8, alignment })
	push( policy_ptr, SlabSizeClass {  64 * Kilobyte,             16, alignment })
	push( policy_ptr, SlabSizeClass { 128 * Kilobyte,             32, alignment })
	push( policy_ptr, SlabSizeClass { 640 * Kilobyte,             64, alignment })
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

	// TODO(Ed): Is this nessary (essentially is there a perf impact of using vs not using, which is better because thats all that matters)
	// Interning should only be handled on a growing arena anyway so it doesn't really need this.
	alloc_error : AllocatorError
	cache.slab, alloc_error = slab_init( & policy, allocator = slabs_allocator, dbg_name = dbg_name )
	verify(alloc_error == .None, "Failed to initialize the string cache" )

	cache.table, alloc_error = make( HMapChained(StrCached), 4 * Kilo, table_allocator, dbg_name = dbg_name )
	return
}

str_cache_reload :: #force_inline proc ( cache : ^StringCache, table_allocator, slabs_allocator : Allocator  ) {
	slab_reload( cache.slab, table_allocator )
	hmap_chained_reload( cache.table, slabs_allocator )
}

str_cache_set_module_ctx :: #force_inline proc "contextless" ( cache : ^StringCache ) { Module_String_Cache = cache }
str_intern_key           :: #force_inline proc( content : string ) ->  StringKey      { return cast(StringKey) crc32( transmute([]byte) content ) }
str_intern_lookup        :: #force_inline proc( key : StringKey )  -> (^StrCached)    { return hmap_chained_get( Module_String_Cache.table, transmute(u64) key ) }

str_intern :: #force_inline proc( content : string ) -> StrCached
{
	// profile(#procedure)
	cache  := Module_String_Cache
	key    := str_intern_key(content)
	result := hmap_chained_get( cache.table, transmute(u64) key )
	if result != nil {
		return (result ^)
	}

	length := len(content)
	str_mem, alloc_error := slab_alloc( cache.slab, uint(length), uint(mem.DEFAULT_ALIGNMENT), zero_memory = false )
	verify( alloc_error == .None, "String cache had a backing allocator error" )

	copy_non_overlapping( raw_data(str_mem), raw_data(content), length )

	result, alloc_error = hmap_chained_set( cache.table, transmute(u64) key, transmute(StrCached) str_mem )
	verify( alloc_error == .None, "String cache had a backing allocator error" )
	// slab_validate_pools( cache.slab.backing )

	return (result ^)
}

str_intern_fmt :: #force_inline proc( format : string, args : ..any, allocator := context.allocator ) -> StrCached {
	return str_intern(str_fmt(format, args, allocator = allocator))
}

// runes_intern :: proc( content : []rune ) -> StrRunesPair
// {
// 	cache := get_state().string_cache
// }
