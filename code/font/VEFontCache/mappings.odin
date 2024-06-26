package VEFontCache

import "core:hash"
	crc64  :: hash.crc64_xz
	crc32  :: hash.crc32
	fnv64a :: hash.fnv64a

import "core:mem"

Kilobyte :: mem.Kilobyte

slice_ptr :: mem.slice_ptr

Arena :: mem.Arena

arena_allocator :: mem.arena_allocator
arena_init      :: mem.arena_init

Allocator      :: mem.Allocator
AllocatorError :: mem.Allocator_Error

import "codebase:grime"

hmap_closest_prime :: grime.hmap_closest_prime

// logging
log  :: grime.log
logf :: grime.logf

profile :: grime.profile

reload_array :: grime.reload_array
reload_map   :: grime.reload_map

//#region("Proc overload mappings")

append :: proc {
	append_elem,
	append_elems,
	append_elem_string,
}

clear :: proc {
	clear_dynamic_array,
}

make :: proc {
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
}


resize :: proc {
	resize_dynamic_array,
}

vec2 :: proc {
	vec2_from_scalar,
}

//#endregion("Proc overload mappings")
