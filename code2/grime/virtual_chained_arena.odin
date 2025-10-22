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

arena_make :: proc(reserve_size : uint = Mega * 64, commit_size : uint = Mega * 64, base_addr: uintptr = 0, flags: ArenaFlags = {}) -> ^Arena {
	header_size    := align_pow2(size_of(Arena), MEMORY_ALIGNMENT_DEFAULT)
	current, error := varena_make(reserve_size, commit_size, base_addr, transmute(VArenaFlags) flags)
	assert(error   == .None)
	assert(current != nil)
	arena: []Arena; arena, error = varena_push(current, Arena, 1)
	assert(error == .None)
	assert(len(arena) > 0)
	arena[0] = Arena {
		backing  = current,
		prev     = nil,
		current  = & arena[0],
		base_pos = 0,
		pos      = header_size,
		flags    = flags,
	}
	return & arena[0]
}
arena_push :: proc(arena: ^Arena, $Type: typeid, amount: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT) -> []Type {
	assert(arena != nil)
	active         := arena.current
	size_requested := amount * size_of(Type)
	size_aligned   := align_pow2(size_requested, alignment)
	pos_pre        := active.pos
	pos_pst        := pos_pre + size_aligned
	should_chain   := (.No_Chaining not_in arena.flags) && (active.backing.reserve < pos_pst)	
	if should_chain {
		new_arena := arena_make(active.backing.reserve, active.backing.commit_size, 0, transmute(ArenaFlags) active.backing.flags)
		new_arena.base_pos = active.base_pos + active.backing.reserve
		sll_stack_push_n(& arena.current, & new_arena, & new_arena.prev)
		new_arena.prev = active
		active = arena.current
	}
	result_ptr := transmute([^]byte) (uintptr(active) + uintptr(pos_pre))
	vresult    := varena_push(active.backing, byte, size_aligned, alignment)
	slice_assert(vresult)
	assert(raw_data(vresult) == result_ptr)
	active.pos = pos_pst
	return slice(result_ptr, amount)
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
	header_size := align_pow2(size_of(Arena), MEMORY_ALIGNMENT_DEFAULT)
	curr        := arena.current
	big_pos     := max(header_size, save_point.slot)
	// Release arenas that are beyond the save point
	for curr.base_pos >= big_pos {
		prev := curr.prev
		varena_release(curr.backing)
		curr = prev
	}
	arena.current = curr
	new_pos      := big_pos - curr.base_pos
	assert(new_pos <= curr.pos)
	curr.pos = new_pos
	varena_rewind(curr.backing, { type_sig = varena_allocator_proc, slot = curr.pos + size_of(VArena) })
}
arena_save :: #force_inline proc(arena: ^Arena) -> AllocatorSP { return { type_sig = arena_allocator_proc, slot = arena.base_pos + arena.current.pos } }



arena_allocator_proc :: proc(input: AllocatorProc_In, output: ^AllocatorProc_Out) {
	
}
