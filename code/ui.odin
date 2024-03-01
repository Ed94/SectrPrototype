package sectr

// TODO(Ed) : This is in Raddbg base_types.h, consider moving outside of UI.
Axis2 :: enum i32 {
	Invalid = -1,
	X       = 0,
	Y       = 1,
	Count,
}

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

Range2 :: struct #raw_union{
	using _ : struct {
		min, max : Vec2
	},
	using _ : struct {
		p0, p1 : Vec2
	},
	using _ : struct {
		x0, y0 : f32,
		x1, y1 : f32,
	},
}

Rect :: struct {
	top_left, bottom_right : Vec2
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
	Focusable,

	Mouse_Clickable,
	Keyboard_Clickable,
	Click_To_Focus,

	Fixed_With,
	Fixed_Height,

	Text_Wrap,

	Count,
}
UI_BoxFlags :: bit_set[UI_BoxFlag; u64]

// The UI_Box's actual positioning and sizing
// There is an excess of rectangles here for debug puproses.
UI_Computed :: struct {
	bounds  : Range2,
	border  : Range2,
	margin  : Range2,
	padding : Range2,
	content : Range2,
}

UI_LayoutSide :: struct #raw_union {
	using _ :  struct {
		top, bottom : UI_Scalar2,
		left, right : UI_Scalar2,
	}
}

UI_Cursor :: struct {
	placeholder : int,
}

UI_Key :: distinct u64

UI_Scalar :: f32

// TODO(Ed): I'm not sure if Percentage is needed or if this would over complicate things...
// UI_Scalar :: struct {
// 	VPixels    : f32,
// 	Percentage : f32,
// }

UI_ScalarConstraint :: struct {
	min, max : UI_Scalar,
}

UI_Scalar2 :: [Axis2.Count]UI_Scalar

// Desiered constraints on the UI_Box.
UI_Layout :: struct {
	// TODO(Ed) : Make sure this is all we need to represent an anchor.
	anchor : Range2,

	border_width : UI_Scalar,

	margins : UI_LayoutSide,
	padding : UI_LayoutSide,

	corner_radii : [Corner.Count]f32,

	// TODO(Ed) : Add support for this
	size_to_content : b32,
	size            : Vec2,
}

UI_BoxState :: enum {
	Disabled,
	Default,
	Hovered,
	Focused,
}

UI_Style :: struct {
	bg_color     : Color,
	border_color : Color,

	blur_size : f32,

	font           : FontID,
	font_size      : f32,
	text_color     : Color,
	text_alignment : UI_TextAlign,

	cursor : UI_Cursor,

	layout : UI_Layout,

	transition_time : f32,
}

UI_TextAlign :: enum u32 {
	Left,
	Center,
	Right,
	Count
}

UI_InteractState :: struct {
	hot_time      : f32,
	active_time   : f32,
	disabled_time : f32,
}

UI_Box :: struct {
	// Cache ID
	key   : UI_Key,
	label : string,

	// Regenerated per frame.
	using _      : DLL_NodeFull( UI_Box ), // first, last, prev, next
	parent       : ^ UI_Box,
	num_children : i32,

	flags    : UI_BoxFlags,
	computed : UI_Computed,
	style    : UI_Style,

	// Persistent Data
	// hash_links : DLL_Node_PN( ^ UI_Box), // This isn't necessary if not using RJF hash table.
	// prev_computed : UI_Computed,
	// prev_style    : UI_Style,v
	mouse         : UI_InteractState,
	keyboard      : UI_InteractState,
}

UI_Layout_Stack_Size      :: 512
UI_Style_Stack_Size       :: 512
UI_Parent_Stack_Size      :: 1024
UI_Built_Boxes_Array_Size :: Kilobyte * 8

UI_FramePassKind :: enum {
	Generate,
	Compute,
	Logical,
}

UI_State :: struct {
	// TODO(Ed) : Use these
	build_arenas : [2]Arena,
	build_arena  : ^ Arena,

	built_box_count : i32,

	caches     : [2] HMapZPL( UI_Box ),
	prev_cache : ^ HMapZPL( UI_Box ),
	curr_cache : ^ HMapZPL( UI_Box ),

	root : ^ UI_Box,

	// Do we need to recompute the layout?
	layout_dirty  : b32,

	// TODO(Ed) : Look into using a build arena like Ryan does for these possibly (and thus have a linked-list stack)
	style_stack   : Stack( UI_Style,  UI_Style_Stack_Size ),
	parent_stack  : Stack( ^ UI_Box,  UI_Parent_Stack_Size ),

	hot            : UI_Key,
	active         : UI_Key,
	clipboard_copy : UI_Key,
	last_clicked   : UI_Key,

	drag_start_mouse : Vec2,
	// drag_state_arena : ^ Arena,
	// drag_state data  : string,
}

