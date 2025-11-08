package grime

/*
This is an non-ideomatic allocator interface inspired by Odin/Jai/gb/zpl-c.

By the default the interface is still compatible Odin's context system however the user is expected to wrap the allocator struct with odin_ainfo_wrap to ideomatic procedures.
For details see: Ideomatic Compatability Wrapper (just search it)

For debug builds, we do not directly do calls to a procedure in the codebase's code paths, instead we pass a proc id that we resolve on interface calls.
This allows for hot-reload without needing to patch persistent allocator references.

To support what ideomatic odin expects in their respective codepaths, all of of sectr's codebase package mappings will wrap procedures in the formaat:
	alias_symbol :: #force_inline proc ... (..., allocator := context.allocator)      { return thidparty_symbol(..., allocator = resolve_odin_allocator(allocator)) }
	- or
	alias_symbol :: #force_inline proc ... (..., allocator := context.temp_allocator) { return thidparty_symbol(..., allocator = resolve_odin_allocator(allocator)) }
	- or
	alias_symbol :: #force_inline proc ... (...) { 
		context.allocator      = resolve_odin_allocator(context.allocator)
		context.temp_allocator = resolve_odin_allocator(context.temp_allocator)
		return thidparty_symbol(..., allocator = resolve_odin_allocator(allocator)) }
	}

	resolve_odin_allocator: Will procedue an Allocator struct with the procedure mapping resolved.
	resolve_allocator_proc: Used for the personalized interface to resolve the mapping right on call.

	It "problably" is possible to extend the original allocator interface without modifying the original source so that the distinction between the codebase's
	generic allocator interface at least converges to use the same proc signature. However since the package mapping symbols are already needing the resolve call 
	for the patchless hot-reload, the cost is just two procs for each interface.
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
	Is_Owner,
	Startup,
	Shutdown,
	Thread_Start,
	Thread_Stop,
}
AllocatorQueryFlag :: enum u64 {
	Alloc,
	Free,
	Reset, // Wipe the allocator's state

	Shrink,
	Grow, 

	Rewind, // Ability to rewind to a save point (ex: arenas, stack), must also be able to save such a point

	Actually_Resize,
	Multiple_Threads,
	Is_Owner,

	Hint_Fast_Bump,
	Hint_General_Heap,
	Hint_Per_Frame_Temporary,
	Hint_Debug_Support,
}
AllocatorQueryFlags :: bit_set[AllocatorQueryFlag; u64]

// AllocatorError :: Odin_AllocatorError
AllocatorError :: enum byte {
	None                 = 0,
	Out_Of_Memory        = 1,
	Invalid_Pointer      = 2,
	Invalid_Argument     = 3,
	Mode_Not_Implemented = 4,
	Owner                = 5,
}
AllocatorSP :: struct {
	type_sig: AllocatorProc,
	slot:     int,
}
AllocatorProc :: #type proc(input: AllocatorProc_In, out: ^AllocatorProc_Out)
AllocatorProc_In :: struct {
	data:             rawptr,
	requested_size:   int,
	alignment:        int,
	using _ : struct #raw_union {
		old_allocation: []byte,
		save_point    : AllocatorSP,
	},
	op:               AllocatorOp,
	loc:              SourceCodeLocation,
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
	data:        rawptr,
}
// #assert(size_of(AllocatorQueryInfo) == size_of(AllocatorProc_Out))

// Listing of every single allocator (used on hot-reloadable builds)
AllocatorProcID :: enum uintptr {
	FArena,
	VArena,
	Arena,
	// Pool,
	// Slab,
	// Odin_Arena,
	// Odin_VArena,
}

resolve_allocator_proc :: #force_inline proc "contextless" (procedure: $AllocatorProcType) -> AllocatorProc {
	when ODIN_DEBUG {
		switch (transmute(AllocatorProcID)procedure) {
			case .FArena:      return farena_allocator_proc
			case .VArena:      return varena_allocator_proc
			case .Arena:       return arena_allocator_proc
			// case .Pool:        return pool_allocator_proc
			// case .Slab:        return slab_allocator_proc
			// case .Odin_Arena:  return odin_arena_allocator_proc
			// case .Odin_VArena: return odin_varena_allocator_proc
		}
	}
	else {
		return transmute(AllocatorProc) procedure
	}
	panic_contextless("Unresolvable procedure")
}

resolve_odin_allocator :: #force_inline proc "contextless" (allocator: Odin_Allocator) -> Odin_Allocator {
	when ODIN_DEBUG {
		switch (transmute(AllocatorProcID)allocator.procedure) {
			case .FArena:      return { farena_odin_allocator_proc, allocator.data }
			case .VArena:      return { varena_odin_allocator_proc, allocator.data }
			case .Arena:       return { arena_odin_allocator_proc,  allocator.data }
			// case .Pool:        return nil // pool_allocator_proc
			// case .Slab:        return nil // slab_allocator_proc
			// case .Odin_Arena:  return nil // odin_arena_allocator_proc
			// case .Odin_VArena: return odin_varena_allocator_proc
		}
	}
	else {
		switch (allocator.procedure) {
			case farena_allocator_proc: return { farena_odin_allocator_proc, allocator.data }
			case varena_allocator_proc: return { varena_odin_allocator_proc, allocator.data }
			case arena_allocator_proc:  return { arena_odin_allocator_proc,  allocator.data }
		}
	}
	panic_contextless("Unresolvable procedure")
}

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

allocatorinfo :: #force_inline proc(ainfo := context.allocator) -> AllocatorInfo  { return transmute(AllocatorInfo)  ainfo }
allocator     :: #force_inline proc(ainfo: AllocatorInfo)       -> Odin_Allocator { return transmute(Odin_Allocator) ainfo }

allocator_query :: proc(ainfo := context.allocator, loc := #caller_location) -> AllocatorQueryInfo {
	assert(ainfo.procedure != nil)
	out: AllocatorQueryInfo; resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Query, loc = loc}, transmute(^AllocatorProc_Out) & out)
	return out
}
mem_free_ainfo :: proc(mem: []byte, ainfo:= context.allocator, loc := #caller_location) {
	assert(ainfo.procedure != nil)
	resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Free, old_allocation = mem, loc = loc}, & {})
}
mem_reset :: proc(ainfo := context.allocator, loc := #caller_location) {
	assert(ainfo.procedure != nil)
	resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Reset, loc = loc}, &{})
}
mem_rewind :: proc(ainfo := context.allocator, save_point: AllocatorSP, loc := #caller_location) {
	assert(ainfo.procedure != nil)
	resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .Rewind, save_point = save_point, loc = loc}, & {})
}
mem_save_point :: proc(ainfo := context.allocator, loc := #caller_location) -> AllocatorSP {
	assert(ainfo.procedure != nil)
	out: AllocatorProc_Out; resolve_allocator_proc(ainfo.procedure)({data = ainfo.data, op = .SavePoint, loc = loc}, & out)
	return out.save_point
}
mem_alloc :: proc(size: int, alignment: int = DEFAULT_ALIGNMENT, no_zero: bool = false, ainfo: $Type = context.allocator, loc := #caller_location) -> ([]byte, AllocatorError) {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Alloc_NoZero : .Alloc,
		requested_size = size,
		alignment      = alignment,
		loc            = loc,
	}
	output: AllocatorProc_Out; resolve_allocator_proc(ainfo.procedure)(input, & output)
	return output.allocation, output.error
}
mem_grow :: proc(mem: []byte, size: int, alignment: int = DEFAULT_ALIGNMENT, no_zero: bool = false, ainfo := context.allocator, loc := #caller_location) -> ([]byte, AllocatorError) {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Grow_NoZero : .Grow,
		requested_size = size,
		alignment      = alignment,
		old_allocation = mem,
		loc            = loc,
	}
	output: AllocatorProc_Out; resolve_allocator_proc(ainfo.procedure)(input, & output)
	return output.allocation, output.error
}
mem_resize :: proc(mem: []byte, size: int, alignment: int = DEFAULT_ALIGNMENT, no_zero: bool = false, ainfo := context.allocator, loc := #caller_location) -> ([]byte, AllocatorError) {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = len(mem) < size ? .Shrink :  no_zero ? .Grow_NoZero : .Grow,
		requested_size = size,
		alignment      = alignment,
		old_allocation = mem,
		loc            = loc,
	}
	output: AllocatorProc_Out; resolve_allocator_proc(ainfo.procedure)(input, & output)
	return output.allocation, output.error
}
mem_shrink :: proc(mem: []byte, size: int, alignment: int = DEFAULT_ALIGNMENT, no_zero: bool = false, ainfo := context.allocator, loc := #caller_location) -> ([]byte, AllocatorError) {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = .Shrink,
		requested_size = size,
		alignment      = alignment,
		old_allocation = mem,
		loc            = loc,
	}
	output: AllocatorProc_Out; resolve_allocator_proc(ainfo.procedure)(input, & output)
	return output.allocation, output.error
}

alloc_type  :: proc($Type: typeid, alignment: int = DEFAULT_ALIGNMENT, no_zero: bool = false, ainfo := context.allocator, loc := #caller_location) -> (^Type, AllocatorError) {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Alloc_NoZero : .Alloc,
		requested_size = size_of(Type),
		alignment      = alignment,
		loc            = loc,
	}
	output: AllocatorProc_Out; resolve_allocator_proc(ainfo.procedure)(input, & output)
	return transmute(^Type) raw_data(output.allocation), output.error
}
alloc_slice :: proc($SliceType: typeid / []$Type, num: int, alignment: int = DEFAULT_ALIGNMENT, no_zero: bool = false, ainfo := context.allocator, loc := #caller_location) -> ([]Type, AllocatorError) {
	assert(ainfo.procedure != nil)
	input := AllocatorProc_In {
		data           = ainfo.data,
		op             = no_zero ? .Alloc_NoZero : .Alloc,
		requested_size = size_of(Type) * num,
		alignment      = alignment,
		loc            = loc,
	}
	output: AllocatorProc_Out; resolve_allocator_proc(ainfo.procedure)(input, & output)
	return transmute([]Type) slice(raw_data(output.allocation), num), output.error
}
