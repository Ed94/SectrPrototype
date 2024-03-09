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

	Mouse_Clickable,
	Keyboard_Clickable,
	Click_To_Focus,

	Scroll_X,
	Scroll_Y,

	Pan_X,
	Pan_Y,

	Count,
}
UI_BoxFlags :: bit_set[UI_BoxFlag; u64]
UI_BoxFlag_Scroll :: UI_BoxFlags { .Scroll_X, .Scroll_Y }

// The UI_Box's actual positioning and sizing
// There is an excess of rectangles here for debug puproses.
UI_Computed :: struct {
	bounds     : Range2,
	padding    : Range2,
	content    : Range2,
	text_pos   : Vec2,
	text_size  : Vec2,
}

UI_LayoutSide :: struct {
	// using _ :  struct {
		top, bottom : UI_Scalar,
		left, right : UI_Scalar,
	// }
}

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
	// TODO(Ed) : Should layout have its own flags (separate from the style flags)
	// flags : UI_LayoutFlags

	// TODO(Ed) : Make sure this is all we need to represent an anchor.
	anchor         : Range2,
	alignment      : Vec2,
	text_alignment : Vec2,

	border_width : UI_Scalar,

	margins : UI_LayoutSide,
	padding : UI_LayoutSide,

	corner_radii : [Corner.Count]f32,

	// Position in relative coordinate space.
	// If the box's flags has Fixed_Position, then this will be its aboslute position in the relative coordinate space
	pos : Vec2,
	// TODO(Ed) : Should everything no matter what its parent is use a WS_Pos instead of a raw vector pos?

	// If the box is a child of the root parent, its automatically in world space and thus will use the tile_pos.
	tile_pos : WS_Pos,

	// TODO(Ed) : Add support for size_to_content?
	// size_to_content : b32,
	size : Vec2,
}

UI_Signal :: struct {
	cursor_pos : Vec2,
	drag_delta : Vec2,
	scroll     : Vec2,

	left_clicked     : b8,
	right_clicked    : b8,
	double_clicked   : b8,
	keyboard_clicked : b8,

	pressed     : b8,
	released    : b8,
	dragging    : b8,
	resizing    : b8,
	hovering    : b8,
	cursor_over : b8,
	commit      : b8,
}

UI_StyleFlag :: enum u32 {
	Fixed_Position_X,
	Fixed_Position_Y,
	Fixed_Width,
	Fixed_Height,

	Text_Wrap,

	Count,
}
UI_StyleFlags :: bit_set[UI_StyleFlag; u32]

UI_StylePreset :: enum u32 {
	Default,
	Disabled,
	Hovered,
	Focused,
	Count,
}

UI_Style :: struct {
	flags : UI_StyleFlags,

	bg_color     : Color,
	border_color : Color,

	blur_size : f32,

	font           : FontID,
	font_size      : f32,
	text_color     : Color,

	cursor : UI_Cursor,

	using layout : UI_Layout,

	transition_time : f32,
}

UI_StyleTheme :: struct #raw_union {
	array : [UI_StylePreset.Count] UI_Style,
	using styles : struct {
		default, disabled, hovered, focused : UI_Style,
	}
}

UI_TextAlign :: enum u32 {
	Left,
	Center,
	Right,
	Count
}

UI_Box :: struct {
	// Cache ID
	key   : UI_Key,
	// label : string,
	label : StringCached,
	text  : StringCached,

	// Regenerated per frame.
	using links  : DLL_NodeFull( UI_Box ), // first, last, prev, next
	parent       : ^UI_Box,
	num_children : i32,

	flags      : UI_BoxFlags,
	computed   : UI_Computed,
	prev_style : UI_Style,
	style      : UI_Style,

	// Persistent Data
	first_frame    : b8,
	hot_delta      : f32,
	active_delta   : f32,
	disabled_delta : f32,
	style_delta    : f32,

	// prev_computed : UI_Computed,
	// prev_style    : UI_Style,v
	mouse         : UI_InteractState,
	keyboard      : UI_InteractState,
}

