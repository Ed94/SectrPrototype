package grime

// TODO(Ed): Review this
import "base:runtime"

// TODO(Ed): Support address sanitizer

/*
Pool allocator backed by chained virtual arenas.
*/

VPool_FreeBlock :: struct { offset: int, }

VPool :: struct {
	
	dbg_name: string,
}

