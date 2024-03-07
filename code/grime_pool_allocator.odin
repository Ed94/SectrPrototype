/*
This is a pool allocator setup to grow incrementally via buckets.
Buckets are stored in singly-linked lists so that allocations aren't necessrily congigous.

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
	bucket_list    : DLL_NodeFL( PoolBucket),
	current_bucket : ^PoolBucket,
}

Pool_FreeBlock :: struct {
	next : ^Pool_FreeBlock,
}

PoolBucket :: struct {
	using links : DLL_NodePN( PoolBucket),
	next_block : uint,
	blocks     : [^]byte,
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
	pool.block_size       = block_size
	pool.alignment        = alignment

	alloc_error = pool_allocate_buckets( pool, bucket_reserve_num )
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
	bucket_size := block_size * bucket_capacity
	to_allocate := cast(int) (header_size + bucket_size * num_buckets)

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
		dll_push_back( & self.bucket_list.last, bucket )

		next_bucket_ptr = next_bucket_ptr[ bucket_size: ]
	}
	return alloc_error
}

pool_grab :: proc( using self : Pool ) -> ( block : []byte, alloc_error : AllocatorError )
{
	alloc_error = .None

	// Check the free-list first for a block
	if free_list_head != nil {
		block = slice_ptr( cast([^]byte) ll_pop( & self.free_list_head ), int(block_size) )
		return
	}

	if current_bucket == nil
	{
		alloc_error := pool_allocate_buckets( self, 1 )
		if alloc_error != .None {
			return
		}
		self.current_bucket = bucket_list.first
	}


	next := uintptr(current_bucket.blocks) + uintptr(current_bucket.next_block)
	end  := uintptr(current_bucket.blocks) + uintptr(bucket_capacity)

	blocks_left := end - next
	if blocks_left == 0
	{
		if current_bucket.next != nil {
			self.current_bucket = current_bucket.next
		}
		else
		{
			alloc_error := pool_allocate_buckets( self, 1 )
			if alloc_error != .None {
				return
			}
			self.current_bucket = current_bucket.next
		}
	}

	block       = slice_ptr( current_bucket.blocks[ current_bucket.next_block:], int(block_size) )
	self.current_bucket.next_block += block_size
	return
}

pool_release :: proc( using self : Pool, block : []byte )
{
	when Pool_Check_Release_Object_Validity
	{
		within_bucket := pool_validate_ownership( self, block )
		verify( within_bucket, "Attempted to release data that is not within a bucket of this pool" )
		return
	}

	ll_push( & self.free_list_head, cast(^Pool_FreeBlock) raw_data(block) )
}

pool_reset :: proc( using self : Pool )
{
	bucket := bucket_list.first
	for ; bucket != nil; {
		bucket.next_block = 0
	}

	self.free_list_head = nil
	self.current_bucket = bucket_list.first
}

pool_validate_ownership :: proc( using self : Pool, block : [] byte ) -> b32
{
	within_bucket := b32(false)
	bucket        := bucket_list.first
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
