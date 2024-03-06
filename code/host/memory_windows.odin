// TODO(Ed): Move this to the grime module when its made
// This was made becaause odin didn't expose the base_address param that virtual alloc allows.
package host

import "base:runtime"
import "core:mem"
import "core:mem/virtual"

import win32 "core:sys/windows"

when ODIN_OS == runtime.Odin_OS_Type.Windows {
@(private="file")
virtual_Platform_Memory_Block :: struct {
	block:      virtual.Memory_Block,
	committed:  uint,
	reserved:   uint,
}

@(private="file", require_results)
memory_align_formula :: #force_inline proc "contextless" (size, align: uint) -> uint {
	result := size + align - 1
	return result - result % align
}


@(private="file")
win32_reserve_with_base_address :: proc "contextless" (base_address : rawptr, size: uint) -> (data: []byte, err: virtual.Allocator_Error) {
	result := win32.VirtualAlloc(base_address, size, win32.MEM_RESERVE, win32.PAGE_READWRITE)
	if result == nil {
		err = .Out_Of_Memory
		return
	}
	data = ([^]byte)(result)[:size]
	return
}

@(private="file")
platform_memory_alloc :: proc "contextless" (to_commit, to_reserve: uint, base_address : rawptr) ->
	(block: ^virtual_Platform_Memory_Block, err: virtual.Allocator_Error)
{
	to_commit, to_reserve := to_commit, to_reserve
	to_reserve = max(to_commit, to_reserve)

	total_to_reserved := max(to_reserve, size_of( virtual_Platform_Memory_Block))
	to_commit = clamp(to_commit, size_of( virtual_Platform_Memory_Block), total_to_reserved)

	data := win32_reserve_with_base_address(base_address, total_to_reserved) or_return
	virtual.commit(raw_data(data), to_commit)

	block = (^virtual_Platform_Memory_Block)(raw_data(data))
	block.committed = to_commit
	block.reserved  = to_reserve
	return
}

@(private="file")
platform_memory_commit :: proc "contextless" (block: ^virtual_Platform_Memory_Block, to_commit: uint) -> (err: virtual.Allocator_Error) {
	if to_commit < block.committed {
		return nil
	}
	if to_commit > block.reserved {
		return .Out_Of_Memory
	}

	virtual.commit(block, to_commit) or_return
	block.committed = to_commit
	return nil
}

@(private="file", require_results)
memory_block_alloc :: proc(committed, reserved: uint, base_address : rawptr,
	alignment : uint = 0,
	flags     : virtual.Memory_Block_Flags = {}
)	-> (block: ^virtual.Memory_Block, err: virtual.Allocator_Error)
{
	page_size := virtual.DEFAULT_PAGE_SIZE
	assert(mem.is_power_of_two(uintptr(page_size)))

	committed := committed
	reserved  := reserved

	committed = memory_align_formula(committed, page_size)
	reserved  = memory_align_formula(reserved, page_size)
	committed = clamp(committed, 0, reserved)

	total_size     := uint(reserved + max(alignment, size_of( virtual_Platform_Memory_Block)))
	base_offset    := uintptr(max(alignment, size_of( virtual_Platform_Memory_Block)))
	protect_offset := uintptr(0)

	do_protection := false
	if .Overflow_Protection in flags { // overflow protection
		rounded_size   := reserved
		total_size     = uint(rounded_size + 2*page_size)
		base_offset    = uintptr(page_size + rounded_size - uint(reserved))
		protect_offset = uintptr(page_size + rounded_size)
		do_protection  = true
	}

	pmblock := platform_memory_alloc(0, total_size, base_address) or_return

	pmblock.block.base = ([^]byte)(pmblock)[base_offset:]
	platform_memory_commit(pmblock, uint(base_offset) + committed) or_return

	// Should be zeroed
	assert(pmblock.block.used == 0)
	assert(pmblock.block.prev == nil)	
	if do_protection {
		virtual.protect(([^]byte)(pmblock)[protect_offset:], page_size, virtual.Protect_No_Access)
	}

	pmblock.block.committed = committed
	pmblock.block.reserved  = reserved

	return &pmblock.block, nil
}

// This is the same as odin's virtual library, except I use my own allocation implementation to set the address space base.
@(require_results)
arena_init_static :: proc(arena: ^virtual.Arena, base_address : rawptr,
	reserved    : uint = virtual.DEFAULT_ARENA_STATIC_RESERVE_SIZE,
	commit_size : uint = virtual.DEFAULT_ARENA_STATIC_COMMIT_SIZE
) -> (err: virtual.Allocator_Error)
{
	arena.kind           = .Static
	arena.curr_block     = memory_block_alloc(commit_size, reserved, base_address, {}) or_return
	arena.total_used     = 0
	arena.total_reserved = arena.curr_block.reserved
	return
}
/* END OF: when ODIN_OS == runtime.Odin_OS_Type.Windows */ }
else
{
	// Fallback to regular init_static impl for other platforms for now.
	arena_init_static :: proc(arena: ^virtual.Arena, base_address : rawptr,
		reserved    : uint = virtual.DEFAULT_ARENA_STATIC_RESERVE_SIZE,
		commit_size : uint = virtual.DEFAULT_ARENA_STATIC_COMMIT_SIZE
	) -> (err: virtual.Allocator_Error) {
		return virtual.arena_init_static( arena, reserved, commit_size )
	}
}
