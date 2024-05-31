package grime

//#region("Fixed Stack")

StackFixed :: struct ( $ Type : typeid, $ Size : u32 ) {
	idx   : u32,
	items : [ Size ] Type,
}

stack_clear :: #force_inline proc ( using stack : ^StackFixed( $Type, $Size)) {
	idx = 0
}

stack_push :: #force_inline proc( using stack : ^ StackFixed( $ Type, $ Size ), value : Type ) {
	assert( idx < len( items ), "Attempted to push on a full stack" )

	items[ idx ] = value
	idx += 1
}

stack_pop :: #force_inline proc( using stack : ^StackFixed( $ Type, $ Size ) ) {
	assert( idx > 0, "Attempted to pop an empty stack" )

	idx -= 1
	if idx == 0 {
		items[idx] = {}
	}
}

stack_peek_ref :: #force_inline proc "contextless" ( using stack : ^StackFixed( $ Type, $ Size ) ) -> ( ^Type) {
	last_idx := max( 0, idx - 1 ) if idx > 0 else 0
	last     := & items[last_idx]
	return last
}

stack_peek :: #force_inline proc "contextless" ( using stack : ^StackFixed( $ Type, $ Size ) ) -> Type {
	last := max( 0, idx - 1 ) if idx > 0 else 0
	return items[last]
}

stack_push_contextless :: #force_inline proc "contextless" ( stack : ^StackFixed( $Type, $Size), value : Type ) {
	items[idx]  = value
	idx        += 1
}

//#endregion("Fixed Stack")
