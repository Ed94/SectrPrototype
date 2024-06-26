package sectr

context_usr :: #force_inline proc( $ Type : typeid ) -> (^Type) {
	return cast(^Type) context.user_ptr
}

ContextExt :: struct {
	stack : StackFixed(rawptr, 1024),
}

// Assign return value to context.user_ptr
// context_ext_init :: proc() -> rawptr
// {

// }

context_ext :: #force_inline proc() -> ^ContextExt {
	return cast(^ContextExt) context.user_ptr
}

context_push :: proc( value : ^($Type) ) {
	push( & context_ext().stack, value )
}

context_pop :: proc( value : ^($Type) ) {
	pop( & context_ext().stack )
	
}
