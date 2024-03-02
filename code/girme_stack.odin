package sectr

Stack :: struct ( $ Type : typeid, $ Size : i32 ) {
	idx   : i32,
	items : [ Size ] Type,
}

stack_push :: proc( using stack : ^ Stack( $ Type, $ Size ), value : Type ) {
	verify( idx < len( items ), "Attempted to push on a full stack" )

	items[ idx ] = value
	idx += 1
}

stack_pop :: proc( using stack : ^ Stack( $ Type, $ Size ) ) {
	verify( idx > 0, "Attempted to pop an empty stack" )

	idx -= 1
	if idx == 0 {
		items[idx] = {}
	}
}

stack_peek_ref :: proc( using stack : ^ Stack( $ Type, $ Size ) ) -> ^ Type {
	last := max( 0, idx - 1 )
	return & items[last]
}

stack_peek :: proc ( using stack : ^ Stack( $ Type, $ Size ) ) -> Type {
	last := max( 0, idx - 1 )
	return items[last]
}
