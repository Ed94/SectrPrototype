package wip

import "core:os"

// TODO(Ed) : As with UI_Box, not all of this will be implemented at once,
// we'll need to review this setup for our use case, we will have UI persistent of
// a workspace (global state UI), and one for the workspace itself.
// The UI state use in raddbg seems to be tied to an OS window and has realted things to it.
// You may need to lift the nav actions outside of the UI_State of a workspace, etc...
UI_State :: struct {
	arena : ^ Arena,

	build_arenas : [2] ^ Arena,
	build_id     : u64,

	// Note(rjf) : Box cache
	// TODO(ED) : Put this in its own struct?
	first_free_box : UI_Box,
	box_table_size : u64,
	box_table      : ^ UI_BoxHashSlot,  // TODO(Ed) : Can the cache use HashTable?

	// Note(rjf) : Build phase output
	// TODO(ED) : Put this in its own struct?
	root                        : ^ UI_Box,
	tooltip_root                : ^ UI_Box,
	ctx_menu_root               : ^ UI_Box,
	default_nav_root_key        : UI_Key,
	build_box_count             : u64,
	last_build_box_count        : u64,
	ctx_menu_touched_this_frame : b32,

	// Note(rjf) : Build parameters
	// icon_info  : UI_IconInfo
	// window    : os.Handle
	// events    : OS_EventList
	nav_actions           : UI_NavActionList,
	// TODO(Ed) : Do we want to keep tracvk of the cursor pos separately
	// incase we do some sequence for tutorials?
	mouse                 : Vec2,
	animation_delta       : f32,
	external_focus_commit : b32,

	// Note(rjf) : User Interaction State
	// TODO(ED) : Put this in its own struct?
	hot_box_key              : UI_Key,
	active_box_key           : [Side.Count] UI_Key,
	clipboard_copy_key       : UI_Key,
	time_since_last_click    : [Side.Count] f32,
	last_click_key           : [Side.Count] UI_Key,
	drag_start_mouse         : Vec2,
	drag_state_arena         : ^ Arena,
	drag_state_data          : string,
	string_hover_arena       : ^ Arena,
	string_hover_string      : string,
	string_hover_fancy_runs  : DrawFancyRunList,
	string_hover_begin_us    : u64,
	string_hover_build_index : u64,
	last_time_mouse_moved_us : u64,

	// Note(rjf) : Tooltip State
	// TODO(ED) : Put this in its own struct?
	tool_tip_open_time : f32,
	tool_tip_open      : b32,

	// Note(rjf) : Context menu state
	// TODO(ED) : Put this in its own struct?
	ctx_menu_anchor_key          : UI_Key,
	next_ctx_menu_anchor_key     : UI_Key,
	ctx_menu_anchor_box_last_pos : Vec2,
	cxt_menu_anchor_off          : Vec2,
	ctx_menu_open                : b32,
	next_ctx_menu_open           : b32,
	ctx_menu_open_time           : f32,
	ctx_menu_key                 : UI_Key,
	ctx_menu_changed             : b32,
}
