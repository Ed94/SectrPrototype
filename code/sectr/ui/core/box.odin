package sectr

UI_BoxFlag :: enum u64
{
	Disabled,

	Focusable,
	Click_To_Focus,

	Mouse_Clickable,
	Keyboard_Clickable,

	Count,
}
UI_BoxFlags :: bit_set[UI_BoxFlag; u64]
// UI_BoxFlag_Scroll :: UI_BoxFlags { .Scroll_X, .Scroll_Y }

UI_NavLinks :: struct {
	left, right, up, down : ^UI_Box,
}

UI_Box :: struct {
	// Cache ID
	key   : UI_Key,
	label : StrCached,
	text  : StrCached,

	// Regenerated per frame.
	nav : UI_NavLinks,
	// signal_callback : #type proc(),

	// first, last : The first and last child of this box
	// prev, next  : The adjacent neighboring boxes who are children of to the same parent
	using links   : DLL_NodeFull( UI_Box ),
	parent        : ^UI_Box,
	num_children  : i32,
	ancestors     : i32, // This value for rooted widgets gets set to -1 after rendering see ui_box_make() for the reason.
	parent_index  : i32,

	flags    : UI_BoxFlags,
	computed : UI_Computed,

	layout : UI_Layout,
	style  : UI_Style,

	// Persistent Data
	hot_delta      : f32,
	active_delta   : f32,
	disabled_delta : f32,
	style_delta    : f32,
	first_frame    : b8,
	// root_order_id  : i16,
}

ui_box_equal :: #force_inline proc "contextless" ( a, b : ^ UI_Box ) -> b32 {
	BoxSize :: size_of(UI_Box)

	result : b32 = true
	result &= a.key   == b.key   // We assume for now the label is the same as the key, if not something is terribly wrong.
	result &= a.flags == b.flags
	return result
}

ui_box_from_key :: #force_inline proc ( cache : ^HMapChained(UI_Box), key : UI_Key ) -> (^UI_Box) {
	return hmap_chained_get( cache ^, cast(u64) key )
}

ui_box_make :: proc( flags : UI_BoxFlags, label : string ) -> (^ UI_Box)
{
	// profile(#procedure)
	using ui := get_state().ui_context
	key := ui_key_from_string( label )

	curr_box : (^ UI_Box)
	prev_box := hmap_chained_get( prev_cache ^, cast(u64) key )
	{
		// profile("Assigning current box")
		set_result : ^ UI_Box
		set_error  : AllocatorError
		if prev_box != nil
		{
			// Previous history was found, copy over previous state.
			set_result, set_error = hmap_chained_set( curr_cache ^, cast(u64) key, (prev_box ^) )
		}
		else {
			box : UI_Box
			box.key   = key
			box.label = str_intern( label )
			set_result, set_error = hmap_chained_set( curr_cache ^, cast(u64) key, box )
		}

		verify( set_error == AllocatorError.None, "Failed to set hmap_zpl due to allocator error" )
		curr_box             = set_result
		curr_box.first_frame = prev_box == nil
		curr_box.flags       = flags
	}

	// Clear non-persistent data
	curr_box.computed.fresh = false
	curr_box.links          = {}
	curr_box.num_children   = 0

	parent := ui_parent_peek()
	if parent != nil
	{
		dll_full_push_back( parent, curr_box, nil )
		curr_box.parent_index = parent.num_children
		parent.num_children  += 1
		curr_box.parent       = parent
		curr_box.ancestors    = parent.ancestors + 1
	}

	ui.built_box_count += 1
	return curr_box
}

ui_prev_cached_box :: #force_inline proc( box : ^UI_Box ) -> ^UI_Box { return hmap_chained_get( ui_context().prev_cache ^, cast(u64) box.key ) }

// TODO(Ed): Rename to ui_box_tranverse_view_next
// Traveral pritorizes immeidate children
ui_box_tranverse_next_depth_first :: #force_inline proc "contextless" (box : ^UI_Box, parent_limit : ^UI_Box = nil, bypass_intersection_test := false, ctx: ^UI_State = nil) -> ^UI_Box
{
	state := get_state(); using state
	ctx := ctx if ctx != nil else ui_context

	// If current has children, check if we should traverse them
	if box.first != nil {
		if bypass_intersection_test || intersects_range2(ui_view_bounds(ctx), box.computed.bounds) {
				return box.first
		}
	}

	// If no children or children are culled, try next sibling
	if box.next != nil {
			return box.next
	}

	// No more siblings, traverse up the tree
	parent := box.parent
	for parent != nil
	{
		if parent_limit != nil && parent_limit == parent {
			// We've reached the end of the parent_limit's tree.
			return nil
		}

		if parent.next != nil {
				return parent.next
		}
	
		parent = parent.parent
	}

	// We've reached the end of the tree
	return nil
}

// Traveral pritorizes traversing a "ancestry layer"
ui_box_traverse_next_breadth_first :: proc "contextless" ( box : ^UI_Box, bypass_intersection_test := false, ctx : ^UI_State = nil ) -> (^UI_Box)
{
	ctx := ctx
	if ctx == nil {
		ctx = ui_context()
	}

	parent := box.parent
	if parent != nil
	{
		if parent.last != box
		{
			if box.next != nil do return box.next
		}
		// There are no more adjacent nodes
	}

	// Either is root OR
	// Parent children exhausted, this should be the last box of this ancestry
	// Do children if they are available.
	if box.first != nil
	{
		// Check to make sure parent is present on the screen, if its not don't bother.
		if bypass_intersection_test {
			return box.first
		}
		if intersects_range2( ui_view_bounds(), box.computed.bounds) {
			return box.first
		}
	}

	// We should have exhausted the list if we're on the last box of teh last parent
	return nil
}
