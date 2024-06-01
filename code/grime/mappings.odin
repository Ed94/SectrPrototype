package grime

//#region("base")

import "base:builtin"
	copy :: builtin.copy

import "base:intrinsics"
	mem_zero       :: intrinsics.mem_zero
	ptr_sub        :: intrinsics.ptr_sub
	type_has_field :: intrinsics.type_has_field
	type_elem_type :: intrinsics.type_elem_type

import "base:runtime"
	Byte               :: runtime.Byte
	Kilobyte           :: runtime.Kilobyte
	Megabyte           :: runtime.Megabyte
	Gigabyte           :: runtime.Gigabyte
	Terabyte           :: runtime.Terabyte
	Petabyte           :: runtime.Petabyte
	Exabyte            :: runtime.Exabyte
	resize_non_zeroed  :: runtime.non_zero_mem_resize
	SourceCodeLocation :: runtime.Source_Code_Location

//#endregion("base")

//#region("core")

import c "core:c/libc"
	mem_fmt :: c.memset

import "core:dynlib"

import "core:hash"
	crc32 :: hash.crc32

import "core:hash/xxhash"
	xxh32 :: xxhash.XXH32

import fmt_io "core:fmt"
	str_fmt_out      :: fmt_io.printf
	str_fmt_tmp      :: fmt_io.tprintf
	str_fmt          :: fmt_io.aprintf // Decided to make aprintf the default. (It will always be the default allocator)
	str_fmt_builder  :: fmt_io.sbprintf
	str_fmt_buffer   :: fmt_io.bprintf
	str_to_file_ln   :: fmt_io.fprintln
	str_tmp_from_any :: fmt_io.tprint

import "core:math"

import "core:mem"
	align_forward_int       :: mem.align_forward_int
	align_forward_uint      :: mem.align_forward_uint
	align_forward_uintptr   :: mem.align_forward_uintptr
	Allocator               :: mem.Allocator
	AllocatorError          :: mem.Allocator_Error
	AllocatorMode           :: mem.Allocator_Mode
	AllocatorModeSet        :: mem.Allocator_Mode_Set
	alloc                   :: mem.alloc
	alloc_bytes             :: mem.alloc_bytes
	alloc_bytes_non_zeroed  :: mem.alloc_bytes_non_zeroed
	Arena                   :: mem.Arena
	arena_allocator         :: mem.arena_allocator
	arena_init              :: mem.arena_init
	byte_slice              :: mem.byte_slice
	copy_non_overlapping    :: mem.copy_non_overlapping
	free                    :: mem.free
	is_power_of_two_uintptr :: mem.is_power_of_two
	ptr_offset              :: mem.ptr_offset
	resize                  :: mem.resize
	slice_ptr               :: mem.slice_ptr
	TrackingAllocator       :: mem.Tracking_Allocator
	tracking_allocator      :: mem.tracking_allocator
	tracking_allocator_init :: mem.tracking_allocator_init

import "core:mem/virtual"
	VirtualProtectFlags :: virtual.Protect_Flags

// TODO(Ed): Use os2 when the package is considered complete.
import "core:os"
	FileFlag_Create    :: os.O_CREATE
	FileFlag_ReadWrite :: os.O_RDWR
	FileTime           :: os.File_Time
	file_close         :: os.close
	file_open          :: os.open
	file_read          :: os.read
	file_remove        :: os.remove
	file_seek          :: os.seek
	file_status        :: os.stat
	file_write         :: os.write

import "core:path/filepath"
	file_name_from_path :: filepath.short_stem

import "core:strconv"
	parse_f32  :: strconv.parse_f32
	parse_u64  :: strconv.parse_u64
	parse_uint :: strconv.parse_uint

import str "core:strings"
	StringBuilder          :: str.Builder
	str_builder_from_bytes :: str.builder_from_bytes
	str_builder_init       :: str.builder_init
	str_builder_to_writer  :: str.to_writer
	str_builder_to_string  :: str.to_string

import "core:time"
	Duration         :: time.Duration
	duration_seconds :: time.duration_seconds
	duration_ms      :: time.duration_milliseconds
	thread_sleep     :: time.sleep

import "core:unicode"
	is_white_space  :: unicode.is_white_space

import "core:unicode/utf8"
	str_rune_count  :: utf8.rune_count_in_string
	runes_to_string :: utf8.runes_to_string
	// string_to_runes :: utf8.string_to_runes

//#endregion("core")

import "thirdparty:backtrace"
	StackTraceData   :: backtrace.Trace_Const
	stacktrace       :: backtrace.trace
	stacktrace_lines :: backtrace.lines

//#region("Proc overload mappings")

array_append :: proc {
	array_append_value,
	array_append_array,
	array_append_slice,
}

array_append_at :: proc {
	array_append_at_slice,
	array_append_at_value,
}

is_power_of_two :: proc {
	is_power_of_two_u32,
	is_power_of_two_uintptr,
}

make :: proc {
	array_init,
	hmap_chained_init,
	hmap_zpl_init,

	// Usual
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
	make_multi_pointer,
}

push :: proc {
	stack_push,
}

to_runes :: proc {
	string_to_runes,
}

to_string :: proc {
	runes_to_string,
	str_builder_to_string,
}

to_writer :: proc {
	str_builder_to_writer,
}

//#endregion("Proc overload mappings")
