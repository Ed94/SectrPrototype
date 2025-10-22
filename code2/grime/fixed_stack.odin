package grime

FStack :: struct ($Type: typeid, $Size: u32) {
	items: [Size]Type,
	idx:   u32,
}
stack_clear :: #force_inline proc "contextless" (stack: ^FStack($Type, $Size)) { stack.idx = 0 }
stack_push  :: #force_inline proc "contextless" (stack: ^FStack($Type, $Size ), value: Type) {
	assert_contextless(stack.idx < u32(len( stack.items )), "Attempted to push on a full stack")
	stack.items[stack.idx] = value
	stack.idx += 1
}
stack_pop :: #force_inline proc "contextless" (stack: ^FStack($Type, $Size)) {
	assert(stack.idx > 0, "Attempted to pop an empty stack")
	stack.idx -= 1
	if stack.idx == 0 {
		stack.items[stack.idx] = {}
	}
}
stack_peek_ref :: #force_inline proc "contextless" (s: ^FStack($Type, $Size)) -> (^Type) {
	return & s.items[/*last_idx*/ max( 0, s.idx - 1 )]
}
stack_peek :: #force_inline proc "contextless" (s: ^FStack($Type, $Size)) -> Type {
	return s.items[/*last_idx*/ max( 0, s.idx - 1 )]
}
stack_push_contextless :: #force_inline proc "contextless" (s: ^FStack($Type, $Size), value: Type) {
	s.items[s.idx] = value
	s.idx         += 1
}
