package sectr

string_to_runes :: proc( content : string, allocator := context.allocator ) -> ( []rune, AllocatorError )
{
	num := cast(u64) str_rune_count(content)

	runes_array, alloc_error := array_init_reserve( rune, allocator, num )
	if alloc_error != AllocatorError.None {
		ensure( false, "Failed to allocate runes array" )
		return nil, alloc_error
	}

	runes := array_to_slice(runes_array)

	idx := 0
	for codepoint in content {
		runes[idx] = codepoint
		idx        += 1
	}
	return runes, alloc_error
}
