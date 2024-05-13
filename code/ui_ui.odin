package sectr

import "base:runtime"

// TODO(Ed) : This is in Raddbg base_types.h, consider moving outside of UI.

Corner :: enum i32 {
	Invalid = -1,
	_00,
	_01,
	_10,
	_11,
	TopLeft     = _00,
	TopRight    = _01,
	BottomLeft  = _10,
	BottomRight = _11,
	Count = 4,
}

Side :: enum i32 {
	Invalid = -1,
	Min     = 0,
	Max     = 1,
	Count
}

// Side2 :: enum u32 {
// 	Top,
// 	Bottom,
// 	Left,
// 	Right,
// 	Count,
// }

UI_AnchorPresets :: enum u32 {
	Top_Left,
	Top_Right,
	Bottom_Right,
	Bottom_Left,
	Center_Left,
	Center_Top,
	Center_Right,
	Center_Bottom,
	Center,
	Left_Wide,
	Top_Wide,
	Right_Wide,
	Bottom_Wide,
	VCenter_Wide,
	HCenter_Wide,
	Full,
	Count,
}

UI_BoxFlag :: enum u64 {
	Disabled,

	Focusable,
	Click_To_Focus,

	Mouse_Clickable,
	Mouse_Resizable,

	Keyboard_Clickable,

	Scroll_X,
	Scroll_Y,

	Pan_X,
	Pan_Y,

	Screenspace,

	Count,
}
UI_BoxFlags :: bit_set[UI_BoxFlag; u64]
UI_BoxFlag_Scroll :: UI_BoxFlags { .Scroll_X, .Scroll_Y }

UI_Cursor :: struct {
	placeholder : int,
}

UI_FramePassKind :: enum {
	Generate,
	Compute,
	Logical,
}

UI_InteractState :: struct {
	hot_time      : f32,
	active_time   : f32,
	disabled_time : f32,
}

UI_Key :: distinct u64

UI_Scalar :: f32

UI_ScalarConstraint :: struct {
	min, max : UI_Scalar,
}

UI_Scalar2 :: [Axis2.Count]UI_Scalar

UI_Box :: struct {
	// Cache ID
	key   : UI_Key,
	// label : string,
	label : StrRunesPair,
	text  : StrRunesPair,

	// Regenerated per frame.
	using links   : DLL_NodeFull( UI_Box ), // first, last, prev, next
	parent        : ^UI_Box,
	num_children  : i32,
	ancestors     : i32,
	parent_index  : i32,

	flags    : UI_BoxFlags,
	computed : UI_Computed,

	prev_layout : UI_Layout,
	layout      : UI_Layout,

	prev_style : UI_Style,
	style      : UI_Style,

	// Persistent Data
	first_frame    : b8,
	hot_delta      : f32,
	active_delta   : f32,
	disabled_delta : f32,
	style_delta    : f32,
	// root_order_id  : i16,

	// prev_computed : UI_Computed,
	// prev_style    : UI_Style,v
	// mouse         : UI_InteractState,
	// keyboard      : UI_InteractState,
}

// UI_BoxFlags_Stack_Size    :: 512
UI_Layout_Stack_Size      :: 512
UI_Style_Stack_Size       :: 512
UI_Parent_Stack_Size      :: 512
// UI_Built_Boxes_Array_Size :: 8
UI_Built_Boxes_Array_Size :: 16 * Kilobyte

UI_State :: struct {
	// TODO(Ed) : Use these
	build_arenas : [2]Arena,
	build_arena  : ^ Arena,

	built_box_count : i32,

	caches     : [2] HMapZPL( UI_Box ),
	prev_cache : ^HMapZPL( UI_Box ),
	curr_cache : ^HMapZPL( UI_Box ),

	null_box : ^UI_Box, // Ryan had this, I don't know why yet.
	root     : ^UI_Box,
	// Children of the root node are unique in that they have their order preserved per frame
	// This is to support overlapping frames
	// So long as their parent-index is non-negative they'll be rendered

	// Do we need to recompute the layout?
	layout_dirty  : b32,

	// TODO(Ed) : Look into using a build arena like Ryan does for these possibly (and thus have a linked-list stack)
	layout_combo_stack : StackFixed( UI_LayoutCombo, UI_Style_Stack_Size ),
	style_combo_stack  : StackFixed( UI_StyleCombo,  UI_Style_Stack_Size ),
	parent_stack       : StackFixed( ^UI_Box, UI_Parent_Stack_Size ),
	// flag_stack    : Stack( UI_BoxFlags, UI_BoxFlags_Stack_Size ),

	hot             : UI_Key,
	hot_start_style : UI_Style,

	active_mouse        : [MouseBtn.count] UI_Key,
	active              : UI_Key,
	active_start_signal : UI_Signal,

	clipboard_copy : UI_Key,
	last_clicked   : UI_Key,

	active_start_style : UI_Style,

	last_pressed_key    : [MouseBtn.count] UI_Key,
	last_pressed_key_us : [MouseBtn.count] f32,
}

