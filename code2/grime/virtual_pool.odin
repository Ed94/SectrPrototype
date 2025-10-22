package grime

// TODO(Ed): Review this
import "base:runtime"

// TODO(Ed): Support address sanitizer

/*
Pool allocator backed by chained virtual arenas.
*/

Pool_FreeBlock :: struct { next: ^Pool_FreeBlock }

VPool :: struct {
	arenas:     ^Arena,
	block_size: uint,
	// alignment:  uint,

	free_list_head: ^Pool_FreeBlock,
}

pool_make :: proc() -> (pool: VPool, error: AllocatorError)
{
	panic("not implemented")
	// return
}


