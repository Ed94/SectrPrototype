package grime

/* Fixed Arena Allocator (Fixed-szie block bump allocator) */

FArena :: struct {
	mem:  []byte,
	used:   int,
}
@require_results
farena_make :: proc "contextless" (backing: []byte) -> FArena { 
	arena := FArena {mem = backing}
	return arena 
}
farena_init :: proc "contextless" (arena: ^FArena, backing: []byte) {
	assert_contextless(arena != nil)
	arena.mem  = backing
	arena.used = 0
}
@require_results
farena_push :: proc "contextless" (arena: ^FArena, $Type: typeid, amount: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, loc := #caller_location) -> ([]Type, AllocatorError) {
	assert_contextless(arena != nil)
	if amount == 0 {
		return {}, .None
	}
	desired   := size_of(Type) * amount
	to_commit := align_pow2(desired, alignment)
	unused    := len(arena.mem) - arena.used
	if (to_commit <= unused) {
		return {}, .Out_Of_Memory
	}
	arena.used += to_commit
	return slice(cursor(arena.mem)[arena.used:], amount), .None
}
@require_results
farena_grow :: proc "contextless" (arena: ^FArena, old_allocation: []byte, requested_size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, should_zero: bool = true, loc := #caller_location) -> (allocation: []byte, err: AllocatorError) {
	assert_contextless(arena != nil)
	if len(old_allocation) == 0 {
		return {}, .Invalid_Argument
	}
	alloc_end := end(old_allocation)
	arena_end := cursor(arena.mem)[arena.used:]
	if alloc_end != arena_end { 
		return {}, .Out_Of_Memory
	}
	// Calculate growth
	grow_amount  := requested_size - len(old_allocation)
	aligned_grow := align_pow2(grow_amount, alignment)
	unused       := len(arena.mem) - arena.used
	if aligned_grow > unused { 
		return {}, .Out_Of_Memory
	}
	arena.used += aligned_grow
	allocation = slice(cursor(old_allocation), requested_size)
	if should_zero {
		mem_zero( cursor(allocation)[len(old_allocation):], grow_amount )
	}
	err = .None
	return
}
@require_results
farena_shirnk :: proc "contextless" (arena: ^FArena, old_allocation: []byte, requested_size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, loc := #caller_location) -> (allocation: []byte, err: AllocatorError) {
	assert_contextless(arena != nil)
	if len(old_allocation) == 0 {
		return {}, .Invalid_Argument
	}
	alloc_end := end(old_allocation)
	arena_end := cursor(arena.mem)[arena.used:]
	if alloc_end != arena_end {
		// Not at the end, can't shrink but return adjusted size
		return old_allocation[:requested_size], .None
	}
	// Calculate shrinkage
	aligned_original := align_pow2(len(old_allocation), MEMORY_ALIGNMENT_DEFAULT)
	aligned_new      := align_pow2(requested_size, alignment)
	arena.used       -= (aligned_original - aligned_new)
	return old_allocation[:requested_size], .None
}
farena_reset :: #force_inline proc "contextless" (arena: ^FArena, loc := #caller_location) {
	assert_contextless(arena != nil)
	arena.used = 0
}
farena_rewind :: #force_inline proc "contextless" (arena: ^FArena, save_point: AllocatorSP, loc := #caller_location) {
	assert_contextless(save_point.type_sig  == farena_allocator_proc)
	assert_contextless(save_point.slot >= 0 && save_point.slot <= arena.used)
	arena.used = save_point.slot
}
farena_save :: #force_inline proc "contextless" (arena: FArena) -> AllocatorSP { return AllocatorSP { type_sig = farena_allocator_proc, slot = arena.used } }
farena_allocator_proc :: proc(input: AllocatorProc_In, output: ^AllocatorProc_Out) {
	assert_contextless(output     != nil)
	assert_contextless(input.data != nil)
	arena := transmute(^FArena) input.data
	switch input.op {
	case .Alloc, .Alloc_NoZero:
		output.allocation, output.error = farena_push(arena, byte, input.requested_size, input.alignment, input.loc)
		if input.op == .Alloc {
			zero(output.allocation)
		}
		return
	case .Free:
		// No-op for arena
		return
	case .Reset:
		farena_reset(arena)
		return
	case .Grow, .Grow_NoZero:
		output.allocation, output.error = farena_grow(arena, input.old_allocation, input.requested_size, input.alignment, input.op == .Grow)
		return
	case .Shrink:
		output.allocation, output.error = farena_shirnk(arena, input.old_allocation, input.requested_size, input.alignment)
		return
	case .Rewind:
		farena_rewind(arena, input.save_point)
		return
	case .SavePoint:
		output.save_point = farena_save(arena^)
		return
	case .Query:
		output.features   = {.Alloc, .Reset, .Grow, .Shrink, .Rewind}
		output.max_alloc  = len(arena.mem) - arena.used
		output.min_alloc  = 0
		output.left       = output.max_alloc
		output.save_point = farena_save(arena^)
		return
	}
	panic_contextless("Impossible path")
}
farena_odin_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : Odin_AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	location       : SourceCodeLocation = #caller_location
) -> ( data : []byte, alloc_error : AllocatorError)
{
	assert_contextless(allocator_data != nil)
	arena := transmute(^FArena) allocator_data
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data, alloc_error = farena_push(arena, byte, size, alignment, location)
		if mode == .Alloc {
			zero(data)
		}
		return
	case .Free:
		return {}, .Mode_Not_Implemented
	case .Free_All:
		farena_reset(arena)
		return
	case .Resize, .Resize_Non_Zeroed:
		if (size > old_size) do data, alloc_error = farena_grow  (arena, slice(cursor(old_memory), old_size), size, alignment, mode == .Resize)
		else                 do data, alloc_error = farena_shirnk(arena, slice(cursor(old_memory), old_size), size, alignment)
		return
	case .Query_Features:
		set := (^Odin_AllocatorModeSet)(old_memory)
		if set != nil {
			set^ = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features, .Query_Info}
		}
		return
	case .Query_Info:
		info := (^Odin_AllocatorQueryInfo)(old_memory)
		info.pointer   = transmute(rawptr) farena_save(arena^).slot
		info.size      = len(arena.mem) - arena.used
		info.alignment = MEMORY_ALIGNMENT_DEFAULT
		return to_bytes(info), nil
	}
	panic_contextless("Impossible path")
}
when ODIN_DEBUG {
	farena_ainfo     :: #force_inline proc "contextless" (arena: ^FArena) -> AllocatorInfo  { return                           AllocatorInfo{proc_id = .FArena, data = arena} }
	farena_allocator :: #force_inline proc "contextless" (arena: ^FArena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{proc_id = .FArena, data = arena} }
}
else {
	farena_ainfo     :: #force_inline proc "contextless" (arena: ^FArena) -> AllocatorInfo  { return                           AllocatorInfo{procedure = farena_allocator_proc, data = arena} }
	farena_allocator :: #force_inline proc "contextless" (arena: ^FArena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{procedure = farena_allocator_proc, data = arena} }
}