ui_startup :: proc( ui : ^ UI_State, cache_allocator : Allocator /* , cache_reserve_size : u64 */ )
{
	ui := ui
	ui^ = {}

	// cache.ref in ui.caches.ref
	for & cache in (& ui.caches) {
		box_cache, allocation_error := zpl_hmap_init_reserve( UI_Box, cache_allocator, UI_Built_Boxes_Array_Size )
		verify( allocation_error == AllocatorError.None, "Failed to allocate box cache" )
		cache = box_cache
	}
	ui.curr_cache = (& ui.caches[1])
	ui.prev_cache = (& ui.caches[0])

	log("ui_startup completed")
}

ui_reload :: proc( ui : ^ UI_State, cache_allocator : Allocator )
{
	// We need to repopulate Allocator references
	for cache in & ui.caches {
		cache.entries.backing = cache_allocator
		cache.hashes.backing  = cache_allocator
	}
}

// TODO(Ed) : Is this even needed?
ui_shutdown :: proc() {
}

ui_box_equal :: #force_inline proc "contextless" ( a, b : ^ UI_Box ) -> b32 {
	BoxSize :: size_of(UI_Box)

	result : b32 = true
	result &= a.key   == b.key   // We assume for now the label is the same as the key, if not something is terribly wrong.
	result &= a.flags == b.flags
	return result
}

ui_box_from_key :: #force_inline proc ( cache : ^HMapZPL(UI_Box), key : UI_Key ) -> (^UI_Box) {
	return zpl_hmap_get( cache, cast(u64) key )
}

ui_box_make :: proc( flags : UI_BoxFlags, label : string ) -> (^ UI_Box)
{
	// profile(#procedure)

	using ui := get_state().ui_context

	key := ui_key_from_string( label )

	curr_box : (^ UI_Box)
	prev_box := zpl_hmap_get( prev_cache, cast(u64) key )
	{
		// profile("Assigning current box")

		set_result : ^ UI_Box
		set_error  : AllocatorError
		if prev_box != nil
		{
			// Previous history was found, copy over previous state.
			set_result, set_error = zpl_hmap_set( curr_cache, cast(u64) key, (prev_box ^) )
		}
		else {
			box : UI_Box
			box.key   = key
			box.label = str_intern( label )
			// set_result, set_error = zpl_hmap_set( prev_cache, cast(u64) key, box )
			set_result, set_error = zpl_hmap_set( curr_cache, cast(u64) key, box )
		}

		verify( set_error == AllocatorError.None, "Failed to set zpl_hmap due to allocator error" )
		curr_box = set_result

		curr_box.first_frame = prev_box == nil
	}

	curr_box.flags = flags

	// Clear non-persistent data
	curr_box.computed.fresh = false
	curr_box.links          = {}
	curr_box.num_children   = 0
	curr_box.parent         = nil
	// curr_box.ancestors      = 0
	curr_box.parent_index   = -1

	// If there is a parent, setup the relevant references
	parent := stack_peek( & parent_stack )
	if curr_box.ancestors == 0 && prev_box != nil
	{
		set_error : AllocatorError
		if prev_box.first != nil {
			curr_box.first, set_error = zpl_hmap_set( curr_cache, cast(u64) prev_box.first.key, prev_box.first ^ )
			verify( set_error == AllocatorError.None, "Failed to set zpl_hmap due to allocator error" )
		}
		if prev_box.last != nil {
			curr_box.last, set_error = zpl_hmap_set( curr_cache, cast(u64) prev_box.last.key, prev_box.last ^ )
			verify( set_error == AllocatorError.None, "Failed to set zpl_hmap due to allocator error" )
		}
	}
	if parent != nil
	{
		if curr_box.ancestors != 1
		{
			dll_full_push_back( parent, curr_box, null_box )
			curr_box.parent_index = parent.num_children
			parent.num_children  += 1
			curr_box.parent       = parent
			curr_box.ancestors    = parent.ancestors + 1
		}
		else if prev_box != nil
		{
			// Order was previously restored, restore linkage
			if prev_box.prev != nil {
				curr_box.prev = zpl_hmap_get( curr_cache, cast(u64) prev_box.prev.key )
			}
			if prev_box.next != nil {
				curr_box.next = zpl_hmap_get( curr_cache, cast(u64) prev_box.next.key )
			}
			curr_box.parent       = ui.root
			curr_box.ancestors    = 1
			curr_box.parent_index = ui.root.num_children
			parent.num_children  += 1
		}
	}

	ui.built_box_count += 1
	return curr_box
}

