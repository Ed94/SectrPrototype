package grime

// TODO(Ed): Review this
import "base:runtime"

// TODO(Ed): Support address sanitizer

/*
So this is a virtual memory backed arena allocator designed
to take advantage of one large contigous reserve of memory.
With the expectation that resizes with its interface will only occur using the last allocated block.
Note(Ed): Odin's mem allocator now has that feature 

All virtual address space memory for this application is managed by a virtual arena.
No other part of the program will directly touch the vitual memory interface direclty other than it.

Thus for the scope of this prototype the Virtual Arena are the only interfaces to dynamic address spaces for the runtime of the client app.
The host application as well ideally (although this may not be the case for a while)
*/

VArenaFlags :: bit_set[VArenaFlag; u32]
VArenaFlag  :: enum u32 {
	No_Large_Pages,
}

VArena :: struct {
	using vmem:  VirtualMemoryRegion,
	commit_size: int,
	commit_used: int,
	flags:       VArenaFlags,
}

// Default growth_policy is varena_default_growth_policy
varena_make :: proc(to_reserve, commit_size: int, base_address: uintptr, flags: VArenaFlags = {}
) -> (arena: ^VArena, alloc_error: AllocatorError)
{
	page_size := virtual_get_page_size()
	verify( page_size   >  size_of(VirtualMemoryRegion), "Make sure page size is not smaller than a VirtualMemoryRegion?")
	verify( to_reserve  >= page_size,   "Attempted to reserve less than a page size" )
	verify( commit_size >= page_size,   "Attempted to commit less than a page size")
	verify( to_reserve  >= commit_size, "Attempted to commit more than there is to reserve" )
	vmem : VirtualMemoryRegion
	vmem, alloc_error = virtual_reserve_and_commit( base_address, uint(to_reserve), uint(commit_size) )
	if ensure(vmem.base_address == nil || alloc_error != .None, "Failed to allocate requested virtual memory for virtual arena") {
		return
	}
	arena = transmute(^VArena) vmem.base_address;
	arena.vmem        = vmem
	arena.commit_used = align_pow2(size_of(arena), MEMORY_ALIGNMENT_DEFAULT)
	arena.flags       = flags
	return
}
varena_alloc :: proc(self: ^VArena,
	size:      int,
	alignment: int = MEMORY_ALIGNMENT_DEFAULT,
	zero_memory := true,
	location    := #caller_location
) -> (data: []byte, alloc_error: AllocatorError)
{
	verify( alignment & (alignment - 1) == 0, "Non-power of two alignment", location = location )
	page_size      := uint(virtual_get_page_size())
	requested_size := uint(size)
	if ensure(requested_size == 0, "Requested 0 size") do return nil, .Invalid_Argument
	// ensure( requested_size > page_size, "Requested less than a page size, going to allocate a page size")
	// requested_size = max(requested_size, page_size)

	// TODO(Ed): Prevent multiple threads from entering here extrusively?
	// sync.mutex_guard( & mutex )

	commit_used := uint(self.commit_used)
	reserved    := uint(self.reserved)
	commit_size := uint(self.commit_size)

	alignment_offset := uint(0)
	current_offset   := uintptr(self.reserve_start) + uintptr(self.commit_used)
	mask             := uintptr(alignment - 1)
	if (current_offset & mask != 0) do alignment_offset = uint(alignment) - uint(current_offset & mask)

	size_to_allocate, overflow_signal := add_overflow( requested_size, alignment_offset )
	if overflow_signal do return {}, .Out_Of_Memory
	to_be_used : uint
	to_be_used, overflow_signal = add_overflow( commit_used, size_to_allocate )
	if (overflow_signal || to_be_used > reserved) do return {}, .Out_Of_Memory

	header_offset        := uint( uintptr(self.reserve_start) - uintptr(self.base_address) )
	commit_left          := self.committed - commit_used - header_offset
	needs_more_committed := commit_left < size_to_allocate
	if needs_more_committed {
		profile("VArena Growing")
		next_commit_size := max(to_be_used, commit_size)
		alloc_error       = virtual_commit( self.vmem, next_commit_size )
		if alloc_error != .None do return
	}
	data_ptr    := ([^]byte)(current_offset + uintptr(alignment_offset))
	data         = slice( data_ptr, requested_size )
	commit_used += size_to_allocate
	alloc_error  = .None
	// log_backing: [Kilobyte * 16]byte; backing_slice := log_backing[:]
	// log( str_pfmt_buffer( backing_slice, "varena alloc - BASE: %p PTR: %X, SIZE: %d", cast(rawptr) self.base_address, & data[0], requested_size) )
	if zero_memory {
		// log( str_pfmt_buffer( backing_slice, "Zeroring data (Range: %p to %p)", raw_data(data), cast(rawptr) (uintptr(raw_data(data)) + uintptr(requested_size))))
		// zero( data )
		mem_zero( data_ptr, int(requested_size) )
	}
	return
}
varena_grow :: #force_inline proc(self: ^VArena, old_memory: []byte, requested_size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, should_zero := true, loc := #caller_location
) -> (data: []byte, error: AllocatorError)
{
	if ensure(old_memory == nil, "Growing without old_memory?") {
		data, error = varena_alloc(self, requested_size, alignment, should_zero, loc)
		return
	}
	if ensure(requested_size == len(old_memory), "Requested grow when none needed") {
		data = old_memory
		return
	}
	alignment_offset := uintptr(cursor(old_memory)) & uintptr(alignment - 1)
	if ensure(alignment_offset == 0 && requested_size < len(old_memory), "Requested a shrink from varena_grow") {
		data = old_memory
		return
	}
	old_memory_offset := cursor(old_memory)[len(old_memory):]
	current_offset    := self.reserve_start[self.commit_used:]
	when false {
		if old_size < page_size {
			// We're dealing with an allocation that requested less than the minimum allocated on vmem.
			// Provide them more of their actual memory
			data = slice(transmute([^]byte)old_memory, size )
			return
		}
	}
	verify( old_memory_offset == current_offset,
		"Cannot grow existing allocation in vitual arena to a larger size unless it was the last allocated" )

	if old_memory_offset != current_offset
	{
		// Give it new memory and copy the old over. Old memory is unrecoverable until clear.
		new_region : []byte
		new_region, error = varena_alloc( self, requested_size, alignment, should_zero, loc )
		if ensure(new_region == nil || error != .None, "Failed to grab new region") {
			data = old_memory
			return
		}
		copy_non_overlapping( cursor(new_region), cursor(old_memory), len(old_memory) )
		data = new_region
		// log_print_fmt("varena resize (new): old: %p %v new: %p %v", old_memory, old_size, (& data[0]), size)
		return
	}
	new_region : []byte
	new_region, error = varena_alloc( self, requested_size - len(old_memory), alignment, should_zero, loc)
	if ensure(new_region == nil || error != .None, "Failed to grab new region") {
		data = old_memory
		return
	}
	data = slice(cursor(old_memory), requested_size )
	// log_print_fmt("varena resize (expanded): old: %p %v new: %p %v", old_memory, old_size, (& data[0]), size)
	return
}
varena_shrink :: proc(self: ^VArena, memory: []byte, requested_size: int, loc := #caller_location) -> (data: []byte, error: AllocatorError) {
	if requested_size == len(memory) { return memory, .None }
	if ensure(memory == nil, "Shrinking without old_memory?") do return memory, .Invalid_Argument
	current_offset := self.reserve_start[self.commit_used:]
	shrink_amount  := len(memory) - requested_size
	if shrink_amount < 0 { return memory, .None }
	assert(cursor(memory) == current_offset)
	self.commit_used -= shrink_amount
	return memory[:requested_size], .None
}
varena_reset :: #force_inline proc(self: ^VArena) {
	// TODO(Ed): Prevent multiple threads from entering here extrusively?
	// sync.mutex_guard( & mutex )
	self.commit_used = 0
}
varena_release :: #force_inline proc(self: ^VArena) {
	// TODO(Ed): Prevent multiple threads from entering here extrusively?
	// sync.mutex_guard( & mutex )
	virtual_release( self.vmem )
	self.commit_used = 0
}
varena_rewind :: #force_inline proc(arena: ^VArena, save_point: AllocatorSP, loc := #caller_location) {
	assert_contextless(save_point.type_sig == varena_allocator_proc)
	assert_contextless(save_point.slot >= 0 && save_point.slot <= int(arena.commit_used))
	arena.commit_used = save_point.slot
}
varena_save :: #force_inline proc(arena: ^VArena) -> AllocatorSP { return AllocatorSP { type_sig = varena_allocator_proc, slot = cast(int) arena.commit_used }}

