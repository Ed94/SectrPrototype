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

type_is_node :: #force_inline proc  "contextless" ( $ Type : typeid ) -> b32
{
	// elem_type := type_elem_type(Type)
	return type_has_field( type_elem_type(Type), "prev" ) && type_has_field( type_elem_type(Type), "next" )
}

dll_insert_raw ::  proc "contextless" ( null, first, last, position, new : ^ DLL_Node( $ Type ) )
{
	// Empty Case
	if first == null {
		first     = new
		last      = new
		new.next  = null
		new.prev  = null
	}
	else if position == null {
		// Position is not set, insert at beginning
		new.next   = first
		first.prev = new
		first      = new
		new.prev   = null
	}
	else if position == last {
		// Positin is set to last, insert at end
		last.next = new
		new.prev  = last
		last      = new
		new.next  = null
	}
	else {
		// Insert around position
		if position.next != null {
			position.next.prev = new
		}
		new.next      = position.next
		position.next = new
		new.prev      = position
	}
}
