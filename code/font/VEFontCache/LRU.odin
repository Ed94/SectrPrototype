package VEFontCache

/*
The choice was made to keep the LUR cache implementation as close to the original as possible.
*/

PoolListIter  :: u32
PoolListValue :: u64

PoolListItem :: struct {
	prev  : PoolListIter,
	next  : PoolListIter,
	value : PoolListValue,
}

PoolList :: struct {
	items     : Array( PoolListItem ),
	free_list : Array( PoolListIter ),
	front     : PoolListIter,
	back      : PoolListIter,
	size      : i32,
	capacity  : i32,
}

pool_list_init :: proc( pool : ^PoolList, capacity : u32 )
{
	error : AllocatorError
	pool.items, error = make( Array( PoolListItem ), u64(capacity) )
	assert( error == .None, "VEFontCache.pool_list_init : Failed to allocate items array")

	pool.free_list, error = make( Array( PoolListIter ), u64(capacity) )
	assert( error == .None, "VEFontCache.pool_list_init : Failed to allocate free_list array")

	pool.capacity = i32(capacity)

	for id in 0 ..< capacity do pool.free_list.data[id] = id
}

pool_list_push_front :: proc( pool : ^PoolList, value : PoolListValue )
{
	using pool
	if size >= capacity do return
	assert( free_list.num > 0 )
	assert( free_list.num == u64(capacity - size) )

	id := array_back( free_list )
}

LRU_Link :: struct {
	value : i32,
	ptr   : PoolListIter,
}

LRU_Cache :: struct {
	capacity  : i32,
	table     : HMapChained(LRU_Link),
	key_queue : PoolList,
}

LRU_init :: proc( cache : ^LRU_Cache, capacity : u32 )
{
	error : AllocatorError
	cache.capacity     = i32(capacity)
	cache.table, error = make( HMapChained(LRU_Link), uint(capacity) )
	assert( error != .None, "VEFontCache.LRU_init : Failed to allocate cache's table")

}


