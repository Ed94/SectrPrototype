package VEFontCache

/*
The choice was made to keep the LRU cache implementation as close to the original as possible.
*/

import "base:runtime"

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
	dbg_name  : string,
}

pool_list_init :: proc( pool : ^PoolList, capacity : u32, dbg_name : string = "" )
{
	error : AllocatorError
	pool.items, error = make( Array( PoolListItem ), u64(capacity) )
	assert( error == .None, "VEFontCache.pool_list_init : Failed to allocate items array")
	array_resize( & pool.items, u64(capacity) )

	pool.free_list, error = make( Array( PoolListIter ), u64(capacity) )
	assert( error == .None, "VEFontCache.pool_list_init : Failed to allocate free_list array")
	array_resize( & pool.free_list, u64(capacity) )

	pool.capacity = capacity

	pool.dbg_name = dbg_name
	using pool

	for id in 0 ..< capacity {
		free_list.data[id] = i32(id)
		items.data[id] = {
			prev = -1,
			next = -1,
		}
	}

	front = -1
	back  = -1
}

pool_list_free :: proc( pool : ^PoolList )
{

}

pool_list_reload :: proc( pool : ^PoolList, allocator : Allocator )
{
	pool.items.backing     = allocator
	pool.free_list.backing = allocator
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
	if pool.dbg_name != "" {
		logf("pool_list: pushed %v into id %v", value, id)
	}

	if front != -1 do items.data[ front ].prev = id
	if back  == -1 do back = id
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
	// if pool.dbg_name != "" {
	// 	logf("pool_list: erased %v, at id %v", iter_node.value, iter)
	// }
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
	if pool.size <= 0 do return 0
	assert( pool.back != -1 )

	value := pool.items.data[ pool.back ].value
	pool_list_erase( pool, pool.back )
	return value
}

LRU_Link :: struct {
	pad_top : u64,
	value : i32,
	ptr   : PoolListIter,
	pad_bottom : u64,
}

LRU_Cache :: struct {
	capacity  : u32,
	num       : u32,
	table     : HMapChained(LRU_Link),
	key_queue : PoolList,
}

LRU_init :: proc( cache : ^LRU_Cache, capacity : u32, dbg_name : string = "" ) {
	error : AllocatorError
	cache.capacity     = capacity
	cache.table, error = make( HMapChained(LRU_Link), hmap_closest_prime( uint(capacity)) )
	assert( error == .None, "VEFontCache.LRU_init : Failed to allocate cache's table")

	pool_list_init( & cache.key_queue, capacity, dbg_name = dbg_name )
}

LRU_free :: proc( cache : ^LRU_Cache )
{

}

LRU_reload :: proc( cache : ^LRU_Cache, allocator : Allocator )
{
	hmap_chained_reload( cache.table, allocator )
	pool_list_reload( & cache.key_queue, allocator )
}

LRU_hash_key :: #force_inline proc( key : u64 ) -> ( hash : u64 ) {
	bytes := transmute( [8]byte ) key
	hash   = fnv64a( bytes[:] )
	return
}

LRU_find :: proc( cache : ^LRU_Cache, key : u64, must_find := false ) -> ^LRU_Link {
	hash := LRU_hash_key( key )
	link := get( cache.table, hash )
	// if link == nil && must_find {
	// 	runtime.debug_trap()
	// 	link = get( cache.table, hash )
	// }
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

LRU_peek :: proc( cache : ^LRU_Cache, key : u64, must_find := false ) -> i32 {
	iter := LRU_find( cache, key, must_find )
	if iter == nil {
		return -1
	}
	return iter.value
}

LRU_put :: proc( cache : ^LRU_Cache, key : u64,  value : i32 ) -> u64
{
	hash_key := LRU_hash_key( key )
	iter     := get( cache.table, hash_key )
	if iter != nil {
		LRU_refresh( cache, key )
		iter.value = value
		return key
	}

	evict := key
	if cache.key_queue.size >= cache.capacity {
		evict = pool_list_pop_back( & cache.key_queue )

		evict_hash := LRU_hash_key( evict )
		// if cache.table.dbg_name != "" {
		// 	logf("%v: Evicted   %v with hash: %v", cache.table.dbg_name, evict, evict_hash)
		// }
		hmap_chained_remove( cache.table, evict_hash )
		cache.num -= 1
	}

	pool_list_push_front( & cache.key_queue, key )
	// if cache.table.dbg_name != "" {
	// 	logf("%v: Pushed   %v with hash: %v", cache.table.dbg_name, key, hash_key )
	// }

	set( cache.table, hash_key, LRU_Link {
		value = value,
		ptr   = cache.key_queue.front
	})

	cache.num += 1
	return evict
}

LRU_refresh :: proc( cache : ^LRU_Cache, key : u64 ) {
	link := LRU_find( cache, key )
	// if cache.table.dbg_name != "" {
	// 	logf("%v: Refreshed %v", cache.table.dbg_name, key)
	// }
	pool_list_erase( & cache.key_queue, link.ptr )
	pool_list_push_front( & cache.key_queue, key )
	link.ptr = cache.key_queue.front
}
