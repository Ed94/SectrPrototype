package fontstash



import "core:mem"

AllocatorError          :: mem.Allocator_Error

import "codebase:grime"

// asserts
ensure :: grime.ensure

// container

Array :: grime.Array

array_init_reserve :: grime.array_init_reserve
array_append       :: grime.array_append
array_append_at    :: grime.array_append_at
array_clear        :: grime.array_clear
array_free         :: grime.array_free
array_remove_at    :: grime.array_remove_at
array_to_slice     :: grime.array_to_slice

//#region("Proc overload mappings")

append :: proc {
	grime.array_append_array,
	grime.array_append_slice,
	grime.array_append_value,
}

append_at :: proc {
	array_append_at,
}

clear :: proc {
	array_clear,
}

free :: proc {
	array_free,
}

init_reserve :: proc {
	array_init_reserve,
}

remove_at :: proc {
	array_remove_at,
}

to_slice :: proc {
	array_to_slice,
}

//#endregion("Proc overload mappings")
