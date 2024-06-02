package fontstash

import "core:mem"

AllocatorError          :: mem.Allocator_Error

import "codebase:grime"

// asserts
ensure :: grime.ensure
verify :: grime.verify

// container

Array :: grime.Array

array_init             :: grime.array_init
array_append           :: grime.array_append
array_append_at        :: grime.array_append_at
array_clear            :: grime.array_clear
array_free             :: grime.array_free
array_remove_at        :: grime.array_remove_at
array_to_slice         :: grime.array_to_slice
array_underlying_slice :: grime.array_underlying_slice

StackFixed :: grime.StackFixed

stack_clear            :: grime.stack_clear
stack_push             :: grime.stack_push
stack_pop              :: grime.stack_pop
stack_peek_ref         :: grime.stack_peek_ref
stack_peek             :: grime.stack_peek
stack_push_contextless :: grime.stack_push_contextless

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
}

delete :: proc {
	array_free,
}

make :: proc {
	array_init,
}

remove_at :: proc {
	array_remove_at,
}

to_slice :: proc {
	array_to_slice,
}

underlying_slice :: proc {
	array_underlying_slice,
}

//#endregion("Proc overload mappings")
