package sectr

LL_Node :: struct ( $ Type : typeid ) {
	next  : ^Type,
}

ll_push :: #force_inline proc "contextless" ( list_ptr : ^(^ ($ Type)), node : ^Type ) {
	list       := (list_ptr^)
	node.next   = list
	(list_ptr^) = node
}

ll_pop :: #force_inline proc "contextless" ( list_ptr : ^(^ ($ Type)) ) -> ( node : ^Type ) {
	list       := (list_ptr^)
	(list_ptr^) = list.next
	return list
}

//region Intrusive Doubly-Linked-List

DLL_Node :: struct ( $ Type : typeid ) #raw_union {
	using _ : struct {
		left, right : ^Type,
	},
	using _ : struct {
		prev, next : ^Type,
	},
	using _ : struct {
		first, last : ^Type,
	},
	using _ : struct {
		bottom, top : ^Type,
	}
}

DLL_NodeFull :: struct ( $ Type : typeid ) {
	// using _ : DLL_NodeFL(Type),
	first, last : ^Type,
	prev, next : ^Type,
}

DLL_NodePN :: struct ( $ Type : typeid ) {
	using _ : struct {
		prev, next : ^Type,
	},
	using _ : struct {
		left, right : ^Type,
	},
}

DLL_NodeFL :: struct ( $ Type : typeid ) #raw_union {
	using _ : struct {
		first, last : ^Type,
	},

	// TODO(Ed): Review this
	using _ : struct {
		bottom, top: ^Type,
	},
}

type_is_node :: #force_inline proc  "contextless" ( $ Type : typeid ) -> bool
{
	// elem_type := type_elem_type(Type)
	return type_has_field( type_elem_type(Type), "prev" ) && type_has_field( type_elem_type(Type), "next" )
}

// First/Last append
dll_fl_append :: proc ( list : ^( $TypeList), node : ^( $TypeNode) )
{
	if list.first == nil {
		list.first = node
		list.last  = node
	}
	else {
		list.last = node
	}
}

dll_push_back :: proc "contextless" ( current_ptr : ^(^ ($ TypeCurr)), node : ^$TypeNode )
{
	current := (current_ptr ^)

	if current == nil
	{
		(current_ptr ^) = node
		node.prev       = nil
	}
	else
	{
		node.prev      = current
		(current_ptr^) = node
		current.next   = node
	}

	node.next = nil
}

dll_pop_back :: #force_inline proc "contextless" ( current_ptr : ^(^ ($ Type)) )
{
	to_remove := (current_ptr ^)
	if to_remove == nil {
		return
	}

	if to_remove.prev == nil {
		(current_ptr ^) = nil
	}
	else {
		(current_ptr ^)      = to_remove.prev
		(current_ptr ^).next = nil
	}
}

dll_full_insert_raw ::  proc "contextless" ( null : ^($ Type), parent, pos, node : ^Type )
{
	if parent.first == null {
		parent.first = node
		parent.last  = node
		node.next    = null
		node.prev    = null
	}
	else if pos == null {
		// Position is not set, insert at beginning
		node.next         = parent.first
		parent.first.prev = node
		parent.first      = node
		node.prev         = null
	}
	else if pos == parent.last {
		// Positin is set to last, insert at end
		parent.last.next = node
		node.prev        = parent.last
		parent.last      = node
		node.next        = null
	}
	else
	{
		if pos.next != null {
			pos.next.prev = node
		}
		node.next = pos.next
		pos.next  = node
		node.prev = pos
	}
}

dll_full_push_back :: proc "contextless" ( null : ^($ Type), parent, node : ^ Type ) {
	dll_full_insert_raw( null, parent, parent.last, node )
}

//endregion Intrusive Doubly-Linked-List
