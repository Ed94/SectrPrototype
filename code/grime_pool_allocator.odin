/*
This is a pool allocator setup to grow incrementally via buckets.
Buckets are stored in singly-linked lists so that allocations aren't necessrily contigous.

The pool is setup with the intention to only grab single entires from the bucket,
not for a contigous array of them.
Thus the free-list only tracks the last free entries thrown out by the user,
irrespective of the bucket the originated from.
This means if there is a heavy recyling of entires in a pool
there can be a large discrepancy of memory localicty of the buckets are small.

The pool doesn't allocate any buckets on initialization unless the user specifes.
*/
package sectr

import "core:mem"

Pool :: struct {
	using header : ^PoolHeader,
}

PoolHeader :: struct {
	backing : Allocator,

	block_size      : uint,
	bucket_capacity : uint,
	alignment       : uint,

	free_list_head : ^Pool_FreeBlock,
	current_bucket : ^PoolBucket,
	bucket_list    : DLL_NodeFL( PoolBucket)
}

PoolBucket :: struct {
	blocks      : [^]byte,
	next_block  : uint,
	using nodes : DLL_NodePN( PoolBucket),
}

Pool_FreeBlock :: struct {
	next : ^Pool_FreeBlock,
}

Pool_Check_Release_Object_Validity :: true

pool_allocator :: proc ( using self : Pool ) -> (allocator : Allocator) {
	allocator.procedure = pool_allocator_proc
	allocator.data      = self.header
	return
}

pool_init :: proc (
	block_size         : uint,
	bucket_capacity    : uint,
	bucket_reserve_num : uint = 0,
	alignment          : uint = mem.DEFAULT_ALIGNMENT,
	allocator          : Allocator = context.allocator
) -> ( pool : Pool, alloc_error : AllocatorError )
{
	header_size := align_forward_int( size_of(PoolHeader), int(alignment) )

	raw_mem : rawptr
	raw_mem, alloc_error = alloc( header_size, int(alignment), allocator )
	if alloc_error != .None do return

	pool.header           = cast( ^PoolHeader) raw_mem
	pool.backing          = allocator
	pool.block_size       = block_size
	pool.bucket_capacity  = bucket_capacity
	pool.alignment        = alignment

	if bucket_reserve_num > 0 {
		alloc_error = pool_allocate_buckets( pool, bucket_reserve_num )
	}
	pool.current_bucket = pool.bucket_list.first
	return
}

pool_destroy :: proc ( using self : Pool )
{
	if bucket_list.first != nil
	{
		bucket := bucket_list.first
		for ; bucket != nil; bucket = bucket.next {
			free( bucket, backing )
		}
	}

	free( self.header, backing )
}

pool_allocate_buckets :: proc( using self : Pool, num_buckets : uint ) -> AllocatorError
{
	if num_buckets == 0 {
		return .Invalid_Argument
	}
	header_size := cast(uint) align_forward_int( size_of(PoolBucket), int(alignment))
	to_allocate := cast(int) (header_size + bucket_capacity * num_buckets)

	bucket_memory, alloc_error := alloc( to_allocate, int(alignment), backing )
	if alloc_error != .None {
		return alloc_error
	}

	next_bucket_ptr := cast( [^]byte) bucket_memory
	for index in 0 ..< num_buckets
	{
		bucket           := cast( ^PoolBucket) next_bucket_ptr
		bucket.blocks     = memory_after_header(bucket)
		bucket.next_block = 0

		if self.bucket_list.first == nil {
			self.bucket_list.first = bucket
			self.bucket_list.last  = bucket
		}
		else {
			dll_push_back( & self.bucket_list.last, bucket )
		}

		next_bucket_ptr = next_bucket_ptr[ bucket_capacity: ]
	}
	return alloc_error
}