// UI_BoxFlags_Stack_Size    :: 512
UI_Layout_Stack_Size      :: 512
UI_Style_Stack_Size       :: 512
UI_Parent_Stack_Size      :: 1024
UI_Built_Boxes_Array_Size :: 1024

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

	// Do we need to recompute the layout?
	layout_dirty  : b32,

	// TODO(Ed) : Look into using a build arena like Ryan does for these possibly (and thus have a linked-list stack)
	theme_stack  : StackFixed( UI_StyleTheme, UI_Style_Stack_Size ),
	parent_stack : StackFixed( ^UI_Box, UI_Parent_Stack_Size ),
	// flag_stack    : Stack( UI_BoxFlags, UI_BoxFlags_Stack_Size ),

	hot             : UI_Key,
	active_mouse    : [MouseBtn.count] UI_Key,
	active          : UI_Key,
	hot_resizable   : b32,
	active_resizing : b32, // Locks the user into a resizing state for the active box until they release the active key

	clipboard_copy : UI_Key,
	last_clicked   : UI_Key,

	cursor_active_start  : Vec2,

	hot_start_style    : UI_Style,
	active_start_style : UI_Style,

	last_pressed_key    : [MouseBtn.count] UI_Key,
	last_pressed_key_us : [MouseBtn.count] f32,
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

ui_box_equal :: proc( a, b : ^ UI_Box ) -> b32 {
	BoxSize :: size_of(UI_Box)

	result : b32 = true
	result &= a.key   == b.key   // We assume for now the label is the same as the key, if not something is terribly wrong.
	result &= a.flags == b.flags
	return result
}

ui_box_make :: proc( flags : UI_BoxFlags, label : string ) -> (^ UI_Box)
{
	using ui := get_state().ui_context

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
			box.label  = str_intern( label )
			set_result, set_error = zpl_hmap_set( curr_cache, cast(u64) key, box )
		}

		verify( set_error == AllocatorError.None, "Failed to set zpl_hmap due to allocator error" )
		curr_box = set_result

		curr_box.first_frame = prev_box == nil
	}

	curr_box.flags  = flags
	curr_box.parent = stack_peek( & parent_stack )

	// Clear old links
	curr_box.parent = nil
	curr_box.links  = {}
	curr_box.num_children = 0

	// If there is a parent, setup the relevant references
	parent := stack_peek( & parent_stack )
	if parent != nil
	{
		dll_full_push_back( null_box, parent, curr_box )
		parent.num_children += 1
		curr_box.parent      = parent
	}

	return curr_box
}

ui_box_tranverse_next :: proc( box : ^ UI_Box ) -> (^ UI_Box) {
	// If current has children, do them first
	if box.first != nil {
		return box.first
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
		return screen_to_world( input.mouse.pos )
	}
	else {
		return input.mouse.pos
	}
}

ui_drag_delta :: #force_inline proc "contextless" () -> Vec2 {
	using state := get_state()
	return ui_cursor_pos() - state.ui_context.cursor_active_start
}

ui_graph_build_begin :: proc( ui : ^ UI_State, bounds : Vec2 = {} )
{
	get_state().ui_context = ui
	using get_state().ui_context

	curr_cache, prev_cache = swap( curr_cache, prev_cache )

	if ui.active == UI_Key(0) {
		ui.hot = UI_Key(0)
	}

	root = ui_box_make( {}, "root#001" )
	ui_parent_push(root)
}

// TODO(Ed) :: Is this even needed?
ui_graph_build_end :: proc()
{
	ui_parent_pop() // Should be ui_context.root

	// Regenerate the computed layout if dirty
	ui_compute_layout()

	get_state().ui_context = nil
}

@(deferred_none = ui_graph_build_end)
ui_graph_build :: proc( ui : ^ UI_State ) {
	ui_graph_build_begin( ui )
}

ui_key_from_string :: proc( value : string ) -> UI_Key {
	key := cast(UI_Key) xxh32( transmute([]byte) value )
	return key
}

ui_layout_padding :: proc( pixels : f32 ) -> UI_LayoutSide {
	return { pixels, pixels, pixels, pixels }
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

ui_style_ref :: proc( box_state : UI_StylePreset ) -> (^ UI_Style) {
	return & stack_peek_ref( & get_state().ui_context.theme_stack ).array[box_state]
}

ui_style_set :: proc ( style : UI_Style, box_state : UI_StylePreset ) {
	stack_peek_ref( & get_state().ui_context.theme_stack ).array[box_state] = style
}

ui_style_set_layout :: proc ( layout : UI_Layout, preset : UI_StylePreset ) {
	stack_peek_ref( & get_state().ui_context.theme_stack ).array[preset].layout = layout
}

ui_style_theme_push :: proc( preset : UI_StyleTheme ) {
	push( & get_state().ui_context.theme_stack, preset )
}

ui_style_theme_pop :: proc() {
	pop( & get_state().ui_context.theme_stack )
}

@(deferred_none = ui_style_theme_pop)
ui_style_theme :: proc( preset : UI_StyleTheme ) {
	ui_style_theme_push( preset )
}

ui_style_theme_set_layout :: proc ( layout : UI_Layout ) {
	for & preset in stack_peek_ref( & get_state().ui_context.theme_stack ).array {
		preset.layout = layout
	}
}
