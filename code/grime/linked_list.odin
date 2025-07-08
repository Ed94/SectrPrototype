/*
An intersive singly & double linked list implementation


*/
package grime

SLL_Node :: struct ($Type: typeid) {
	next: ^Type,
}

// ll_push :: proc( list_ptr : ^(^ ($ Type)), node : ^Type ) {
sll_push :: #force_inline proc "contextless" ( list_ptr : ^(^ ($ Type)), node : ^Type, node_next: ^(^Type) ) {
	list:         = (list_ptr ^)
	(node_next ^) = list
	(list_ptr  ^) = node
}

sll_pop :: #force_inline proc "contextless" ( list_ptr: ^(^ ($ Type)), list_next: ^(^Type) ) -> ( node : ^Type ) {
	list : ^Type = (list_ptr  ^)
	(list_ptr ^) = (list_next ^)
	return list
}

//#region("Intrusive Doubly-Linked-List")

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
	first, last : ^Type,
	prev, next  : ^Type,
}
DLL_NodePN :: struct ( $ Type : typeid ) {
	prev, next : ^Type,
}
DLL_NodeFL :: struct ( $ Type : typeid ) {
	first, last : ^Type,
}
DLL_NodeBT :: struct ($Type: typeid) {
	bottom, top: ^Type,
}
DLL_NodeLR :: struct ($Type: typeid) {
	left, right: ^Type,
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
	current : ^TypeCurr = (current_ptr ^)

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

dll_pn_pop :: proc "contextless" ( node : ^$Type )
{
	if node == nil {
		return
	}
	if node.prev != nil {
		node.prev.next = nil
		node.prev = nil
	}
	if node.next != nil {
		node.next.prev = nil
		node.next = nil
	}
}

dll_pop_back :: #force_inline proc "contextless" ( current_ptr : ^(^ ($ Type)) )
{
	to_remove : ^Type = (current_ptr ^)
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

dll_full_insert_raw ::  proc "contextless" ( null : ^($ Type), parent : ^$ParentType, pos, node : ^Type )
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

dll_full_pop :: proc "contextless" (  node : ^$NodeType, parent : ^$ParentType ) {
	if node == nil {
		return
	}
	if parent.first == node {
		parent.first = node.next
	}
	if parent.last == node {
		parent.last = node.prev
	}
	prev := node.prev
	next := node.next
	if prev != nil {
		prev.next = next
		node.prev = nil
	}
	if next != nil {
		next.prev = prev
		node.next = nil
	}
}

dll_full_push_back :: proc "contextless" ( parent : ^$ParentType, node : ^$Type, null : ^Type ) {
	dll_full_insert_raw( null, parent, parent.last, node )
}

//#endregion("Intrusive Doubly-Linked-List")
