package sectr
// At least its less than C/C++ ...

import "base:builtin"
	copy :: builtin.copy
import "base:intrinsics"
	type_has_field :: intrinsics.type_has_field
	type_elem_type :: intrinsics.type_elem_type
import "base:runtime"
	Byte     :: runtime.Byte
	Kilobyte :: runtime.Kilobyte
	Megabyte :: runtime.Megabyte
	Gigabyte :: runtime.Gigabyte
	Terabyte :: runtime.Terabyte
	Petabyte :: runtime.Petabyte
	Exabyte  :: runtime.Exabyte
import c "core:c/libc"
import "core:dynlib"
import "core:hash"
	crc32 :: hash.crc32
import fmt_io "core:fmt"
	str_fmt          :: fmt_io.printf
	str_fmt_tmp      :: fmt_io.tprintf
	str_fmt_builder  :: fmt_io.sbprintf
	str_fmt_buffer   :: fmt_io.bprintf
	str_to_file_ln   :: fmt_io.fprintln
	str_tmp_from_any :: fmt_io.tprint
import "core:mem"
	Allocator               :: mem.Allocator
	AllocatorError          :: mem.Allocator_Error
	alloc                   :: mem.alloc
	alloc_bytes             :: mem.alloc_bytes
	Arena                   :: mem.Arena
	arena_allocator         :: mem.arena_allocator
	arena_init              :: mem.arena_init
	free                    :: mem.free
	ptr_offset              :: mem.ptr_offset
	slice_ptr               :: mem.slice_ptr
	TrackingAllocator       :: mem.Tracking_Allocator
	tracking_allocator      :: mem.tracking_allocator
	tracking_allocator_init :: mem.tracking_allocator_init
import "core:mem/virtual"
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
import str "core:strings"
	str_builder_to_string  :: str.to_string
import "core:time"
	Duration :: time.Duration
import "core:unicode"
	is_white_space  :: unicode.is_white_space
import "core:unicode/utf8"
	runes_to_string :: utf8.runes_to_string
	string_to_runes :: utf8.string_to_runes

OS_Type :: type_of(ODIN_OS)

// Alias Tables

get_bounds :: proc {
	box_get_bounds,
	view_get_bounds,
}

is_power_of_two :: proc {
	is_power_of_two_u32,
}

to_runes :: proc {
	string_to_runes,
}

to_string :: proc {
	runes_to_string,
	str_builder_to_string,
}
