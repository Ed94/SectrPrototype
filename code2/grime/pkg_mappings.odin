package grime

import "base:builtin"
	Odin_OS_Type :: type_of(ODIN_OS)

import "base:intrinsics"
	atomic_thread_fence  :: intrinsics.atomic_thread_fence
	mem_zero_volatile    :: intrinsics.mem_zero_volatile
	// mem_zero             :: intrinsics.mem_zero
	// mem_copy             :: intrinsics.mem_copy_non_overlapping
	// mem_copy_overlapping :: intrinsics.mem_copy

mem_zero                 :: #force_inline proc "contextless" (data:     rawptr, len: int) { intrinsics.mem_zero                (data,     len) }
mem_copy_non_overlapping :: #force_inline proc "contextless" (dst, src: rawptr, len: int) { intrinsics.mem_copy_non_overlapping(dst, src, len) }
mem_copy                 :: #force_inline proc "contextless" (dst, src: rawptr, len: int) { intrinsics.mem_copy                (dst, src, len) }

import "base:runtime"
	Assertion_Failure_Proc :: runtime.Assertion_Failure_Proc
	debug_trap             :: runtime.debug_trap
	Odin_Logger            :: runtime.Logger
	LoggerLevel            :: runtime.Logger_Level
	LoggerOptions          :: runtime.Logger_Options
	Random_Generator       :: runtime.Random_Generator
	SourceCodeLocation     :: runtime.Source_Code_Location
	slice_copy_overlapping :: runtime.copy_slice

import fmt_io "core:fmt"
	// % based template formatters
	str_pfmt_out       :: fmt_io.printf
	str_pfmt_tmp       :: #force_inline proc(fmt: string, args: ..any,                                 newline := false) -> string { context.temp_allocator = resolve_odin_allocator(context.temp_allocator); return fmt_io.tprintf(fmt, ..args, newline = newline) }
	str_pfmt           :: #force_inline proc(fmt: string, args: ..any, allocator := context.allocator, newline := false) -> string { return fmt_io.aprintf(fmt, ..args, newline = newline, allocator = resolve_odin_allocator(allocator)) }
	str_pfmt_builder   :: fmt_io.sbprintf
	str_pfmt_buffer    :: fmt_io.bprintf
	str_pfmt_file_ln   :: fmt_io.fprintln
	str_tmp_from_any   :: fmt_io.tprint

import "core:log"
	Default_File_Logger_Opts   :: log.Default_File_Logger_Opts
	Logger_Full_Timestamp_Opts :: log.Full_Timestamp_Opts

import "core:mem"
	Odin_Allocator          :: mem.Allocator
	Odin_AllocatorError     :: mem.Allocator_Error
	Odin_AllocatorQueryInfo :: mem.Allocator_Query_Info
	Odin_AllocatorMode      :: mem.Allocator_Mode
	Odin_AllocatorModeSet   :: mem.Allocator_Mode_Set
	Odin_AllocatorProc      :: mem.Allocator_Proc

	align_forward_int     :: mem.align_forward_int
	align_forward_uintptr :: mem.align_backward_uintptr
	align_forward_raw     :: mem.align_forward

import "core:mem/virtual"
	VirtualProtectFlags :: virtual.Protect_Flags

import core_os "core:os"
	FS_Open_Readonly  :: core_os.O_RDONLY
	FS_Open_Writeonly :: core_os.O_WRONLY
	FS_Open_Create    :: core_os.O_CREATE
	FS_Open_Trunc     :: core_os.O_TRUNC

	OS_ERROR_NONE       :: core_os.ERROR_NONE
	OS_Handle           :: core_os.Handle
	OS_ERROR_HANDLE_EOF :: core_os.ERROR_HANDLE_EOF
	OS_INVALID_HANDLE   :: core_os.INVALID_HANDLE

	FileFlag_Create    :: core_os.O_CREATE
	FileFlag_ReadWrite :: core_os.O_RDWR
	FileTime           :: core_os.File_Time
	file_close         :: core_os.close
	file_open          :: core_os.open
	file_read          :: core_os.read
	file_remove        :: core_os.remove
	file_seek          :: core_os.seek
	file_status        :: core_os.stat
	file_truncate      :: core_os.truncate
	file_write         :: core_os.write

	file_read_entire  :: core_os.read_entire_file
	file_write_entire :: core_os.write_entire_file

import "core:strings"
	StrBuilder            :: strings.Builder
	strbuilder_from_bytes :: strings.builder_from_bytes

import "core:slice"
	slice_zero :: slice.zero

import "core:time"
	TIME_IS_SUPPORTED :: time.IS_SUPPORTED
	time_clock        :: time.clock
	time_date         :: time.date
	time_now          :: time.now

import "core:unicode/utf8"
	str_rune_count  :: utf8.rune_count_in_string
	runes_to_string :: utf8.runes_to_string
	// string_to_runes :: utf8.string_to_runes

cursor :: proc {
	raw_cursor,
	ptr_cursor,
	slice_cursor,
	string_cursor,
}

end :: proc {
	slice_end,
	slice_byte_end,
	string_end,
}

to_string :: proc {
	strings.to_string,
}

copy :: proc {
	mem_copy,
	slice_copy,
}

copy_non_overlaping :: proc {
	mem_copy_non_overlapping,
	slice_copy_overlapping,
}

to_bytes :: proc {
	slice_to_bytes,
	type_to_bytes,
}

zero :: proc {
	mem_zero,
	slice_zero,
}
