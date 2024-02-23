
package sectr
// At least its less than C/C++ ...

import "base:builtin"
import "base:runtime"
import "core:hash"
import "core:mem"
import "core:mem/virtual"
import "core:os"
import "core:path/filepath"

import c "core:c/libc"

Byte     :: 1
Kilobyte :: 1024 * Byte
Megabyte :: 1024 * Kilobyte
Gigabyte :: 1024 * Megabyte
Terabyte :: 1024 * Gigabyte
Petabyte :: 1024 * Terabyte
Exabyte  :: 1024 * Petabyte

kilobytes :: proc( kb : $ integer_type ) -> integer_type {
	return kb * Kilobyte
}
megabytes :: proc( mb : $ integer_type ) -> integer_type {
	return mb * Megabyte
}
gigabyte  :: proc( gb : $ integer_type ) -> integer_type {
	return gb * Gigabyte
}
terabyte  :: proc( tb : $ integer_type ) -> integer_type {
	return tb * Terabyte
}

copy                    :: builtin.copy
crc32                   :: hash.crc32
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
Tracking_Allocator      :: mem.Tracking_Allocator
tracking_allocator      :: mem.tracking_allocator
tracking_allocator_init :: mem.tracking_allocator_init
file_name_from_path     :: filepath.short_stem
OS_Type                 :: type_of(ODIN_OS)

get_bounds :: proc {
	box_get_bounds,
	view_get_bounds,
}

//region Stack - Basic fixed-size stack container
Stack :: struct ( $ Type : typeid, $ Size : i32 ) {
	idx   : i32,
	items : [ Size ] Type,
}

stack_push :: proc( stack : ^ $ StackType / Stack( $ Type, $ Size ), value : Type ) {
	using stack
	verify( idx < len( items ), "Attempted to push on a full stack" )

	items[ idx ] = value
	idx += 1
}

stack_pop :: proc( stack : ^ $ StackType / Stack( $ Type, $ Size ) ) {
	using stack
	verify( idx > 0, "Attempted to pop an empty stack" )

	idx -= 1
	if idx == 0 {
		items[idx] = {}
	}
}

stack_peek :: proc( stack : ^ Stack( $ Type, $ Size ) ) -> ^ Type {
	using stack
	return & items[idx]
}
//endregion Stack


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






// TODO(Ed) : This is extremely jank, Raylib requires a 'heap' allocator with the way it works.
// We do not have persistent segmented in such a way for this. Eventually we might just want to segment vmem and just shove a heap allocator on a segment of it.

when false {
RL_MALLOC :: proc "c" ( size : c.size_t ) -> rawptr
{
	allocator : Allocator
	when Use_TrackingAllocator {
		allocator = Allocator {
			data      = & memory.persistent.tracker,
			procedure = mem.tracking_allocator_proc,
		}
	}
	else {
		allocator = Allocator {
			data      = & memory.persistent,
			procedure = mem.arena_allocator_proc,
		}
	}
	result, error_code := allocator.procedure( allocator.data, mem.Allocator_Mode.Alloc_Non_Zeroed, cast(int) size, mem.DEFAULT_ALIGNMENT, nil, 0, auto_cast {} )
	if error_code != AllocatorError.None {
		runtime.debug_trap()
		os.exit( -1 )
	}
	return raw_data(result)
}

RL_CALLOC :: proc "c" ( count : c.size_t, size : c.size_t ) -> rawptr
{
	allocator : Allocator
	when Use_TrackingAllocator {
		allocator = Allocator {
			data      = & memory.persistent.tracker,
			procedure = mem.tracking_allocator_proc,
		}
	}
	else {
		allocator = Allocator {
			data      = & memory.persistent,
			procedure = mem.arena_allocator_proc,
		}
	}
	result, error_code := allocator.procedure( allocator.data, mem.Allocator_Mode.Alloc, cast(int) size, mem.DEFAULT_ALIGNMENT, nil, 0, auto_cast {} )
	if error_code != AllocatorError.None {
		runtime.debug_trap()
		os.exit( -1 )
	}
	return raw_data(result)
}

RL_REALLOC :: proc "c" ( block : rawptr, size : c.size_t ) -> rawptr
{
	allocator : Allocator
	when Use_TrackingAllocator {
		allocator = Allocator {
			data      = & memory.persistent.tracker,
			procedure = mem.tracking_allocator_proc,
		}
	}
	else {
		allocator = Allocator {
			data      = & memory.persistent,
			procedure = mem.arena_allocator_proc,
		}
	}
	result, error_code := allocator.procedure( allocator.data, mem.Allocator_Mode.Resize_Non_Zeroed, cast(int) size, mem.DEFAULT_ALIGNMENT, block, 0, auto_cast {} )
	if error_code != AllocatorError.None {
		runtime.debug_trap()
		os.exit( -1 )
	}
	return raw_data(result)
}

RL_FREE :: proc "c" ( block : rawptr )
{
	allocator : Allocator
	when Use_TrackingAllocator {
		allocator = Allocator {
			data      = & memory.persistent.tracker,
			procedure = mem.tracking_allocator_proc,
		}
	}
	else {
		allocator = Allocator {
			data      = & memory.persistent,
			procedure = mem.arena_allocator_proc,
		}
	}
	result, error_code := allocator.procedure( allocator.data, mem.Allocator_Mode.Free, 0, 0, block, 0, auto_cast {} )
	if error_code != AllocatorError.None {
		runtime.debug_trap()
		os.exit( -1 )
	}
}
}