ui_box_tranverse_next :: proc "contextless" ( box : ^ UI_Box ) -> (^ UI_Box)
{
	// Check to make sure parent is present on the screen, if its not don't bother.
	// If current has children, do them first
	using state := get_state()
	if box.first != nil
	{
		is_app_ui := ui_context == & screen_ui
		if is_app_ui || intersects_range2( view_get_bounds(), box.computed.bounds)
		{
			return box.first
		}
	}

	if box.next == nil
	{
		// There is no more adjacent nodes
		if box.parent != nil {
			// Lift back up to parent, and set it to its next.
			return box.parent.next
		}
	}

	return box.next
}

ui_cursor_pos :: #force_inline proc "contextless" () -> Vec2 {
	using state := get_state()
	if ui_context == & state.project.workspace.ui {
		return screen_to_ws_view_pos( input.mouse.pos )
	}
	else {
		return input.mouse.pos
	}
}

ui_ws_drag_delta :: #force_inline proc "contextless" () -> Vec2 {
	using state := get_state()
	return screen_to_ws_view_pos(input.mouse.pos) - state.ui_context.active_start_signal.cursor_pos
}

ui_graph_build_begin :: proc( ui : ^ UI_State, bounds : Vec2 = {} )
{
	profile(#procedure)

	state := get_state()
	get_state().ui_context = ui
	using get_state().ui_context

	if root != nil
	{
		// Set all top-level widgets to a negative index
		// This will be used for prunning the rooted_children order
		// for box := ui.root.first; box != nil; box = box.next {
		// 	box.parent_index = -1
		// }
	}

	temp := prev_cache
	prev_cache = curr_cache
	curr_cache = temp
	// curr_cache, prev_cache = swap( curr_cache, prev_cache )

	if ui.active == UI_Key(0) {
		//ui.hot = UI_Key(0)
		ui.active_start_signal = {}
	}

	ui.built_box_count = 0
	root = ui_box_make( {}, "root#001" )
	if ui == & state.screen_ui {
		root.layout.size = range2(Vec2(state.app_window.extent) * 2, {})
	}
	ui_parent_push(root)
}

// TODO(Ed) :: Is this even needed?
ui_graph_build_end :: proc( ui : ^UI_State )
{
	profile(#procedure)

	ui_parent_pop() // Should be ui_context.root

	// Regenerate the computed layout if dirty
	ui_compute_layout( ui )

	get_state().ui_context = nil
}

@(deferred_in = ui_graph_build_end)
ui_graph_build :: proc( ui : ^ UI_State ) {
	ui_graph_build_begin( ui )
}

ui_key_from_string :: #force_inline proc "contextless" ( value : string ) -> UI_Key
{
	// profile(#procedure)
	USE_RAD_DEBUGGERS_METHOD :: true

	key : UI_Key

	when USE_RAD_DEBUGGERS_METHOD {
		hash : u64
		for str_byte in transmute([]byte) value {
			hash = ((hash << 5) + hash) + u64(str_byte)
		}
		key = cast(UI_Key) hash
	}

	when ! USE_RAD_DEBUGGERS_METHOD {
		key = cast(UI_Key) crc32( transmute([]byte) value )
	}

	return key
}

ui_parent_push :: proc( ui : ^ UI_Box ) {
	stack := & get_state().ui_context.parent_stack
	stack_push( & get_state().ui_context.parent_stack, ui )
}

ui_parent_pop :: proc() {
	// If size_to_content is set, we need to compute the layout now.

	// Check to make sure that the parent's children are the same for this frame,
	// if its not we need to mark the layout as dirty.

	stack_pop( & get_state().ui_context.parent_stack )
}

@(deferred_none = ui_parent_pop)
ui_parent :: #force_inline proc( ui : ^UI_Box) { ui_parent_push( ui ) }

// Topmost ancestor that is not the root
ui_top_ancestor :: #force_inline proc "contextless" ( box : ^UI_Box ) -> (^UI_Box) {
	using ui := get_state().ui_context
	ancestor := box
	for ; ancestor.parent != root; ancestor = ancestor.parent {}
	return ancestor
}

ui_context :: #force_inline proc() -> ^UI_State { return get_state().ui_context }
