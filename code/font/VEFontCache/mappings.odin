package VEFontCache

import "core:hash"
	fnv64a :: hash.fnv64a

import "core:mem"

Kilobyte :: mem.Kilobyte

Arena :: mem.Arena

arena_allocator :: mem.arena_allocator
arena_init      :: mem.arena_init

Allocator      :: mem.Allocator
AllocatorError :: mem.Allocator_Error

import "codebase:grime"

// asserts
ensure :: grime.ensure
verify :: grime.verify

// container

Array :: grime.Array

array_init             :: grime.array_init
array_append           :: grime.array_append
array_append_at        :: grime.array_append_at
array_back             :: grime.array_back
array_clear            :: grime.array_clear
array_free             :: grime.array_free
array_remove_at        :: grime.array_remove_at
array_pop              :: grime.array_pop
array_resize           :: grime.array_resize
array_to_slice         :: grime.array_to_slice
array_to_slice_cpacity :: grime.array_to_slice_capacity
array_underlying_slice :: grime.array_underlying_slice

HMapChained :: grime.HMapChained

hmap_chained_clear   :: grime.hmap_chained_clear
hmap_chained_destroy :: grime.hmap_chained_destroy
hmap_chained_init    :: grime.hmap_chained_init
hmap_chained_get     :: grime.hmap_chained_get
hmap_chained_remove  :: grime.hmap_chained_remove
hmap_chained_set     :: grime.hmap_chained_set
hmap_closest_prime   :: grime.hmap_closest_prime

// Pool :: grime.Pool

StackFixed :: grime.StackFixed

stack_clear            :: grime.stack_clear
stack_push             :: grime.stack_push
stack_pop              :: grime.stack_pop
stack_peek_ref         :: grime.stack_peek_ref
stack_peek             :: grime.stack_peek
stack_push_contextless :: grime.stack_push_contextless

// logging
log  :: grime.log
logf :: grime.logf

//#region("Proc overload mappings")

append :: proc {
	grime.array_append_array,
	grime.array_append_slice,
	grime.array_append_value,
}

append_at :: proc {
	grime.array_append_at_slice,
	grime.array_append_at_value,
}

clear :: proc {
	array_clear,
	hmap_chained_clear,
}

delete :: proc {
	array_free,
	hmap_chained_destroy,
}

get :: proc {
	hmap_chained_get,
}

make :: proc {
	array_init,
	hmap_chained_init,
}

remove_at :: proc {
	array_remove_at,
}

resize :: proc {
	array_resize,
}

set :: proc {
	hmap_chained_set,
}

to_slice :: proc {
	array_to_slice,
}

underlying_slice :: proc {
	array_underlying_slice,
}

//#endregion("Proc overload mappings")
