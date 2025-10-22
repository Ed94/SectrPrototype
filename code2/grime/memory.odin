package grime

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024

// Provides the nearest prime number value for the given capacity
closest_prime :: proc(capacity: uint) -> uint
{
	prime_table : []uint = {
		53, 97, 193, 389, 769, 1543, 3079, 6151, 12289, 24593,
		49157, 98317, 196613, 393241, 786433, 1572869, 3145739,
		6291469, 12582917, 25165843, 50331653, 100663319,
		201326611, 402653189, 805306457, 1610612741, 3221225473, 6442450941
	};
	for slot in prime_table {
		if slot >= capacity {
			return slot
		}
	}
	return prime_table[len(prime_table) - 1]
}

raw_cursor :: #force_inline proc "contextless" (ptr: rawptr) -> [^]byte { return transmute([^]byte) ptr }
ptr_cursor :: #force_inline proc "contextless" (ptr: ^$Type) -> [^]Type { return transmute([^]Type) ptr }

@(require_results) is_power_of_two :: #force_inline proc "contextless" (x: uintptr) -> bool { return (x > 0) && ((x & (x-1)) == 0) }
@(require_results)
align_pow2_uint :: #force_inline proc "contextless" (ptr, align: uint) -> uint { 
	assert_contextless(is_power_of_two(uintptr(align)))
	return ptr & ~(align-1)
}
@(require_results)
align_pow2 :: #force_inline proc "contextless" (ptr, align: int) -> int { 
	assert_contextless(is_power_of_two(uintptr(align)))
	return ptr & ~(align-1)
}

sync_mem_zero :: #force_inline proc "contextless" (data: rawptr, len: int) -> rawptr {
	mem_zero_volatile(data, len)  // Use the volatile mem_zero
	sync_fence(.Seq_Cst)          // Prevent reordering
	return data
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
slice_assert :: #force_inline proc "contextless" (s: $SliceType / []$Type) {
	assert_contextless(len(s) > 0)
	assert_contextless(s != nil)
}
slice_end      :: #force_inline proc "contextless" (s : $SliceType / []$Type) -> ^Type { return cursor(s)[len(s):] }
slice_byte_end :: #force_inline proc "contextless" (s : SliceByte)            -> ^byte { return s.data[s.len:] }

slice_zero :: #force_inline proc "contextless" (s: $SliceType / []$Type) { 
	assert_contextless(len(s) > 0)
	mem_zero(raw_data(s), size_of(Type) * len(s))
}
slice_copy :: #force_inline proc "contextless" (dst, src: $SliceType / []$Type) -> int {
	n := max(0, min(len(dst), len(src)))
	assert_contextless(n > 0)
	mem_copy(raw_data(dst), raw_data(src), n * size_of(Type))
	return n
}

slice_fill :: #force_inline proc "contextless" (s: $SliceType / []$Type, value: Type) { memory_fill(cursor(s), value, len(s)) }

@(require_results) slice_to_bytes     :: #force_inline proc "contextless" (s: []$Type) -> []byte         { return ([^]byte)(raw_data(s))[:len(s) * size_of(Type)] }
@(require_results) slice_raw          :: #force_inline proc "contextless" (s: []$Type) -> SliceRaw(Type) { return transmute(SliceRaw(Type)) s }

@(require_results) type_to_bytes :: #force_inline proc "contextless" (obj: ^$Type) -> []byte { return ([^]byte)(obj)[:size_of(Type)] }

//region Memory Math

// See: core/mem.odin, I wanted to study it an didn't like the naming.
@(require_results)
calc_padding_with_header :: proc "contextless" (pointer: uintptr, alignment: uintptr, header_size: int) -> int
{
	alignment_offset := pointer & (alignment - 1)

	initial_padding := uintptr(0)
	if alignment_offset != 0 {
			initial_padding = alignment - alignment_offset
	}

	header_space_adjustment := uintptr(header_size)
	if initial_padding < header_space_adjustment
	{
			additional_space_needed := header_space_adjustment - initial_padding
			unaligned_extra_space   := additional_space_needed & (alignment - 1)

			if unaligned_extra_space > 0 {
					initial_padding += alignment * (1 + (additional_space_needed / alignment))
			}
			else {
					initial_padding += alignment * (additional_space_needed / alignment)
			}
	}

	return int(initial_padding)
}

// Helper to get the the beginning of memory after a slice
@(require_results)
memory_after :: #force_inline proc "contextless" (s: []byte ) -> (^byte) {
	return cursor(s)[len(s):]
}
memory_after_header :: #force_inline proc "contextless" (header: ^($Type)) -> ([^]byte) {
	result := cast( [^]byte) ptr_offset( header, 1 )
	// result := cast( [^]byte) (cast( [^]Type) header)[ 1:]
	return result
}
@(require_results)
memory_align_formula :: #force_inline proc "contextless" (size, align: uint) -> uint {
	result := size + align - 1
	return result - result % align
}
// This is here just for docs
memory_misalignment :: #force_inline proc "contextless" (address, alignment: uintptr) -> uint {
	// address % alignment
	assert_contextless(is_power_of_two(alignment))
	return uint( address & (alignment - 1) )
}
// This is here just for docs
@(require_results)
memory_aign_forward :: #force_inline proc "contextless" (address, alignment : uintptr) -> uintptr
{
	assert_contextless(is_power_of_two(alignment))
	aligned_address := address
	misalignment    := transmute(uintptr) memory_misalignment( address, alignment )
	if misalignment != 0 {
		aligned_address += alignment - misalignment
	}
	return aligned_address
}

// align_up :: proc(address: uintptr, alignment: uintptr) -> uintptr {
// 	return (address + alignment - 1) & ~(alignment - 1)
// }

//endregion Memory Math

swap :: #force_inline proc "contextless" ( a, b : ^ $Type ) -> ( ^ Type, ^ Type ) { return b, a }
