package VEFontCache

/*
The choice was made to keep the LRU cache implementation as close to the original as possible.
*/

PoolListIter  :: i32
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
	size      : u32,
	capacity  : u32,
}

pool_list_init :: proc( pool : ^PoolList, capacity : u32 )
{
	error : AllocatorError
	pool.items, error = make( Array( PoolListItem ), u64(capacity) )
	assert( error == .None, "VEFontCache.pool_list_init : Failed to allocate items array")
	array_resize( & pool.items, u64(capacity) )

	pool.free_list, error = make( Array( PoolListIter ), u64(capacity) )
	assert( error == .None, "VEFontCache.pool_list_init : Failed to allocate free_list array")
	array_resize( & pool.free_list, u64(capacity) )

	pool.capacity = capacity

	for id in 0 ..< capacity do pool.free_list.data[id] = i32(id)
}

pool_list_push_front :: proc( pool : ^PoolList, value : PoolListValue )
{
	using pool
	if size >= capacity do return
	assert( free_list.num > 0 )
	assert( free_list.num == u64(capacity - size) )

	id := array_back( free_list )
	array_pop( free_list )
	items.data[ id ].prev  = -1
	items.data[ id ].next  = front
	items.data[ id ].value = value

	if front != -1 do items.data[ front ].prev = id
	if back  != -1 do back = id
	front  = id
	size  += 1
}

pool_list_erase :: proc( pool : ^PoolList, iter : PoolListIter )
{
	using pool
	if size <= 0 do return
	assert( iter >= 0 && iter < i32(capacity) )
	assert( free_list.num == u64(capacity - size) )

	iter_node := & items.data[ iter ]
	prev := iter_node.prev
	next := iter_node.next

	if iter_node.prev != -1 do items.data[ prev ].next = iter_node.next
	if iter_node.next != -1 do items.data[ next ].prev = iter_node.prev

	if front == iter do front = iter_node.next
	if back  == iter do back  = iter_node.prev

	iter_node.prev  = -1
	iter_node.next  = -1
	iter_node.value = 0
	append( & free_list, iter )

	size -= 1
	if size == 0 {
		back  = -1
		front = -1
	}
}

pool_list_peek_back :: proc ( pool : ^PoolList ) -> PoolListValue {
	assert( pool.back != - 1 )
	value := pool.items.data[ pool.back ].value
	return value
}

pool_list_pop_back :: proc( pool : ^PoolList ) -> PoolListValue {
	using pool
	if size <= 0 do return 0
	assert( back != -1 )

	value := items.data[ back ].value
	pool_list_erase( pool, back )
	return value
}

LRU_Link :: struct {
	value : i32,
	ptr   : PoolListIter,
}

LRU_Cache :: struct {
	capacity  : u32,
	num       : u32,
	table     : HMapZPL(LRU_Link),
	key_queue : PoolList,
}

LRU_init :: proc( cache : ^LRU_Cache, capacity : u32 ) {
	error : AllocatorError
	cache.capacity     = capacity
	cache.table, error = hmap_zpl_init( HMapZPL(LRU_Link), u64( hmap_closest_prime( uint(capacity))) )
	assert( error == .None, "VEFontCache.LRU_init : Failed to allocate cache's table")

	pool_list_init( & cache.key_queue, capacity )
}

LRU_find :: proc( cache : ^LRU_Cache, value : u64 ) -> ^LRU_Link {
	bytes := transmute( [8]byte ) value
	key   := fnv64a( bytes[:] )
	link  := get( & cache.table, key )
	return link
}

LRU_get :: proc( cache : ^LRU_Cache, key : u64 ) -> i32 {
	iter := LRU_find( cache, key )
	if iter == nil {
		return -1
	}
	LRU_refresh( cache, key )
	return iter.value
}

LRU_get_next_evicted :: proc( cache : ^LRU_Cache ) -> u64
{
	if cache.key_queue.size >= cache.capacity {
		evict := pool_list_peek_back( & cache.key_queue )
		return evict
	}
	return 0xFFFFFFFFFFFFFFFF
}

LRU_peek :: proc( cache : ^LRU_Cache, key : u64 ) -> i32 {
	iter := LRU_find( cache, key )
	if iter == nil {
		return -1
	}
	return iter.value
}

LRU_put :: proc( cache : ^LRU_Cache, key : u64,  value : i32 ) -> u64 {
	iter := LRU_find( cache, key )
	if iter != nil {
		LRU_refresh( cache, key )
		iter.value = value
		return key
	}

	evict := key
	if cache.key_queue.size >= cache.capacity {
		evict = pool_list_pop_back( & cache.key_queue )
		// hmap_chained_remove( cache.table, evict )
		hmap_zpl_remove( & cache.table, evict )
		cache.num -= 1
	}

	pool_list_push_front( & cache.key_queue, key )

	bytes    := transmute( [8]byte ) key
	hash_key := fnv64a( bytes[:] )
	// set( cache.table, hash_key, LRU_Link {
	set( & cache.table, hash_key, LRU_Link {
		value = value,
		ptr   = cache.key_queue.front
	})

	cache.num += 1
	return evict
}

LRU_refresh :: proc( cache : ^LRU_Cache, key : u64 ) {
	link := LRU_find( cache, key )
	pool_list_erase( & cache.key_queue, link.ptr )
	pool_list_push_front( & cache.key_queue, key )
	link.ptr = cache.key_queue.front
}
