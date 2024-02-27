package sectr
// At least its less than C/C++ ...

import "base:builtin"
	copy :: builtin.copy
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
import "core:unicode/utf8"

to_runes :: proc {
	utf8.string_to_runes,
}

to_string :: proc {
	str_builder_to_string,
}

OS_Type :: type_of(ODIN_OS)

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

get_bounds :: proc {
	box_get_bounds,
	view_get_bounds,
}

// TODO(Ed): Review
//region Doubly Linked List generic procs (verbose)

dbl_linked_list_push_back :: proc(first: ^(^ $ Type), last: ^(^ Type), new_node: ^ Type)
{
	if first == nil || first^ == nil {
			// List is empty, set first and last to the new node
			(first ^) = new_node
			(last  ^) = new_node
			new_node.next = nil
			new_node.prev = nil
	}
	else
	{
			// List is not empty, add new node to the end
			(last^).next = new_node
			new_node.prev = last^
			(last ^) = new_node
			new_node.next = nil
	}
}

//endregion
