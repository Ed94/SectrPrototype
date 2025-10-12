package grime

FArena :: struct {
	mem:  []byte,
	used:   int,
}
@require_results
farena_make :: proc(backing: []byte) -> FArena { 
	arena := FArena {mem = backing}
	return arena 
}
farena_init :: proc(arena: ^FArena, backing: []byte) {
	assert(arena != nil)
	arena.mem  = backing
	arena.used = 0
}
@require_results
farena_push :: proc(arena: ^FArena, $Type: typeid, amount: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT) -> []Type {
	assert(arena != nil)
	if amount == 0 {
		return {}
	}
	desired   := size_of(Type) * amount
	to_commit := align_pow2(desired, alignment)
	unused    := len(arena.mem) - arena.used
	assert(to_commit <= unused)
	ptr        := cursor(arena.mem[arena.used:])
	arena.used += to_commit
	return slice(ptr, amount)
}
@require_results
farena_grow :: proc(arena: ^FArena, old_allocation: []byte, requested_size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, should_zero: bool = true) -> (allocation: []byte, err: AllocatorError) {
	if len(old_allocation) == 0 {
		return {}, .Invalid_Argument
	}
	alloc_end := end(old_allocation)
	arena_end := cursor(arena.mem)[arena.used:]
	if alloc_end != arena_end {
		// Not at the end, can't grow in place
		return {}, .Out_Of_Memory
	}
	// Calculate growth
	grow_amount  := requested_size - len(old_allocation)
	aligned_grow := align_pow2(grow_amount, alignment)
	unused       := len(arena.mem) - arena.used
	if aligned_grow > unused {
		// Not enough space
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
farena_shirnk :: proc(arena: ^FArena, old_allocation: []byte, requested_size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT) -> (allocation: []byte, err: AllocatorError) {
	if len(old_allocation) == 0 {
		return {}, .Invalid_Argument
	}
	alloc_end := end(old_allocation)
	arena_end := cursor(arena.mem)[arena.used:]
	if alloc_end != arena_end {
		// Not at the end, can't shrink but return adjusted size
		allocation = old_allocation[:requested_size]
		err        = .None
		return 
	}
	// Calculate shrinkage
	aligned_original := align_pow2(len(old_allocation), MEMORY_ALIGNMENT_DEFAULT)
	aligned_new      := align_pow2(requested_size, alignment)
	arena.used       -= (aligned_original - aligned_new)
	allocation        = old_allocation[:requested_size]
	return
}
farena_reset :: proc(arena: ^FArena) {
	arena.used = 0
}
farena_rewind :: proc(arena: ^FArena, save_point: AllocatorSP) {
	assert(save_point.type_sig  == farena_allocator_proc)
	assert(save_point.slot >= 0 && save_point.slot <= arena.used)
	arena.used = save_point.slot
}
farena_save :: #force_inline proc(arena: FArena) -> AllocatorSP { return AllocatorSP { type_sig = farena_allocator_proc, slot = arena.used } }
farena_allocator_proc :: proc(input: AllocatorProc_In, output: ^AllocatorProc_Out) {
	assert(output     != nil)
	assert(input.data != nil)
	arena := transmute(^FArena) input.data
	switch input.op 
	{
	case .Alloc, .Alloc_NoZero:
		output.allocation = to_bytes(farena_push(arena, byte, input.requested_size, input.alignment))
		if input.op == .Alloc {
			zero(output.allocation)
		}
	case .Free:
		// No-op for arena
	case .Reset:
		farena_reset(arena)
	case .Grow, .Grow_NoZero:
		output.allocation, output.error = farena_grow(arena, input.old_allocation, input.requested_size, input.alignment, input.op == .Grow)
	case .Shrink:
		output.allocation, output.error = farena_shirnk(arena, input.old_allocation, input.requested_size, input.alignment)
	case .Rewind:
		farena_rewind(arena, input.save_point)
	case .SavePoint:
		output.save_point = farena_save(arena^)
	case .Query:
		output.features   = {.Alloc, .Reset, .Grow, .Shrink, .Rewind}
		output.max_alloc  = len(arena.mem) - arena.used
		output.min_alloc  = 0
		output.left       = output.max_alloc
		output.save_point = farena_save(arena^)
	}
}
when ODIN_DEBUG {
	farena_ainfo     :: #force_inline proc "contextless" (arena: ^FArena) -> AllocatorInfo  { return                           AllocatorInfo{proc_id = .FArena, data = arena} }
	farena_allocator :: #force_inline proc "contextless" (arena: ^FArena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{proc_id = .FArena, data = arena} }
}
else {
	farena_ainfo     :: #force_inline proc "contextless" (arena: ^FArena) -> AllocatorInfo  { return                           AllocatorInfo{procedure = farena_allocator_proc, data = arena} }
	farena_allocator :: #force_inline proc "contextless" (arena: ^FArena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{procedure = farena_allocator_proc, data = arena} }
}