ui_key_from_string :: proc( value : string ) -> UI_Key {
	key := cast(UI_Key) crc32( transmute([]byte) value )
	return key
}

ui_box_equal :: proc( a, b : ^ UI_Box ) -> b32 {
	BoxSize :: size_of(UI_Box)

	result : b32 = true
	result &= a.key   == b.key   // We assume for now the label is the same as the key, if not something is terribly wrong.
	result &= a.flags == b.flags

	return result
}

ui_startup :: proc( ui : ^ UI_State, cache_allocator : Allocator )
{
	ui := ui
	ui^ = {}

	for cache in (& ui.caches) {
		box_cache, allocation_error := zpl_hmap_init_reserve( UI_Box, cache_allocator, UI_Built_Boxes_Array_Size )
		verify( allocation_error == AllocatorError.None, "Failed to allocate box cache" )
		cache = box_cache
	}

	ui.curr_cache = & ui.caches[1]
	ui.prev_cache = & ui.caches[0]
}

ui_reload :: proc( ui : ^ UI_State, cache_allocator : Allocator )
{
	// We need to repopulate Allocator references
	for cache in & ui.caches {
		cache.entries.allocator = cache_allocator
		cache.hashes.allocator  = cache_allocator
	}
}

// TODO(Ed) : Is this even needed?
ui_shutdown :: proc() {
}

ui_graph_build_begin :: proc( ui : ^ UI_State, bounds : Vec2 = {} )
{
	get_state().ui_context = ui
	using get_state().ui_context

	swap( & curr_cache, & prev_cache )

	root = ui_box_make( {}, "root#001" )
	ui_parent_push(root)

	log("BUILD GRAPH BEGIN")
}

// TODO(Ed) :: Is this even needed?
ui_graph_build_end :: proc()
{
	ui_parent_pop()

	// Regenerate the computed layout if dirty
	// ui_compute_layout()

	get_state().ui_context = nil
	log("BUILD GRAPH END")
}

@(deferred_none = ui_graph_build_end)
ui_graph_build :: proc( ui : ^ UI_State ) {
	ui_graph_build_begin( ui )
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
ui_parent :: proc( ui : ^ UI_Box) {
	ui_parent_push( ui )
}

ui_box_make :: proc( flags : UI_BoxFlags, label : string ) -> (^ UI_Box)
{
	using get_state().ui_context

	key := ui_key_from_string( label )

	curr_box : (^ UI_Box)
	prev_box := zpl_hmap_get( prev_cache, cast(u64) key )
	{
		set_result : ^ UI_Box
		set_error  : AllocatorError
		if prev_box != nil {
			// Previous history was found, copy over previous state.
			set_result, set_error = zpl_hmap_set( curr_cache, cast(u64) key, (prev_box ^) )
		}
		else {
			box : UI_Box
			box.key    = key
			box.label  = label
			set_result, set_error = zpl_hmap_set( curr_cache, cast(u64) key, box )
		}

		verify( set_error == AllocatorError.None, "Failed to set zpl_hmap due to allocator error" )
		curr_box = set_result
	}

	if prev_box != nil {
		layout_dirty &= ! ui_box_equal( curr_box, prev_box )
	}
	else {
		layout_dirty = true
	}

	curr_box.flags  = flags
	curr_box.style  = ( stack_peek( & style_stack )  ^ )
	curr_box.parent = ( stack_peek( & parent_stack ) ^ )

	// If there is a parent, setup the relevant references
	if curr_box.parent != nil
	{
		// dbl_linked_list_push_back( box.parent, nil, box )
		curr_box.parent.last = curr_box

		if curr_box.parent.first == nil {
			curr_box.parent.first = curr_box
		}
	}

	return curr_box
}

ui_set_layout :: proc ( layout : UI_Layout ) {
	log("LAYOUT SET")
}

ui_compute_layout :: proc() {
	// TODO(Ed) : This generates the bounds for each box.
}

ui_layout_set_size :: proc( size : Vec2 ) {
}

ui_style_push :: proc( preset : UI_Style ) {
	log("STYLE PUSH")
	stack_push( & get_state().ui_context.style_stack, preset )
}

ui_style_pop :: proc() {
	log("STYLE POP")
	stack_pop( & get_state().ui_context.style_stack )
}

@(deferred_none = ui_style_pop)
ui_style :: proc( preset : UI_Style ) {
	ui_style_push( preset )
}
