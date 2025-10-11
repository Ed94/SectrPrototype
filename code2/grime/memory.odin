package grime

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024

ptr_cursor :: #force_inline proc "contextless" (ptr: ^$Type) -> [^]Type { return transmute([^]Type) ptr }

align_pow2 :: proc(x: int, b: int) -> int {
    assert(b != 0)
    assert((b & (b - 1)) == 0) // Check power of 2
    return ((x + b - 1) & ~(b - 1))
}
memory_zero_explicit :: proc "contextless" (data: rawptr, len: int) -> rawptr {
	mem_zero_volatile(data, len) // Use the volatile mem_zero
	atomic_thread_fence(.Seq_Cst) // Prevent reordering
	return data
}
memory_copy :: proc "contextless" (dst, src: rawptr, len: int) -> rawptr {
	mem_copy(dst, src, len)
	return dst
}

SliceByte :: struct {
	data: [^]byte,
	len: int
}
SliceRaw  :: struct ($Type: typeid) {
	data: [^]Type,
	len:  int,
}
slice        :: #force_inline proc "contextless" (s: [^] $Type, num: $Some_Integer) -> [ ]Type { return transmute([]Type) SliceRaw(Type) { s, cast(int) num } }
slice_cursor :: #force_inline proc "contextless" (s: []$Type)                       -> [^]Type { return transmute([^]Type) raw_data(s) }
slice_assert :: #force_inline proc (s: $SliceType / []$Type) {
	assert(len(s) > 0)
	assert(s != nil)
}
slice_end :: #force_inline proc "contextless" (s : $SliceType / []$Type) -> ^Type { return & cursor(s)[len(s)] }

slice_copy :: proc "contextless" (dst, src: $SliceType / []$Type) -> int {
	n := max(0, min(len(dst), len(src)))
	if n > 0 {
		mem_copy(raw_data(dst), raw_data(src), n * size_of(Type))
	}
	return n
}

@(require_results) slice_to_bytes :: proc "contextless" (s: []$Type) -> []byte         { return ([^]byte)(raw_data(s))[:len(s) * size_of(Type)] }
@(require_results) slice_raw      :: proc "contextless" (s: []$Type) -> SliceRaw(Type) { return transmute(SliceRaw(Type)) s }

//region Allocator Interface
AllocatorOp :: enum u32 {
	Alloc_NoZero = 0, // If Alloc exist, so must No_Zero
	Alloc,
	Free,
	Reset,
	Grow_NoZero,
	Grow,
	Shrink,
	Rewind,
	SavePoint,
	Query, // Must always be implemented
}
AllocatorQueryFlag :: enum u64 {
	Alloc,
	Free,
	Reset, // Wipe the allocator's state

	Shrink,
	Grow, 
	Resize, // Supports both grow and shrink

	Rewind, // Ability to rewind to a save point (ex: arenas, stack), must also be able to save such a point

	// Actually_Resize,
	// Is_This_Yours,

	Hint_Fast_Bump,
	Hint_General_Heap,
	Hint_Per_Frame_Temporary,
	Hint_Debug_Support,
}
AllocatorQueryFlags :: bit_set[AllocatorQueryFlag; u64]
AllocatorSP :: struct {
	type_sig: AllocatorProc,
	slot:     int,
}
AllocatorProc :: #type proc (input: AllocatorProc_In, out: ^AllocatorProc_Out)
AllocatorProc_In :: struct {
	data:             rawptr,
	requested_size:   int,
	alignment:        int,
	using _ : struct #raw_union {
		old_allocation: []byte,
		save_point    : AllocatorSP,
	},
	op:               AllocatorOp,
}
AllocatorProc_Out :: struct {
	using _ : struct #raw_union {
		allocation: []byte,
		save_point: AllocatorSP,
	},
	features:         AllocatorQueryFlags,
	left:             int,
	max_alloc:        int,
	min_alloc:        int,
	continuity_break: b32,
}
AllocatorQueryInfo :: struct {
	save_point:       AllocatorSP,
	features:         AllocatorQueryFlags,
	left:             int,
	max_alloc:        int,
	min_alloc:        int,
	continuity_break: b32,
}
AllocatorInfo :: struct {
	procedure: AllocatorProc,
	data:      rawptr,
}
// #assert(size_of(AllocatorQueryInfo) == size_of(AllocatorProc_Out))

