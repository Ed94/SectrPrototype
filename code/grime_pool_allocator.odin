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

import "base:intrinsics"
import "base:runtime"
import "core:mem"
import "core:slice"

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
	bucket_list    : DLL_NodeFL( PoolBucket),
}

PoolBucket :: struct {
	using nodes : DLL_NodePN( PoolBucket),
	next_block  : uint,
	blocks      : [^]byte,
}

Pool_FreeBlock :: struct {
	next : ^Pool_FreeBlock,
}

Pool_Check_Release_Object_Validity :: true

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
	pool.block_size       = align_forward_uint(block_size, alignment)
	pool.bucket_capacity  = bucket_capacity
	pool.alignment        = alignment

	if bucket_reserve_num > 0 {
		alloc_error = pool_allocate_buckets( pool, bucket_reserve_num )
	}
	pool.current_bucket = pool.bucket_list.first
	return
}

pool_reload :: proc( pool : Pool, allocator : Allocator ) {
	pool.backing = allocator
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

pool_allocate_buckets :: proc( pool : Pool, num_buckets : uint ) -> AllocatorError
{
	profile(#procedure)
	if num_buckets == 0 {
		return .Invalid_Argument
	}
	header_size := cast(uint) align_forward_int( size_of(PoolBucket), int(pool.alignment))
	bucket_size := header_size + pool.bucket_capacity
	to_allocate := cast(int) (bucket_size * num_buckets)

	pool_validate( pool )
	bucket_memory, alloc_error := alloc_bytes_non_zeroed( to_allocate, int(pool.alignment), pool.backing )
	pool_validate( pool )
	if alloc_error != .None {
		return alloc_error
	}
	verify( bucket_memory != nil, "Bucket memory is null")

	next_bucket_ptr := cast( [^]byte) raw_data(bucket_memory)
	for index in 0 ..< num_buckets
	{
		bucket           := cast( ^PoolBucket) next_bucket_ptr
		bucket.blocks     = memory_after_header(bucket)
		bucket.next_block = 0
		log( str_fmt_tmp("Pool (%d) allocated bucket: %p capacity: %d",
			pool.block_size,
			raw_data(bucket_memory),
			pool.bucket_capacity / pool.block_size
		))

		if bucket == cast(rawptr) uintptr(0x100017740D0) {
			runtime.debug_trap()
		}

		if pool.bucket_list.first == nil {
			pool.bucket_list.first = bucket
			pool.bucket_list.last  = bucket
		}
		else {
			dll_push_back( & pool.bucket_list.last, bucket )
		}
		// log( str_fmt_tmp("Bucket List First: %p", self.bucket_list.first))

		next_bucket_ptr = next_bucket_ptr[ bucket_size: ]
	}
	return alloc_error
}

pool_grab :: proc( pool : Pool, zero_memory := false ) -> ( block : []byte, alloc_error : AllocatorError )
{
	pool := pool
	if pool.current_bucket != nil {
		verify( pool.current_bucket.blocks != nil, str_fmt_tmp("current_bucket was wiped %p", pool.current_bucket) )
	}

	// profile(#procedure)
	alloc_error = .None

	// Check the free-list first for a block
	// if pool.free_list_head != nil && false
	if false
	{
		head := & pool.free_list_head

		// Compiler Bug? Fails to compile
		// last_free := ll_pop( & pool.free_list_head )

		last_free : ^Pool_FreeBlock = pool.free_list_head
		pool.free_list_head         = pool.free_list_head.next

		block = byte_slice( cast([^]byte) last_free, int(pool.block_size) )
		log( str_fmt_tmp("Returning free block: %p %d", raw_data(block), pool.block_size))
		if zero_memory {
			slice.zero(block)
		}
		verify(false, "WE SHOULD NEVER BE HERE")
		return
	}

	// Compiler Fail Bug ? using current_bucket directly instead of with pool..
	// if current_bucket == nil
	if pool.current_bucket == nil
	{
		alloc_error = pool_allocate_buckets( pool, 1 )
		if alloc_error != .None {
			ensure(false, "Failed to allocate bucket")
			return
		}
		pool.current_bucket = pool.bucket_list.first
		// log( "First bucket allocation")
	}

	// Compiler Bug ? (Won't work without "pool."")
	// next := uintptr(current_bucket.blocks) + uintptr(current_bucket.next_block)
	// end  := uintptr(current_bucket.blocks) + uintptr(bucket_capacity)
	next := uintptr(pool.current_bucket.blocks) + uintptr(pool.current_bucket.next_block)
	end  := uintptr(pool.current_bucket.blocks) + uintptr(pool.bucket_capacity)

	blocks_left, overflow_signal := intrinsics.overflow_sub( end, next )
	if blocks_left == 0 || overflow_signal
	{
		// Compiler Bug
		// if current_bucket.next != nil {
		if pool.current_bucket.next != nil {
			// current_bucket = current_bucket.next
			// log( str_fmt_tmp("Bucket %p exhausted using %p", pool.current_bucket, pool.current_bucket.next))
			pool.current_bucket = pool.current_bucket.next
			verify( pool.current_bucket.blocks != nil, "Next's blocks are null?" )
		}
		else
		{
			log( "All previous buckets exhausted, allocating new bucket")
			alloc_error := pool_allocate_buckets( pool, 1 )
			if alloc_error != .None {
				ensure(false, "Failed to allocate bucket")
				return
			}
			pool.current_bucket = pool.current_bucket.next
			verify( pool.current_bucket.blocks != nil, "Next's blocks are null (Post new bucket alloc)?" )
		}
	}

	verify( pool.current_bucket != nil, "Attempted to grab a block from a null bucket reference" )

	// Compiler Bug
	// block = slice_ptr( current_bucket.blocks[ current_bucket.next_block:], int(block_size) )
	// self.current_bucket.next_block += block_size

	block_ptr := cast(rawptr) (uintptr(pool.current_bucket.blocks) + uintptr(pool.current_bucket.next_block))

	block = byte_slice( block_ptr, int(pool.block_size) )
	pool.current_bucket.next_block += pool.block_size

	next = uintptr(pool.current_bucket.blocks) + uintptr(pool.current_bucket.next_block)
	// log( str_fmt_tmp("grabbing block: %p blocks left: %d", raw_data(block), (end - next) / uintptr(pool.block_size) ))

	if zero_memory {
		slice.zero(block)
	}
	return
}

pool_release :: proc( self : Pool, block : []byte, loc := #caller_location )
{
	// profile(#procedure)
	if Pool_Check_Release_Object_Validity {
		within_bucket := pool_validate_ownership( self, block )
		verify( within_bucket, "Attempted to release data that is not within a bucket of this pool", location = loc )
	}

	// Compiler bug
	// ll_push( & self.free_list_head, cast(^Pool_FreeBlock) raw_data(block) )

	pool_watch := self
	head_watch := & self.free_list_head

	// ll_push:
	new_free_block     := cast(^Pool_FreeBlock) raw_data(block)
	new_free_block.next = self.free_list_head
	self.free_list_head = new_free_block

	new_free_block = new_free_block
	// log( str_fmt_tmp("Released block: %p %d", new_free_block, self.block_size))
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

pool_validate :: proc( pool : Pool )
{
	pool := pool
	// Make sure all buckets don't show any indication of corruption
	bucket : ^PoolBucket = pool.bucket_list.first
	// Compiler bug ^^ same as pool_reset
	for ; bucket != nil; bucket = bucket.next
	{
		verify( bucket.blocks != nil, "Found corrupted bucket" )
	}
}

pool_validate_ownership :: proc( using self : Pool, block : [] byte ) -> b32
{
	profile(#procedure)
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
