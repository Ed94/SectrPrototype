// TODO(Ed) : Move this to a grime package problably
package sectr

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:runtime"
import "core:os"

kilobytes :: #force_inline proc "contextless" ( kb : $ integer_type ) -> integer_type {
	return kb * Kilobyte
}
megabytes :: #force_inline proc "contextless" ( mb : $ integer_type ) -> integer_type {
	return mb * Megabyte
}
gigabytes  :: #force_inline proc "contextless" ( gb : $ integer_type ) -> integer_type {
	return gb * Gigabyte
}
terabytes  :: #force_inline proc "contextless" ( tb : $ integer_type ) -> integer_type {
	return tb * Terabyte
}

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
memory_after :: #force_inline proc "contextless" ( slice : []byte ) -> ( ^ byte) {
	return ptr_offset( & slice[0], len(slice) )
}

memory_after_header :: #force_inline proc "contextless" ( header : ^($ Type) ) -> ( [^]byte) {
	result := cast( [^]byte) ptr_offset( header, 1 )
	// result := cast( [^]byte) (cast( [^]Type) header)[ 1:]
	return result
}

@(require_results)
memory_align_formula :: #force_inline proc "contextless" ( size, align : uint) -> uint {
	result := size + align - 1
	return result - result % align
}

// This is here just for docs
memory_misalignment :: #force_inline proc ( address, alignment  : uintptr) -> uint {
	// address % alignment
	assert(is_power_of_two(alignment))
	return uint( address & (alignment - 1) )
}

// This is here just for docs
@(require_results)
memory_aign_forward :: #force_inline proc( address, alignment : uintptr) -> uintptr
{
	assert(is_power_of_two(alignment))

	aligned_address := address
	misalignment    := cast(uintptr) memory_misalignment( address, alignment )
	if misalignment != 0 {
		aligned_address += alignment - misalignment
	}
	return aligned_address
}

//endregion Memory Math
