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


// UI_BoxFlags_Stack_Size    :: 512
UI_Layout_Stack_Size      :: 512
UI_Style_Stack_Size       :: 512
UI_Parent_Stack_Size      :: 512
// UI_Built_Boxes_Array_Size :: 8
UI_Built_Boxes_Array_Size :: 128 * Kilobyte

UI_State :: struct {
	// TODO(Ed) : Use these
	// build_arenas : [2]Arena,
	// build_arena  : ^ Arena,

	built_box_count : i32,

	caches     : [2] HMapZPL( UI_Box ),
	prev_cache : ^HMapZPL( UI_Box ),
	curr_cache : ^HMapZPL( UI_Box ),

	render_queue : Array(UI_RenderBoxInfo),

	null_box : ^UI_Box, // This was used with the Linked list interface...
	// TODO(Ed): Should we change our convention for null boxes to use the above and nil as an invalid state?
	root     : ^UI_Box,
	// Children of the root node are unique in that they have their order preserved per frame
	// This is to support overlapping frames
	// So long as their parent-index is non-negative they'll be rendered

	// Do we need to recompute the layout?
	// layout_dirty  : b32,

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

	allocation_error : AllocatorError
	ui.render_queue, allocation_error = array_init_reserve( UI_RenderBoxInfo, cache_allocator, UI_Built_Boxes_Array_Size, fixed_cap = true )
	verify( allocation_error == AllocatorError.None, "Failed to allocate render queue" )

	log("ui_startup completed")
}

ui_reload :: proc( ui : ^ UI_State, cache_allocator : Allocator )
{
	// We need to repopulate Allocator references
	for & cache in & ui.caches {
		zpl_hmap_reload( & cache, cache_allocator)
	}
	ui.render_queue.backing = cache_allocator
}

// TODO(Ed) : Is this even needed?
ui_shutdown :: proc() {
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

ui_drag_delta :: #force_inline proc "contextless" () -> Vec2 {
	using state := get_state()
	return ui_cursor_pos() - state.ui_context.active_start_signal.cursor_pos
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

	stack_clear( & layout_combo_stack )
	stack_clear( & style_combo_stack )
	array_clear( render_queue )

	temp := prev_cache
	prev_cache = curr_cache
	curr_cache = temp
	// curr_cache, prev_cache = swap( curr_cache, prev_cache )

	if ui.active == UI_Key(0) {
		//ui.hot = UI_Key(0)
		ui.active_start_signal = {}
	}

	ui.built_box_count = 0
	root = ui_box_make( {}, str_intern(str_fmt_tmp("%s: root#001", ui == & state.screen_ui ? "Screen" : "Workspace" )).str)
	if ui == & state.screen_ui {
		root.layout.size = range2(Vec2(state.app_window.extent) * 2, {})
	}
	ui_parent_push(root)
}

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

ui_prev_cached_box :: #force_inline proc( box : ^UI_Box ) -> ^UI_Box {
	return zpl_hmap_get( ui_context().prev_cache, cast(u64) box.key )
}

// Topmost ancestor that is not the root
ui_top_ancestor :: #force_inline proc "contextless" ( box : ^UI_Box ) -> (^UI_Box) {
	using ui := get_state().ui_context
	ancestor := box
	for ; ancestor.parent != root; ancestor = ancestor.parent {}
	return ancestor
}

ui_context :: #force_inline proc() -> ^UI_State { return get_state().ui_context }
