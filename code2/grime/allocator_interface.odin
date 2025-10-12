package grime

/*
This is an non-ideomatic allocator interface inspired Odin/Jai/gb/zpl-c.

By the default the interface is still compatible Odin's context system however the user is expected to wrap the allocator struct with odin_ainfo_wrap to ideomatic procedures.
For details see: Ideomatic Compatability Wrapper (just search it)
*/

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
AllocatorError :: Odin_AllocatorError
// AllocatorError :: enum i32 {
// 	None                 = 0,
// 	Out_Of_Memory        = 1,
// 	Invalid_Pointer      = 2,
// 	Invalid_Argument     = 3,
// 	Mode_Not_Implemented = 4,
// }
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
	error:            AllocatorError,
}
AllocatorQueryInfo :: struct {
	save_point:       AllocatorSP,
	features:         AllocatorQueryFlags,
	left:             int,
	max_alloc:        int,
	min_alloc:        int,
	alignment:        i32,
}
AllocatorInfo :: struct {
	using _ : struct #raw_union {
		procedure: AllocatorProc,
		proc_id:   AllocatorProcID,
	},
	data:      rawptr,
}
// #assert(size_of(AllocatorQueryInfo) == size_of(AllocatorProc_Out))

// Listing of every single allocator (used on hot-reloadable builds)
AllocatorProcID :: enum uintptr {
	FArena,
	VArena,
	CArena,
	Pool,
	Slab,
	Odin_Arena,
	// Odin_VArena,
}

resolve_allocator_proc :: #force_inline proc(procedure: $AllocatorProcType) -> AllocatorProc {
	when ODIN_DEBUG {
		switch (transmute(AllocatorProcID)procedure) {
			case .FArena:      return farena_allocator_proc
			case .VArena:      return nil // varena_allocaotr_proc
			case .CArena:      return nil // carena_allocator_proc
			case .Pool:        return nil // pool_allocator_proc
			case .Slab:        return nil // slab_allocator_proc
			case .Odin_Arena:  return nil // odin_arena_allocator_proc
			// case .Odin_VArena: return odin_varena_allocator_proc
		}
	}
	else {
		return transmute(AllocatorProc) procedure
	}
	return nil
}

MEMORY_ALIGNMENT_DEFAULT :: 2 * size_of(rawptr)

ainfo          :: #force_inline proc(ainfo := context.allocator) -> AllocatorInfo  { return transmute(AllocatorInfo)  ainfo }
odin_allocator :: #force_inline proc(ainfo: AllocatorInfo)       -> Odin_Allocator { return transmute(Odin_Allocator) ainfo }

allocator_query :: proc(ainfo := context.allocator) -> AllocatorQueryInfo {
	assert(ainfo.procedure != nil)
	out: AllocatorQueryInfo; resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Query}, transmute(^AllocatorProc_Out) & out)
	return out
}
mem_free_ainfo :: proc(mem: []byte, ainfo: AllocatorInfo) {
	assert(ainfo.procedure != nil)
	resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Free, old_allocation = mem}, & {})
}
mem_reset :: proc(ainfo := context.allocator) {
	assert(ainfo.procedure != nil)
	resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Reset}, &{})
}
mem_rewind :: proc(ainfo := context.allocator, save_point: AllocatorSP) {
	assert(ainfo.procedure != nil)
	resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Rewind, save_point = save_point}, & {})
}
mem_save_point :: proc(ainfo := context.allocator) -> AllocatorSP {
	assert(ainfo.procedure != nil)
	out: AllocatorProc_Out
	resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .SavePoint}, & out)
	return out.save_point
}
mem_alloc :: proc(size: int, alignment: int = MEMORY_ALIGNMENT_DEFAULT, no_zero: b32 = false, ainfo : $Type = context.allocator) -> []byte {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Alloc_NoZero : .Alloc,
		requested_size = size,
		alignment      = alignment,
	}
	output: AllocatorProc_Out
	resolve_allocator_proc(ainfo.procedure)(input, & output)
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
	resolve_allocator_proc(ainfo.procedure)(input, & output)
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
	resolve_allocator_proc(ainfo.procedure)(input, & output)
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
	resolve_allocator_proc(ainfo.procedure)(input, & output)
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
	resolve_allocator_proc(ainfo.procedure)(input, & output)
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
	resolve_allocator_proc(ainfo.procedure)(input, & output)
	return transmute([]Type) slice(raw_data(output.allocation), num)
}

/*
	Idiomatic Compatability Wrapper

 Ideally we wrap all procedures that go to ideomatic odin with the following pattern:

 Usually we do the following:
```
 import "core:dynlib"
	os_lib_load :: dynlib.load_library
```
	Instead:
	os_lib_load :: #force_inline proc "contextless" (... same signature as load_library, allocator := ...) { return dynlib.load_library(..., odin_ainfo_wrap(allocator)) }
*/

odin_allocator_mode_to_allocator_op :: #force_inline proc "contextless" (mode: Odin_AllocatorMode, size_diff : int) -> AllocatorOp {
	switch mode {
		case .Alloc:             return .Alloc
		case .Alloc_Non_Zeroed:  return .Alloc_NoZero
		case .Free:              return .Free
		case .Free_All:          return .Reset
		case .Resize:            return size_diff > 0 ? .Grow        : .Shrink
		case .Resize_Non_Zeroed: return size_diff > 0 ? .Grow_NoZero : .Shrink
		case .Query_Features:    return .Query
		case .Query_Info:        return .Query
	}
	panic_contextless("Impossible path")
}

odin_allocator_wrap_proc :: proc(
	allocator_data : rawptr,
	mode           : Odin_AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	loc            := #caller_location
) -> ( data : []byte, alloc_error : Odin_AllocatorError)
{
	input := AllocatorProc_In {
		data           = (transmute(^AllocatorInfo)allocator_data).data,
		requested_size = size,
		alignment      = alignment,
		old_allocation = slice(transmute([^]byte)old_memory, old_size),
		op             = odin_allocator_mode_to_allocator_op(mode, size - old_size),
	}
	output: AllocatorProc_Out
	resolve_allocator_proc((transmute(^Odin_Allocator)allocator_data).procedure)(input, & output)

	#partial switch mode {
		case .Query_Features:
			debug_trap() // TODO(Ed): Finish this...
			return nil, nil
		case .Query_Info: 
			info := (^Odin_AllocatorQueryInfo)(old_memory)
			if info != nil && info.pointer != nil {
				info.size = output.left
				info.alignment = cast(int) (transmute(AllocatorQueryInfo)output).alignment
				return slice(transmute(^byte)info, size_of(info^) ), nil
			}
			return nil, nil
	}
	return output.allocation, cast(Odin_AllocatorError)output.error
}

odin_ainfo_giftwrap :: #force_inline proc(ainfo := context.allocator) -> Odin_Allocator { 
	@(thread_local)
	cursed_allocator_wrap_ref : Odin_Allocator
	cursed_allocator_wrap_ref = {ainfo.procedure, ainfo.data}
	return {odin_allocator_wrap_proc, & cursed_allocator_wrap_ref} 
}
