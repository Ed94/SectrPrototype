package grime

rune16 :: distinct u16

// Exposing the alloc_error
@(require_results)
string_to_runes :: proc ( content : string, allocator := context.allocator) -> (runes : []rune, alloc_error : AllocatorError) #optional_allocator_error {
	num := str_rune_count(content)

	runes, alloc_error = make([]rune, num, allocator)
	if runes == nil || alloc_error != AllocatorError.None {
		return
	}

	idx := 0
	for codepoint in content {
		runes[idx] = codepoint
		idx += 1
	}
	return
}

string_to_runes_array :: proc( content : string, allocator := context.allocator ) -> ( []rune, AllocatorError )
{
	num := cast(u64) str_rune_count(content)

	runes_array, alloc_error := make( Array(rune), num, allocator )
	if alloc_error != AllocatorError.None {
		return nil, alloc_error
	}

	runes := array_to_slice_capacity(runes_array)

	idx := 0
	for codepoint in content {
		runes[idx] = codepoint
		idx        += 1
	}
	return runes, alloc_error
}
