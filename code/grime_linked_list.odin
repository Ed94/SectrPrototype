// I'm not sure about this, it was created to figure out Ryan's linked-list usage in the UI module of the RAD Debugger.
// The code takes advantage of macros for the linked list interface in a way that odin doesn't really permit without a much worse interface.
package sectr

DLL_Node :: struct ( $ Type : typeid ) #raw_union {
	using _ : struct {
		left, right : ^ Type,
	},
	using _ : struct {
		prev, next : ^ Type,
	},
	using _ : struct {
		first, last : ^ Type,
	},
}

DLL_NodeFull :: struct ( $ Type : typeid ) {
	first, last, prev, next : ^ Type,
}

DLL_NodeLR :: struct ( $ Type : typeid ) {
	left, right : ^ Type,
}

DLL_NodePN :: struct ( $ Type : typeid ) {
	prev, next : ^ Type,
}

DLL_NodeFL :: struct ( $ Type : typeid ) {
	first, last : ^ Type,
}

type_is_node :: #force_inline proc  "contextless" ( $ Type : typeid ) -> bool
{
	// elem_type := type_elem_type(Type)
	return type_has_field( type_elem_type(Type), "prev" ) && type_has_field( type_elem_type(Type), "next" )
}

dll_full_insert_raw ::  proc "contextless" ( null : ^($ Type), parent, pos, node : ^ Type )
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
