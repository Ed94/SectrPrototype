package grime

/*
Arena (Chained Virtual Areans):
*/

ArenaFlags :: bit_set[ArenaFlag; u32]
ArenaFlag  :: enum u32 {
	No_Large_Pages,
	No_Chaining,
}
Arena :: struct {
	backing:  ^VArena,
	prev:     ^Arena,
	current:  ^Arena,
	base_pos: int,
	pos:      int,
	flags:    ArenaFlags,
}

arena_make :: proc(reserve_size : int = Mega * 64, commit_size : int = Mega * 64, base_addr: uintptr = 0, flags: ArenaFlags = {}) -> ^Arena {
	header_size    := align_pow2(size_of(Arena), DEFAULT_ALIGNMENT)
	current, error := varena_make(reserve_size, commit_size, base_addr, transmute(VArenaFlags) flags)
	assert(error   == .None)
	arena: ^Arena; arena, error = varena_push_item(current, Arena, 1)
	assert(error == .None)
	arena^ = Arena {
		backing  = current,
		prev     = nil,
		current  = arena,
		base_pos = 0,
		pos      = header_size,
		flags    = flags,
	}
	return arena
}
arena_alloc :: proc(arena: ^Arena, size: int, alignment: int = DEFAULT_ALIGNMENT, should_zero := true) -> []byte {
	assert(arena != nil)
	active         := arena.current
	size_requested := size
	size_aligned   := align_pow2(size_requested, alignment)
	pos_pre        := active.pos
	pos_pst        := pos_pre + size_aligned
	reserved       := int(active.backing.reserved)
	should_chain   := (.No_Chaining not_in arena.flags) && (reserved < pos_pst)	
	if should_chain {
		new_arena := arena_make(reserved, active.backing.commit_size, 0, transmute(ArenaFlags) active.backing.flags)
		new_arena.base_pos = active.base_pos + reserved
		sll_stack_push_n(& arena.current, & new_arena, & new_arena.prev)
		new_arena.prev = active
		active = arena.current
	}
	result_ptr     := transmute([^]byte) (uintptr(active) + uintptr(pos_pre))
	vresult, error := varena_alloc(active.backing, size_aligned, alignment, should_zero)
	assert(error == .None)
	assert(cursor(vresult) == result_ptr)
	active.pos = pos_pst
	return slice(result_ptr, size)
}
arena_grow :: proc(arena: ^Arena, old_allocation: []byte, requested_size: int, alignment: int = DEFAULT_ALIGNMENT, zero_memory := true) -> (allocation: []byte) {
	active := arena.current
	if len(old_allocation) == 0 { allocation = {}; return }
	alloc_end := end(old_allocation)
	arena_end := transmute([^]byte) (uintptr(active) + uintptr(active.pos))
	if alloc_end == arena_end
	{
		// Can grow in place
		grow_amount  := requested_size - len(old_allocation)
		aligned_grow := align_pow2(grow_amount, alignment)
		if active.pos + aligned_grow <= cast(int) active.backing.reserved
		{
			vresult, error := varena_alloc(active.backing, aligned_grow, alignment, zero_memory);
			assert(error == .None)
			if len(vresult) > 0 {
				active.pos += aligned_grow
				allocation = slice(cursor(old_allocation), requested_size)
				return
			}
		}
	}
	// Can't grow in place, allocate new
	allocation = arena_alloc(arena, requested_size, alignment, false)
	if len(allocation) == 0 { allocation = {}; return }
	copy(allocation, old_allocation)
	zero(cursor(allocation)[len(old_allocation):], (requested_size - len(old_allocation)) * int(zero_memory))
	return
}
arena_release :: proc(arena: ^Arena) {
	assert(arena != nil)
	curr := arena.current
	for curr != nil {
		prev := curr.prev
		varena_release(curr.backing)
		curr = prev
	}
}
arena_reset :: proc(arena: ^Arena) {
	arena_rewind(arena, AllocatorSP { type_sig = arena_allocator_proc, slot = 0 })
}
arena_rewind :: proc(arena: ^Arena, save_point: AllocatorSP) {
	assert(arena != nil)
	assert(save_point.type_sig == arena_allocator_proc)
	header_size := align_pow2(size_of(Arena), DEFAULT_ALIGNMENT)
	curr        := arena.current
	big_pos     := max(header_size, save_point.slot)
	// Release arenas that are beyond the save point
	for curr.base_pos >= big_pos {
		prev := curr.prev
		varena_release(curr.backing)
		curr = prev
	}
	arena.current = curr
	new_pos      := big_pos - curr.base_pos; assert(new_pos <= curr.pos)
	curr.pos = new_pos
	varena_rewind(curr.backing, { type_sig = varena_allocator_proc, slot = curr.pos + size_of(VArena) })
}
arena_save :: #force_inline proc(arena: ^Arena) -> AllocatorSP { return { type_sig = arena_allocator_proc, slot = arena.base_pos + arena.current.pos } }

arena_allocator_proc :: proc(input: AllocatorProc_In, output: ^AllocatorProc_Out) {
	panic("not implemented")
}
arena_odin_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : Odin_AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	location       : SourceCodeLocation = #caller_location
) -> (data: []byte, alloc_error: AllocatorError)
{
	panic("not implemented")
}
when ODIN_DEBUG {
	arena_ainfo     :: #force_inline proc "contextless" (arena: ^Arena) -> AllocatorInfo  { return                           AllocatorInfo{proc_id = .Arena, data = arena} }
	arena_allocator :: #force_inline proc "contextless" (arena: ^Arena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{proc_id = .Arena, data = arena} }
}
else {
	arena_ainfo     :: #force_inline proc "contextless" (arena: ^Arena) -> AllocatorInfo  { return                           AllocatorInfo{procedure = arena_allocator_proc, data = arena} }
	arena_allocator :: #force_inline proc "contextless" (arena: ^Arena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{procedure = arena_allocator_proc, data = arena} }
}

arena_push_item :: proc()
{

}
arena_push_array :: proc()
{

}
