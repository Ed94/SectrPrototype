/* Slab Allocator
These are a collection of pool allocators serving as a general way
to allocate a large amount of dynamic sized data.

The usual use case for this is an arena, stack,
or dedicated pool allocator fail to be enough to handle a data structure
that either is too random with its size (ex: strings)
or is intended to grow an abitrary degree with an unknown upper bound (dynamic arrays, and hashtables).

The protototype will use slab allocators for two purposes:
* String interning
* General purpose set for handling large arrays & hash tables within some underlying arena or stack.

Technically speaking the general purpose situations can instead be grown on demand
with a dedicated segement of vmem, however this might be overkill
if the worst case buckets allocated are < 500 mb for most app usage.

The slab allocators are expected to hold growable pool allocators,
where each pool stores a 'bucket' of fixed-sized blocks of memory.
When a pools bucket is full it will request another bucket from its arena
for permanent usage within the arena's lifetime.

A freelist is tracked for free-blocks for each pool (provided by the underlying pool allocator)

A slab starts out with pools initialized with no buckets and grows as needed.
When a slab is initialized the slab policy is provided to know how many size-classes there should be
which each contain the ratio of bucket to block size.
*/
package sectr

import "core:mem"
import "core:slice"

SlabSizeClass :: struct {
	bucket_capacity : uint,
	block_size      : uint,
	block_alignment : uint,
}

Slab_Max_Size_Classes :: 64

SlabPolicy :: StackFixed(SlabSizeClass, Slab_Max_Size_Classes)

SlabHeader :: struct {
	backing : Allocator,

	policy : SlabPolicy, // TODO(Ed) : Remove this, the policy can't be changed after its been set so its meaningless to have...
	pools  : StackFixed(Pool, Slab_Max_Size_Classes),
}

Slab :: struct {
	using header : ^SlabHeader,
}

slab_allocator :: proc( slab : Slab ) -> ( allocator : Allocator ) {
	allocator.procedure = slab_allocator_proc
	allocator.data      = slab.header
	return
}

slab_init :: proc( policy : ^SlabPolicy, bucket_reserve_num : uint = 0, allocator : Allocator ) -> ( slab : Slab, alloc_error : AllocatorError )
{
	header_size :: size_of( SlabHeader )

	raw_mem : rawptr
	raw_mem, alloc_error = alloc( header_size, mem.DEFAULT_ALIGNMENT, allocator )
	if alloc_error != .None do return

	slab.header  = cast( ^SlabHeader) raw_mem
	slab.backing = allocator
	slab.policy  = (policy^)
	alloc_error  = slab_init_pools( slab, bucket_reserve_num )
	return
}

