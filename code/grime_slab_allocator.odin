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

Strings Slab pool size-classes (bucket:block ratio) are as follows:
16 mb  : 64  b  = 262,144 blocks
8  mb  : 128 b  = 8192 blocks
8  mb  : 256 b  = 8192 blocks
8  mb  : 1  kb  = 8192 blocks
16 mb  : 4  kb  = 4096 blocks
32 mb  : 16 kb  = 4096 blocks
32 mb  : 32 kb  = 4096 blocks
256 mb : 64 kb  = 
512 mb : 128 kb = 
*/
package sectr

SlabSizeClass :: struct {
	bucket : uint,
	block  : uint,
}

Slab_Max_Size_Classes :: 32

SlabPolicy :: [Slab_Max_Size_Classes]SlabSizeClass

SlabHeader :: struct {
	policy : SlabPolicy,
	pools  : [Slab_Max_Size_Classes]Pool,
}

Slab :: struct {
	using header : SlabHeader,
}

slab_init_reserve :: proc(  ) -> ( Slab )
{
	return {}
}
