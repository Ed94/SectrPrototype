
package sectr
// At least its less than C/C++ ...

import "core:mem"
import "core:mem/virtual"

Byte     :: 1
Kilobyte :: 1024 * Byte
Megabyte :: 1024 * Kilobyte
Gigabyte :: 1024 * Megabyte
Terabyte :: 1024 * Gigabyte
Petabyte :: 1024 * Terabyte
Exabyte  :: 1024 * Petabyte

kilobytes :: proc ( kb : $ integer_type ) -> integer_type {
	return kb * Kilobyte
}
megabytes :: proc ( mb : $ integer_type ) -> integer_type {
	return mb * Megabyte
}
gigabyte  :: proc ( gb : $ integer_type ) -> integer_type {
	return gb * Gigabyte
}
terabyte  :: proc ( tb : $ integer_type ) -> integer_type {
	return tb * Terabyte
}

Allocator               :: mem.Allocator
alloc                   :: mem.alloc
Arena                   :: mem.Arena
arena_allocator         :: mem.arena_allocator
arena_init              :: mem.arena_init
ptr_offset              :: mem.ptr_offset
slice_ptr               :: mem.slice_ptr
Tracking_Allocator      :: mem.Tracking_Allocator
tracking_allocator      :: mem.tracking_allocator
tracking_allocator_init :: mem.tracking_allocator_init

import rl "vendor:raylib"

Font :: rl.Font

