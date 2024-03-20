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

	Count,
}
UI_BoxFlags :: bit_set[UI_BoxFlag; u64]
UI_BoxFlag_Scroll :: UI_BoxFlags { .Scroll_X, .Scroll_Y }

// The UI_Box's actual positioning and sizing
// There is an excess of rectangles here for debug puproses.
UI_Computed :: struct {
	anchors    : Range2, // Bounds for anchors within parent
	margins    : Range2, // Bounds for margins within parent
	bounds     : Range2, // Bounds for box itself
	padding    : Range2, // Bounds for padding's starting bounds (will be offset by border if there is one)
	content    : Range2, // Bounds for content (text or children)
	text_pos   : Vec2,   // Position of text within content
	text_size  : Vec2,   // Size of text within content
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

UI_ScalarConstraint :: struct {
	min, max : UI_Scalar,
}

UI_Scalar2 :: [Axis2.Count]UI_Scalar

// Desiered constraints on the UI_Box.
UI_Layout :: struct {
	anchor         : Range2,
	alignment      : Vec2,
	text_alignment : Vec2,

	border_width : UI_Scalar,

	margins : UI_LayoutSide,
	padding : UI_LayoutSide,

	// TODO(Ed): We cannot support individual corners unless we add it to raylib (or finally change the rendering backend)
	corner_radii : [Corner.Count]f32,

	// Position in relative coordinate space.
	// If the box's flags has Fixed_Position, then this will be its aboslute position in the relative coordinate space
	pos : Vec2,

	size : Range2,

	// TODO(Ed) :  Should thsi just always be WS_Pos for workspace UI?
	// (We can union either varient and just know based on checking if its the screenspace UI)
	// If the box is a child of the root parent, its automatically in world space and thus will use the tile_pos.
	// tile_pos : WS_Pos,
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
	cursor_over : b8,
	commit      : b8,
}

UI_StyleFlag :: enum u32 {

	// Will perform scissor pass on children to their parent's bounds
	// (Specified in the parent)
	Clip_Children_To_Bounds,

	// Enforces the box will always remain in a specific position relative to the parent.
	// Overriding the anchors and margins.
	Fixed_Position_X,
	Fixed_Position_Y,

	// Enforces box will always be within the bounds of the parent box.
	Clamp_Position_X,
	Clamp_Position_Y,

	// Enroces the widget will maintain its size reguardless of any constraints
	// Will override parent constraints
	Fixed_Width,
	Fixed_Height,

	// Sets the (0, 0) position of the child box to the parents anchor's center (post-margins bounds)
	// By Default, the origin is at the top left of the anchor's bounds
	Origin_At_Anchor_Center,

	// Will size the box to its text. (Padding & Margins will thicken )
	Size_To_Text,
	Text_Wrap,

	Count,
}
UI_StyleFlags :: bit_set[UI_StyleFlag; u32]

UI_StylePreset :: enum u32 {
	Default,
	Disabled,
	Hot,
	Active,
	Count,
}

UI_Style :: struct {
	flags : UI_StyleFlags,

	bg_color     : Color,
	border_color : Color,

	// TODO(Ed) : Add support for this eventually
	blur_size : f32,

	font           : FontID,
	// TODO(Ed): Should this get moved to the layout struct? Techncially font-size is mainly
	font_size      : f32,
	text_color     : Color,

	cursor : UI_Cursor,

	using layout : UI_Layout,

	 // Used with style, prev_style, and style_delta to produce a simple interpolated animation
	 // Applied in the layout pass & the rendering pass for their associated fields.
	transition_time : f32,
}

UI_StyleTheme :: struct #raw_union {
	array : [UI_StylePreset.Count] UI_Style,
	using styles : struct {
		default, disabled, hot, active : UI_Style,
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
	// mouse         : UI_InteractState,
	// keyboard      : UI_InteractState,
}

// UI_BoxFlags_Stack_Size    :: 512
UI_Layout_Stack_Size      :: 512
UI_Style_Stack_Size       :: 512
UI_Parent_Stack_Size      :: 512
UI_Built_Boxes_Array_Size :: 512

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
	hot_resizable   : b32,
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

	ui.built_box_count += 1
	return curr_box
}

ui_box_tranverse_next :: proc "contextless" ( box : ^ UI_Box ) -> (^ UI_Box)
{
	// Check to make sure parent is present on the screen, if its not don't bother.
	// If current has children, do them first
	if intersects_range2( view_get_bounds(), box.computed.bounds) && box.first != nil
	{
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
	return ui_cursor_pos() - state.ui_context.active_start_signal.cursor_pos
}

ui_graph_build_begin :: proc( ui : ^ UI_State, bounds : Vec2 = {} )
{
	profile(#procedure)

	get_state().ui_context = ui
	using get_state().ui_context

	curr_cache, prev_cache = swap( curr_cache, prev_cache )

	if ui.active == UI_Key(0) {
		//ui.hot = UI_Key(0)
		ui.active_start_signal = {}
	}
	if ui.hot == UI_Key(0) {
		ui.hot_resizable = false
	}

	ui.built_box_count = 0
	root = ui_box_make( {}, "root#001" )
	ui_parent_push(root)
}

// TODO(Ed) :: Is this even needed?
ui_graph_build_end :: proc()
{
	profile(#procedure)

	ui_parent_pop() // Should be ui_context.root

	// Regenerate the computed layout if dirty
	ui_compute_layout()

	get_state().ui_context = nil
}

@(deferred_none = ui_graph_build_end)
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
ui_parent :: proc( ui : ^UI_Box) {
	ui_parent_push( ui )
}

ui_style_peek :: proc( box_state : UI_StylePreset ) -> UI_Style {
	return stack_peek_ref( & get_state().ui_context.theme_stack ).array[box_state]
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

@(deferred_none = ui_style_theme_pop)
ui_theme_via_style :: proc ( style : UI_Style ) {
	ui_style_theme_push( UI_StyleTheme { styles = { style, style, style, style } })
}

ui_style_theme_set_layout :: proc ( layout : UI_Layout ) {
	for & preset in stack_peek_ref( & get_state().ui_context.theme_stack ).array {
		preset.layout = layout
	}
}
