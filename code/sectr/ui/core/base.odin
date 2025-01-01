package sectr

import "base:runtime"

// TODO(Ed) : This is in Raddbg base_types.h, consider moving outside of UI.

Corner :: enum i32 {
	Invalid = -1,
	_00,
	_01,
	_10,
	_11,
	Top_Left     = _00,
	Top_Right    = _01,
	Bottom_Left  = _10,
	Bottom_Right = _11,
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
UI_Built_Boxes_Array_Size :: 56 * Kilobyte
UI_BoxCache_TableSize     :: 8 * Kilobyte

UI_RenderEntry :: struct {
	info        : UI_RenderBoxInfo,
	using links : DLL_NodeFull(UI_RenderEntry),
	parent      : ^UI_RenderEntry,
	layer_id    : i32,
}

UI_RenderLayer :: DLL_NodeFL(UI_RenderEntry)

// UI_RenderBoxInfo :: struct {
// 	using computed : UI_Computed,
// 	using style    : UI_Style,
// 	text           : StrRunesPair,
// 	font_size      : UI_Scalar,
// 	border_width   : UI_Scalar,
// 	label          : StrRunesPair,
// 	layer_signal   : b32,
// }

UI_RenderBoxInfo :: struct {
	bounds       : Range2,
	corner_radii : [Corner.Count]f32,
	bg_color     : RGBA8,
	border_color : RGBA8,
	border_width : UI_Scalar,
	layer_signal : b8,
}

UI_RenderTextInfo :: struct {
	text         : string,
	position     : Vec2,
	color        : RGBA8,
	font         : FontID,
	font_size    : f32,
	layer_signal : b8
}

UI_RenderMethod :: enum u32 {
	Depth_First,
	Layers,
}

UI_Render_Method :: UI_RenderMethod.Layers

// TODO(Ed): Rename to UI_Context
UI_State :: struct {
	// TODO(Ed) : Use these?
	// build_arenas : [2]Arena,
	// build_arena  : ^ Arena,

	built_box_count : i32,

	caches     : [2] HMapChained( UI_Box ),
	prev_cache : ^HMapChained( UI_Box ),
	curr_cache : ^HMapChained( UI_Box ),

	// TODO(Ed): DO WE ACTUALLY NEED THIS?
	spacial_indexing_method : UI_SpacialIndexingMethod,

	// For rendering via a set of layers organized into a single command list
	// render_queue_builder : SubArena,
	// render_queue         : Array(UI_RenderLayer),
	// render_list          : Array(UI_RenderBoxInfo),
	render_list_box      : Array(UI_RenderBoxInfo),
	render_list_text     : Array(UI_RenderTextInfo),

	null_box : ^UI_Box, // This was used with the Linked list interface...
	root     : ^UI_Box,

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

	last_invalid_input_time : Time,
}

#region("Lifetime")

ui_startup :: proc( ui : ^ UI_State, spacial_indexing_method : UI_SpacialIndexingMethod = .QuadTree, cache_allocator : Allocator, cache_table_size : uint )
{
	ui := ui
	ui^ = {}

	for & cache in ui.caches {
		box_cache, allocation_error := make( HMapChained(UI_Box), cache_table_size, cache_allocator )
		verify( allocation_error == AllocatorError.None, "Failed to allocate box cache" )
		cache = box_cache
	}
	ui.curr_cache = (& ui.caches[1])
	ui.prev_cache = (& ui.caches[0])

	allocation_error : AllocatorError

	// ui.render_queue, allocation_error = make( Array(UI_RenderLayer), 32, cache_allocator )
	// verify( allocation_error == AllocatorError.None, "Failed to allcate render_queue")

	// ui.render_list, allocation_error = make( Array(UI_RenderBoxInfo), UI_Built_Boxes_Array_Size, cache_allocator, fixed_cap = true )
	// verify( allocation_error == AllocatorError.None, "Failed to allocate rener_list" )

	ui.render_list_box, allocation_error = make( Array(UI_RenderBoxInfo), UI_Built_Boxes_Array_Size, cache_allocator, fixed_cap = true )
	verify( allocation_error == AllocatorError.None, "Failed to allocate rener_list_box" )

	ui.render_list_text, allocation_error = make( Array(UI_RenderTextInfo), UI_Built_Boxes_Array_Size, cache_allocator, fixed_cap = true )
	verify( allocation_error == AllocatorError.None, "Failed to allocate rener_list_box" )

	log("ui_startup completed")
}

ui_reload :: proc( ui : ^ UI_State, cache_allocator : Allocator )
{
	// We need to repopulate Allocator references
	for & cache in ui.caches {
		hmap_chained_reload( cache, cache_allocator)
	}
	// ui.render_queue.backing = cache_allocator
	// ui.render_list.backing  = cache_allocator
	ui.render_list_box.backing  = cache_allocator
	ui.render_list_text.backing = cache_allocator
}

// TODO(Ed) : Is this even needed?
ui_shutdown :: proc() {
}

ui_graph_build_begin :: proc( ui : ^ UI_State, bounds : Vec2 = {} )
{
	profile(#procedure)

	state := get_state()
	get_state().ui_context = ui
	using get_state().ui_context

	stack_clear( & layout_combo_stack )
	stack_clear( & style_combo_stack )
	// array_clear( render_queue )
	// array_clear( render_list )
	array_clear( render_list_box )
	array_clear( render_list_text )

	curr_cache, prev_cache = swap( curr_cache, prev_cache )

	if ui.active == UI_Key(0) {
		//ui.hot = UI_Key(0)
		ui.active_start_signal = {}
	}

	ui.built_box_count = 0
	root = ui_box_make( {}, str_intern(str_fmt("%s: root#001", ui == & state.screen_ui ? "Screen" : "Workspace" )).str)
	if ui == & state.screen_ui {
		root.layout.size = range2(Vec2(state.app_window.extent) * 2, {})
	}
	ui_parent_push(root)
}

ui_graph_build_end :: proc( ui : ^UI_State )
{
	profile(#procedure)
	state := get_state()

	ui_parent_pop() // Should be ui_context.root
	assert(stack_peek(& ui.parent_stack) == nil)

	Post_Build_Graph_Traversal:
	{
		root := ui.root
		{
			computed := & root.computed
			style    := root.style
			layout   := & root.layout
			if ui == & state.screen_ui {
				computed.bounds.min = transmute(Vec2) state.app_window.extent * -1
				computed.bounds.max = transmute(Vec2) state.app_window.extent
			}
			computed.content    = computed.bounds
		}

		previous_layer : i32 = 1

		// Auto-layout and initial render_queue generation
		profile_begin("Auto-layout and render_queue generation")
		// render_queue := array_to_slice(ui.render_queue)
		for current := ui.root.first; current != nil; 
				current  = ui_box_tranverse_next_depth_first( current, bypass_intersection_test = true, ctx = ui )
		{
			if ! current.computed.fresh {
				ui_box_compute_layout( current )
			}

			if ! intersects_range2(ui_view_bounds(ui), current.computed.bounds) {
				continue
			}

			when true {
			// entry : UI_RenderBoxInfo = {
			// 	current.computed,
			// 	current.style,
			// 	current.text,
			// 	current.layout.font_size,
			// 	current.layout.border_width,
			// 	current.label,
			// 	false,
			// }
			entry_box := UI_RenderBoxInfo {
				bounds        = current.computed.bounds,
				corner_radii  = current.style.corner_radii,
				bg_color      = current.style.bg_color,
				border_color  = current.style.border_color,
				border_width  = current.layout.border_width,
			}
			entry_text := UI_RenderTextInfo {
				text      = current.text.str,
				position  = current.computed.text_pos,
				color     = current.style.text_color,
				font      = current.style.font,
				font_size = current.layout.font_size,
			}

			if current.ancestors != previous_layer {
				entry_box .layer_signal = true
				entry_text.layer_signal = true
			}

			array_append(& ui.render_list_box,  entry_box)
			array_append(& ui.render_list_text, entry_text)
			previous_layer = current.ancestors
			}
		}
		profile_end()

		// render_list  := array_to_slice(ui.render_list)
		render_list_box   := array_to_slice(ui.render_list_box)
		render_list_text  := array_to_slice(ui.render_list_text)
	}

	get_state().ui_context = nil
}

// TODO(Ed): Review usage if at all.
ui_render_entry_tranverse :: proc( entry : ^UI_RenderEntry ) -> ^UI_RenderEntry
{
	// using state := get_state()
	parent := entry.parent
	if parent != nil
	{
		if parent.last != entry
		{
			if entry.next != nil do return entry.next
		}
	}

	// If there any children, do them next.
	if entry.first != nil {
		return entry.first
	}

	// Iteration exhausted
	return nil
}

@(deferred_in = ui_graph_build_end)
ui_graph_build :: #force_inline proc( ui : ^ UI_State ) { ui_graph_build_begin( ui ) }

#endregion("Lifetime")

#region("Caching")
// Mainly referenced from RAD Debugger

// TODO(Ed): Need to setup the proper hashing convention for strings the other reference imguis use.
ui_hash_from_string :: proc ( value : string ) -> u64 {
	fatal("NOT IMPLEMENTED")
	return 0
}

ui_hash_part_from_key_string :: proc ( content : string ) -> string {
	fatal("NOT IMPLEMENTED")
	return ""
}

ui_key_from_string :: #force_inline proc "contextless" ( value : string ) -> UI_Key
{
	// profile(#procedure)
	USE_RAD_DEBUGGERS_METHOD :: true

	key : UI_Key

	when USE_RAD_DEBUGGERS_METHOD {
		hash : u64
		for str_byte in transmute([]byte) value {
			hash = ((hash << 8) + hash) + u64(str_byte)
		}
		key = cast(UI_Key) hash
	}

	when ! USE_RAD_DEBUGGERS_METHOD {
		key = cast(UI_Key) crc32( transmute([]byte) value )
	}

	return key
}
#endregion("Caching")

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

ui_parent_push :: #force_inline proc( ui : ^ UI_Box ) { stack_push( & ui_context().parent_stack, ui ) }
ui_parent_pop  :: #force_inline proc()                { stack_pop(  & get_state().ui_context.parent_stack ) }

ui_parent_peek :: #force_inline proc() -> ^UI_Box { return stack_peek( & ui_context().parent_stack )}

@(deferred_none = ui_parent_pop)
ui_parent :: #force_inline proc( ui : ^UI_Box) { ui_parent_push( ui ) }

// Topmost ancestor that is not the root
ui_top_ancestor :: #force_inline proc "contextless" ( box : ^UI_Box ) -> (^UI_Box) {
	using ui := get_state().ui_context
	ancestor := box
	for ; ancestor.parent != root; ancestor = ancestor.parent {}
	return ancestor
}

ui_view_bounds :: #force_inline proc "contextless" ( ui : ^UI_State = nil ) -> (range : Range2) {
	state := get_state(); using state
	ui := ui; if ui == nil do ui = ui_context

	if ui == & screen_ui {
		return screen_get_bounds()
	}
	else {
		return view_get_bounds()
	}
}

ui_context :: #force_inline proc "contextless" () -> ^UI_State { return get_state().ui_context }