pool_grab :: proc( using pool : Pool ) -> ( block : []byte, alloc_error : AllocatorError )
{
	alloc_error = .None

	// Check the free-list first for a block
	if free_list_head != nil {

		head := & pool.free_list_head

		// Compiler Bug? Fails to compile
		// ll_pop( head )

		last_free : ^Pool_FreeBlock = pool.free_list_head
		// last_free := ll_pop( & pool.free_list_head )

		pool.free_list_head = pool.free_list_head.next 		// ll_pop

		block = slice_ptr( cast([^]byte) last_free, int(pool.block_size) )
		return
	}

	// Compiler Fail Bug ? using current_bucket directly instead of with pool..
	// if current_bucket == nil
	if pool.current_bucket == nil
	{
		alloc_error = pool_allocate_buckets( pool, 1 )
		if alloc_error != .None {
			return
		}
		pool.current_bucket = bucket_list.first
	}

	// Compiler Bug ? (Won't work without "pool."")
	// next := uintptr(current_bucket.blocks) + uintptr(current_bucket.next_block)
	// end  := uintptr(current_bucket.blocks) + uintptr(bucket_capacity)
	next := uintptr(pool.current_bucket.blocks) + uintptr(pool.current_bucket.next_block)
	end  := uintptr(pool.current_bucket.blocks) + uintptr(pool.bucket_capacity)

	blocks_left := end - next
	if blocks_left == 0
	{
		// Compiler Bug
		// if current_bucket.next != nil {
		if pool.current_bucket.next != nil {
			// current_bucket = current_bucket.next
			pool.current_bucket = pool.current_bucket.next
		}
		else
		{
			alloc_error := pool_allocate_buckets( pool, 1 )
			if alloc_error != .None {
				return
			}
			pool.current_bucket = pool.current_bucket.next
		}
	}

	// Compiler Bug
	// block = slice_ptr( current_bucket.blocks[ current_bucket.next_block:], int(block_size) )
	// self.current_bucket.next_block += block_size
	block = slice_ptr( pool.current_bucket.blocks[ pool.current_bucket.next_block:], int(block_size) )
	pool.current_bucket.next_block += block_size
	return
}

pool_release :: proc( using self : Pool, block : []byte, loc := #caller_location )
{
	when Pool_Check_Release_Object_Validity
	{
		within_bucket := pool_validate_ownership( self, block )
		verify( within_bucket, "Attempted to release data that is not within a bucket of this pool", location = loc )
		return
	}

	// Compiler bug
	// ll_push( & self.free_list_head, cast(^Pool_FreeBlock) raw_data(block) )

	// ll_push:
	new_free_block     := cast(^Pool_FreeBlock) raw_data(block)
	new_free_block.next = self.free_list_head
	self.free_list_head = new_free_block
}

pool_reset :: proc( using pool : Pool )
{
	bucket : ^PoolBucket = bucket_list.first // TODO(Ed): Compiler bug? Build fails unless ^PoolBucket is explcitly specified.
	for ; bucket != nil; {
		bucket.next_block = 0
	}

	pool.free_list_head = nil
	pool.current_bucket = bucket_list.first
}

pool_validate_ownership :: proc( using self : Pool, block : [] byte ) -> b32
{
	within_bucket := b32(false)

	// Compiler Bug : Same as pool_reset
	bucket        : ^PoolBucket = bucket_list.first
	for ; bucket != nil; bucket = bucket.next
	{
		start         := uintptr( bucket.blocks )
		end           := start + uintptr(bucket_capacity)
		block_address := uintptr(raw_data(block))

		if start <= block_address && block_address < end {
			within_bucket = true
			break
		}
	}

	return within_bucket
}

// This interface should really not be used for a pool allocator... But fk it its here.
// TODO(Ed): Implement this eventaully..
pool_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	loc            := #caller_location
) -> ([]byte, AllocatorError)
{
	switch mode
	{
		case .Alloc, .Alloc_Non_Zeroed:
			fallthrough
		case .Free:
			fallthrough
		case .Free_All:
			fallthrough
		case .Resize, .Resize_Non_Zeroed:
			fallthrough
		case .Query_Features:
			fallthrough
		case .Query_Info:
			fallthrough
	}
	return nil, AllocatorError.Mode_Not_Implemented
}
