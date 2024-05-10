package sectr

import "core:mem"
import "core:slice"

//region Fixed Stack

StackFixed :: struct ( $ Type : typeid, $ Size : u32 ) {
	idx   : u32,
	items : [ Size ] Type,
}

stack_push :: #force_inline proc( using stack : ^ StackFixed( $ Type, $ Size ), value : Type ) {
	verify( idx < len( items ), "Attempted to push on a full stack" )

	items[ idx ] = value
	idx += 1
}

stack_pop :: #force_inline proc( using stack : ^StackFixed( $ Type, $ Size ) ) {
	verify( idx > 0, "Attempted to pop an empty stack" )

	idx -= 1
	if idx == 0 {
		items[idx] = {}
	}
}

stack_peek_ref :: #force_inline proc "contextless" ( using stack : ^StackFixed( $ Type, $ Size ) ) -> ( ^Type) {
	last_idx := max( 0, idx - 1 ) if idx > 0 else 0
	last     := & items[last_idx]
	return last
}

stack_peek :: #force_inline proc "contextless" ( using stack : ^StackFixed( $ Type, $ Size ) ) -> Type {
	last := max( 0, idx - 1 ) if idx > 0 else 0
	return items[last]
}

//endregion Fixed Stack

//region Stack Allocator

// TODO(Ed) : This is untested and problably filled with bugs.
/* Growing Stack allocator
	This implementation can support growing if the backing allocator supports
	it without fragmenting the backing allocator.

	Each block in the stack is tracked with a doubly-linked list to have debug stats.
	(It could be removed for non-debug builds)
*/

StackAllocatorBase :: struct {
	backing : Allocator,

	using links : DLL_NodeFL(StackAllocatorHeader),
	peak_used : int,
	size      : int,
	data      : [^]byte,
}

StackAllocator :: struct {
	using base : ^StackAllocatorBase,
}

StackAllocatorHeader :: struct {
	using links : DLL_NodePN(StackAllocatorHeader),
	block_size : int,
	padding    : int,
}

stack_allocator :: proc( using self : StackAllocator ) -> ( allocator : Allocator ) {
	allocator.procedure = stack_allocator_proc
	allocator.data      = self.base
	return
}

stack_allocator_init :: proc( size : int, allocator := context.allocator ) -> ( stack : StackAllocator, alloc_error : AllocatorError )
{
	header_size := size_of(StackAllocatorBase)

	raw_mem : rawptr
	raw_mem, alloc_error = alloc( header_size + size, mem.DEFAULT_ALIGNMENT )
	if alloc_error != AllocatorError.None do return

	stack.base = cast( ^StackAllocatorBase) raw_mem
	stack.size = size
	stack.data = cast( [^]byte) (cast( [^]StackAllocatorBase) stack.base)[ 1:]

	stack.top    = cast(^StackAllocatorHeader) stack.data
	stack.bottom = stack.top
	return
}

stack_allocator_destroy :: proc( using self : StackAllocator )
{
	free( self.base, backing )
}

stack_allocator_init_via_memory :: proc( memory : []byte ) -> ( stack : StackAllocator )
{
	header_size := size_of(StackAllocatorBase)

	if len(memory) < (header_size + Kilobyte) {
		verify(false, "Assigning a stack allocator less than a kilobyte of space")
		return
	}

	stack.base = cast( ^StackAllocatorBase) & memory[0]
	stack.size = len(memory) - header_size
	stack.data = cast( [^]byte ) (cast( [^]StackAllocatorBase) stack.base)[ 1:]

	stack.top    = cast( ^StackAllocatorHeader) stack.data
	stack.bottom = stack.top
	return
}

stack_allocator_push :: proc( using self : StackAllocator, block_size, alignment : int, zero_memory : bool ) -> ( []byte, AllocatorError )
{
	// TODO(Ed): Make sure first push is fine.
	verify( block_size > Kilobyte, "Attempted to push onto the stack less than a Kilobyte")
	top_block_ptr := memory_after_header( top )

	theoretical_size := cast(int) (uintptr(top_block_ptr) + uintptr(block_size) - uintptr(bottom))
	if theoretical_size > size {
		// TODO(Ed) : Check if backing allocator supports resize, if it does attempt to grow.
		return nil, .Out_Of_Memory
	}

	top_block_slice := slice_ptr( top_block_ptr, top.block_size )
	next_spot       := uintptr( top_block_ptr) + uintptr(top.block_size)

	header_offset_pad := calc_padding_with_header( uintptr(next_spot), uintptr(alignment), size_of(StackAllocatorHeader) )
	header            := cast( ^StackAllocatorHeader) (next_spot + uintptr(header_offset_pad) - uintptr(size_of( StackAllocatorHeader)))
	header.padding     = header_offset_pad
	header.prev        = last
	header.block_size  = block_size

	curr_block_ptr := memory_after_header( header )
	curr_block     := slice_ptr( curr_block_ptr, block_size )

	curr_used := cast(int) (uintptr(curr_block_ptr) + uintptr(block_size) - uintptr(self.top))
	self.peak_used += max( peak_used, curr_used )

	dll_push_back( & base.links.last, header )

	if zero_memory {
		slice.zero( curr_block )
	}

	return curr_block, .None
}