MEMORY_ALIGNMENT_DEFAULT :: 2 * size_of(rawptr)

allocator_query :: proc(ainfo := context.allocator) -> AllocatorQueryInfo {
	assert(ainfo.procedure != nil)
	out: AllocatorQueryInfo; (cast(AllocatorProc)ainfo.procedure)({data = ainfo.data, op = .Query}, transmute(^AllocatorProc_Out) & out)
	return out
}
mem_free :: proc(mem: []byte, ainfo := context.allocator) {
	assert(ainfo.procedure != nil)
	(cast(AllocatorProc)ainfo.procedure)({data = ainfo.data, op = .Free, old_allocation = mem}, & {})
}
mem_reset :: proc(ainfo := context.allocator) {
	assert(ainfo.procedure != nil)
	(cast(AllocatorProc)ainfo.procedure)({data = ainfo.data, op = .Reset}, &{})
}
mem_rewind :: proc(ainfo := context.allocator, save_point: AllocatorSP) {
	assert(ainfo.procedure != nil)
	(cast(AllocatorProc)ainfo.procedure)({data = ainfo.data, op = .Rewind, save_point = save_point}, & {})
}
mem_save_point :: proc(ainfo := context.allocator) -> AllocatorSP {
	assert(ainfo.procedure != nil)
	out: AllocatorProc_Out
	(cast(AllocatorProc)ainfo.procedure)({data = ainfo.data, op = .SavePoint}, & out)
	return out.save_point
}
mem_alloc :: proc(size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, no_zero: b32 = false, ainfo := context.allocator) -> []byte {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Alloc_NoZero : .Alloc,
		requested_size = size,
		alignment      = alignment,
	}
	output: AllocatorProc_Out
	(cast(AllocatorProc)ainfo.procedure)(input, & output)
	return output.allocation
}
mem_grow :: proc(mem: []byte, size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, no_zero: b32 = false, ainfo := context.allocator) -> []byte {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Grow_NoZero : .Grow,
		requested_size = size,
		alignment      = alignment,
		old_allocation = mem,
	}
	output: AllocatorProc_Out
	(cast(AllocatorProc)ainfo.procedure)(input, & output)
	return output.allocation
}
mem_resize :: proc(mem: []byte, size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, no_zero: b32 = false, ainfo := context.allocator) -> []byte {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = len(mem) < size ? .Shrink :  no_zero ? .Grow_NoZero : .Grow,
		requested_size = size,
		alignment      = alignment,
		old_allocation = mem,
	}
	output: AllocatorProc_Out
	(cast(AllocatorProc)ainfo.procedure)(input, & output)
	return output.allocation
}
mem_shrink :: proc(mem: []byte, size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, no_zero: b32 = false, ainfo := context.allocator) -> []byte {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = .Shrink,
		requested_size = size,
		alignment      = alignment,
		old_allocation = mem,
	}
	output: AllocatorProc_Out
	(cast(AllocatorProc)ainfo.procedure)(input, & output)
	return output.allocation
}

alloc_type  :: proc($Type: typeid, alignment: int = MEMORY_ALIGNMENT_DEFAULT, no_zero: b32 = false, ainfo := context.allocator) -> ^Type {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Alloc_NoZero : .Alloc,
		requested_size = size_of(Type),
		alignment      = alignment,
	}
	output: AllocatorProc_Out
	(cast(AllocatorProc)ainfo.procedure)(input, & output)
	return transmute(^Type) raw_data(output.allocation)
}
alloc_slice :: proc($SliceType: typeid / []$Type, num : int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, no_zero: b32 = false, ainfo := context.allocator) -> []Type {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Alloc_NoZero : .Alloc,
		requested_size = size_of(Type) * num,
		alignment      = alignment,
	}
	output: AllocatorProc_Out
	(cast(AllocatorProc)ainfo.procedure)(input, & output)
	return transmute([]Type) slice(raw_data(output.allocation), num)
}
//endregion Allocator Interface