varena_allocator_proc :: proc(input: AllocatorProc_In, output: ^AllocatorProc_Out) {
	assert(output     != nil)
	assert(input.data != nil)
	arena := transmute(^VArena) input.data
	switch input.op {
	case .Alloc, .Alloc_NoZero:
		output.allocation, output.error = varena_alloc(arena, input.requested_size, input.alignment, input.op == .Alloc, input.loc)
		return
	case .Free: 
		output.error = .Mode_Not_Implemented
	case .Reset: 
		varena_reset(arena)
	case .Grow, .Grow_NoZero:
		output.allocation, output.error = varena_grow(arena, input.old_allocation, input.requested_size, input.alignment, input.op == .Grow, input.loc)
	case .Shrink:
		output.allocation, output.error = varena_shrink(arena, input.old_allocation, input.requested_size)
	case .Rewind:
		varena_rewind(arena, input.save_point)
	case .SavePoint:
		output.save_point = varena_save(arena)
	case .Query:
		output.features   = {.Alloc, .Reset, .Grow, .Shrink, .Rewind}
		output.max_alloc  = int(arena.reserved) - arena.commit_used
		output.min_alloc  = 0
		output.left       = output.max_alloc
		output.save_point = varena_save(arena)
	}
}
varena_odin_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : Odin_AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	location       : SourceCodeLocation = #caller_location
) -> (data: []byte, alloc_error: AllocatorError)
{
	arena     := transmute( ^VArena) allocator_data
	page_size := uint(virtual_get_page_size())
	switch mode {
	case .Alloc, .Alloc_Non_Zeroed:
		data, alloc_error = varena_alloc( arena, size, alignment, (mode == .Alloc), location )
		return
	case .Free:
		alloc_error = .Mode_Not_Implemented
	case .Free_All:
		varena_reset( arena )
	case .Resize, .Resize_Non_Zeroed:
		if size > old_size do varena_grow  (arena, slice(cursor(old_memory), old_size), size, alignment, (mode == .Alloc), location)
		else               do varena_shrink(arena, slice(cursor(old_memory), old_size), size, location)
	case .Query_Features:
		set := cast( ^Odin_AllocatorModeSet) old_memory
		if set != nil do (set ^) = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Query_Features}
	case .Query_Info:
		info := (^Odin_AllocatorQueryInfo)(old_memory)
		info.pointer   = transmute(rawptr) varena_save(arena).slot
		info.size      = cast(int) arena.reserved
		info.alignment = MEMORY_ALIGNMENT_DEFAULT
		return to_bytes(info), nil
	}
	return
}