slab_init_pools :: proc ( using self : Slab, bucket_reserve_num : uint = 0 ) -> AllocatorError
{
	profile(#procedure)
	for id in 0 ..< policy.idx {
		using size_class := policy.items[id]

		pool, alloc_error := pool_init( block_size, bucket_capacity, bucket_reserve_num, block_alignment, backing )
		if alloc_error != .None do return alloc_error

		push( & self.pools, pool )
	}
	return .None
}

slab_destroy :: proc( using self : Slab )
{
	for id in 0 ..< policy.idx {
		pool := pools.items[id]
		pool_destroy( pool )
	}

	free( self.header, backing )
}

slab_alloc :: proc( using self : Slab,
	size        : uint,
	alignment   : uint,
	zero_memory := true,
	loc    := #caller_location
) -> ( data : []byte, alloc_error : AllocatorError )
{
	// profile(#procedure)
	pool : Pool
	id : u32 = 0
	for ; id < pools.idx; id += 1 {
			pool = pools.items[id]

			if pool.block_size >= size && pool.alignment >= alignment {
					break
			}
	}
	verify( id < pools.idx, "There is not a size class in the slab's policy to satisfy the requested allocation" )

	verify( pool.header != nil, "Requested alloc not supported by the slab allocator", location = loc )

	block : []byte
	block, alloc_error = pool_grab(pool)
	if alloc_error != .None {
			ensure(false, "Bad block from pool")
			return nil, alloc_error
	}
	log( str_fmt_tmp("Retrieved block: %p %d", raw_data(block), len(block) ))

	// if zero_memory {
	// 	slice.zero(block)
	// }

	data = byte_slice(raw_data(block), size)
	if zero_memory {
		slice.zero(data)
	}
	return
}

slab_free :: proc( using self : Slab, data : []byte, loc := #caller_location )
{
	// profile(#procedure)
	pool : Pool
	for id in 0 ..< pools.idx
	{
		pool = pools.items[id]
		if pool_validate_ownership( pool, data ) {
			pool_release( pool, data, loc )
			return
		}
	}
	verify(false, "Attempted to free a block not within a pool of this slab", location = loc)
}

slab_resize :: proc( using self : Slab,
	data        : []byte,
	new_size    : uint,
	alignment   : uint,
	zero_memory := true,
	loc         := #caller_location
) -> ( new_data : []byte, alloc_error : AllocatorError )
{
	// profile(#procedure)
	old_size := uint( len(data))

	pool_resize, pool_old : Pool
	for id in 0 ..< pools.idx
	{
			pool := pools.items[id]

			if pool.block_size >= new_size && pool.alignment >= alignment {
				pool_resize = pool
			}
			if pool_validate_ownership( pool, data ) {
				pool_old = pool
			}
			if pool_resize.header != nil && pool_old.header != nil {
				break
			}
	}

	verify( pool_resize.header != nil, "Requested resize not supported by the slab allocator", location = loc )

	// Resize will keep block in the same size_class, just give it more of its already allocated block
	if pool_old == pool_resize
	{
		new_data_ptr := memory_after(data)
		new_data      = byte_slice( raw_data(data), new_size )
		log( str_fmt_tmp("Resize via expanding block space allocation %p %d", new_data_ptr, int(new_size - old_size)))

		if zero_memory && new_size > old_size {
			to_zero := byte_slice( memory_after(data), int(new_size - old_size) )
			slice.zero( to_zero )
			log( str_fmt_tmp("Zeroed memory - Range(%p to %p)", new_data_ptr, int(new_size - old_size)))
		}
		return
	}

	// We'll need to provide an entirely new block, so the data will need to be copied over.
	new_block : []byte
	new_block, alloc_error = pool_grab( pool_resize )
	if new_block == nil {
		ensure(false, "Retreived a null block")
		return
	}

	if alloc_error != .None do return
	// if zero_memory {
	// 	slice.zero( new_block )
	// }

	log( str_fmt_tmp("Resize via new block: %p %d (old : %p $d )", raw_data(new_block), len(new_block), raw_data(data), old_size ))

	if raw_data(data) != raw_data(new_block) {
		copy_non_overlapping( raw_data(new_block), raw_data(data), int(old_size) )
		pool_release( pool_old, data )
	}

	new_data = byte_slice( raw_data(new_block), int(old_size) )
	return
}

slab_reset :: proc( slab : Slab )
{
	for id in 0 ..< slab.pools.idx {
		pool := slab.pools.items[id]
		pool_reset( pool )
	}
}

slab_allocator_proc :: proc(
	allocator_data : rawptr,
	mode           : AllocatorMode,
	size           : int,
	alignment      : int,
	old_memory     : rawptr,
	old_size       : int,
	loc            := #caller_location
) -> ( data : []byte, alloc_error : AllocatorError)
{
	slab : Slab
	slab.header = cast( ^SlabHeader) allocator_data

	size      := uint(size)
	alignment := uint(alignment)
	old_size  := uint(old_size)

	switch mode
	{
		case .Alloc, .Alloc_Non_Zeroed:
			return slab_alloc( slab, size, alignment, (mode != .Alloc_Non_Zeroed), loc)

		case .Free:
			slab_free( slab, byte_slice( old_memory, int(old_size)), loc )

		case .Free_All:
			slab_reset( slab )

		case .Resize, .Resize_Non_Zeroed:
			return slab_resize( slab, byte_slice(old_memory, int(old_size)), size, alignment, (mode != .Resize_Non_Zeroed), loc)

		case .Query_Features:
			set := cast( ^AllocatorModeSet) old_memory
			if set != nil {
				(set ^) = {.Alloc, .Alloc_Non_Zeroed, .Free_All, .Resize, .Query_Features}
			}

		case .Query_Info:
			alloc_error = .Mode_Not_Implemented
	}
	return
}