stack_allocator_resize_top :: proc( using self : StackAllocator, new_block_size, alignment : int, zero_memory : bool ) -> AllocatorError
{
	verify( new_block_size > Kilobyte, "Attempted to resize the last pushed on the stack to less than a Kilobyte")
	top_block_ptr := memory_after_header( top )

	theoretical_size := cast(int) (uintptr(top_block_ptr) + uintptr(top.block_size) - uintptr(bottom))
	if theoretical_size > size {
		// TODO(Ed) : Check if backing allocator supports resize, if it does attempt to grow.
		return .Out_Of_Memory
	}

	if zero_memory && new_block_size > top.block_size {
		added_ptr   := top_block_ptr[ top.block_size:]
		added_slice := slice_ptr( added_ptr, new_block_size - top.block_size )
		slice.zero( added_slice )
	}

	top.block_size = new_block_size
	return .None
}

stack_allocator_pop :: proc( using self : StackAllocator ) {
	base.links.top      = top.prev
	base.links.top.next = nil
}

stack_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : AllocatorMode,
	block_size     : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	location       : SourceCodeLocation = #caller_location
) -> ([]byte, AllocatorError)
{
	stack := StackAllocator { cast( ^StackAllocatorBase) allocator_data }

	if stack.data == nil {
		return nil, AllocatorError.Invalid_Argument
	}

	switch mode
	{
		case .Alloc, .Alloc_Non_Zeroed:
		{
			return stack_allocator_push( stack, block_size, alignment, mode == .Alloc )
		}
		case .Free:
		{
			if old_memory == nil {
				return nil, .None
			}

			start     := uintptr(stack.data)
			end       := start + uintptr(block_size)
			curr_addr := uintptr(old_memory)

			verify( start <= curr_addr && curr_addr < end, "Out of bounds memory address passed to stack allocator (free)" )

			block_ptr := memory_after_header( stack.last )

			if curr_addr >= start + uintptr(block_ptr) {
				return nil, .None
			}

			dll_pop_back( & stack.last )
		}
		case .Free_All:
			// TODO(Ed) : Review that we don't have any header issues with the reset.
			stack.bottom         = stack.top
			stack.top.next       = nil
			stack.top.block_size = 0

		case .Resize, .Resize_Non_Zeroed:
		{
			// Check if old_memory is at the first on the stack, if it is, just grow its size
			// Otherwise, log that the user cannot resize stack items that are not at the top of the stack allocated.
			if old_memory == nil {
				return stack_allocator_push(stack, block_size, alignment, mode == .Resize )
			}
			if block_size == 0 {
				return nil, .None
			}

			start     := uintptr(stack.data)
			end       := start + uintptr(block_size)
			curr_addr := uintptr(old_memory)

			verify( start <= curr_addr && curr_addr < end, "Out of bounds memory address passed to stack allocator (resize)" )

			block_ptr := memory_after_header( stack.top )
			if block_ptr != old_memory {
				ensure( false, "Attempted to reszie a block of memory on the stack other than top most" )
				return nil, .None
			}

			if old_size == block_size {
				return byte_slice( old_memory, block_size ), .None
			}

			stack_allocator_resize_top( stack, block_size, alignment, mode == .Resize )
			return byte_slice( block_ptr, block_size ), .None
		}
		case .Query_Features:
		{
			feature_flags := ( ^AllocatorModeSet)(old_memory)
			if feature_flags != nil {
				(feature_flags ^) = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Resize, .Resize_Non_Zeroed, .Query_Features}
			}
			return nil, .None
		}
		case .Query_Info:
		{
			return nil, .Mode_Not_Implemented
		}
	}

	return nil, .None
}

//endregion Stack Allocator
