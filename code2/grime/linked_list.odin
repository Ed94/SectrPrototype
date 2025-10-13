package grime

sll_stack_push_n :: proc "contextless" (curr, n, n_link: ^^$Type) {
    (n_link ^) = (curr ^)
    (curr   ^) = (n    ^)
}
sll_queue_push_nz :: proc "contextless" (first: ^$ParentType, last, n: ^^$Type, nil_val: ^Type) {
	if (first ^) == nil_val {
		(first ^) = n^
		(last  ^) = n^
		n^.next = nil_val
	}
	else {
		(last ^).next = n^
		(last ^)      = n^
		n^.next        = nil_val
	}
}
sll_queue_push_n :: #force_inline proc "contextless" (first: $ParentType, last, n: ^^$Type) { sll_queue_push_nz(first, last, n, nil) }
