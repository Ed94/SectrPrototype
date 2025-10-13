package grime

OdinContext :: struct {
	allocator:              AllocatorInfo,
	temp_allocator:         AllocatorInfo,
	assertion_failure_proc: Assertion_Failure_Proc,
	logger:                 Logger,
	random_generator:       Random_Generator,

	user_ptr:   rawptr,
	user_index: int,

	// Internal use only
	_internal: rawptr,
}

context_user :: #force_inline proc( $ Type : typeid ) -> (^Type) {
	return cast(^Type) context.user_ptr
}
