package sectr

context_ext :: proc( $ Type : typeid ) -> (^Type) {
	return cast(^Type) context.user_ptr
}
