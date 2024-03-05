/*
This is a pool allocator setup to grow incrementally via buckets.
Buckets are stored in singly-linked lists so that they be allocated non-contiguous
*/
package sectr

Pool :: struct {
	using header : ^PoolHeader,
}

PoolHeader :: struct {
	backing : Allocator,

	block_size      : uint,
	bucket_capacity : uint,
	out_band_size   : uint,
	alignment       : uint,

	free_list      : LL_Node( [^]byte),
	buckets        : LL_Node( [^]byte),
	current_bucket : ^byte,
}

PoolBucket :: struct ( $ Type : typeid) {
	blocks : [^]Type,
}

pool_allocator :: proc ( using self : Pool ) -> (allocator : Allocator) {
	allocator.procedure = pool_allocator_proc
	allocator.data      = self.header
	return
}

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
	return nil, AllocatorError.Mode_Not_Implemented
}