varena_odin_allocator :: proc(arena: ^VArena) -> (allocator: Odin_Allocator) {
	allocator.procedure = varena_odin_allocator_proc
	allocator.data      = arena
	return
}
when ODIN_DEBUG {
	varena_ainfo     :: #force_inline proc "contextless" (arena: ^VArena) -> AllocatorInfo  { return                           AllocatorInfo{proc_id = .VArena, data = arena} }
	varena_allocator :: #force_inline proc "contextless" (arena: ^VArena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{proc_id = .VArena, data = arena} }
}
else {
	varena_ainfo     :: #force_inline proc "contextless" (arena: ^VArena) -> AllocatorInfo  { return                           AllocatorInfo{procedure = varena_allocator_proc, data = arena} }
	varena_allocator :: #force_inline proc "contextless" (arena: ^VArena) -> Odin_Allocator { return transmute(Odin_Allocator) AllocatorInfo{procedure = varena_allocator_proc, data = arena} }
}

varena_push_item :: #force_inline proc(va: ^VArena, $Type: typeid, alignment: int = MEMORY_ALIGNMENT_DEFAULT, should_zero := true, location := #caller_location
) -> (^Type, AllocatorError) {
	raw, error := varena_alloc(va, size_of(Type), alignment, should_zero, location)
	return transmute(^Type) cursor(raw), error
}

varena_push_slice :: #force_inline proc(va: ^VArena, $Type: typeid, amount: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, should_zero := true, location := #caller_location
) -> ([]Type, AllocatorError) {
	raw, error := varena_alloc(va, size_of(Type) * amount, alignment, should_zero, location)
	return slice(transmute([^]Type) cursor(raw), len(raw) / size_of(Type)), error
}
