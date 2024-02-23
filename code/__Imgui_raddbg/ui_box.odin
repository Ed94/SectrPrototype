package wip

UI_BoxFlag :: enum u64 {
	// Note(rjf) : Interaction
	Mouse_Clickable,
	Keyboard_Clickable,
	Click_To_Focus,
	Scroll,
	View_Scroll_X,
	View_Scroll_Y,
	View_Clamp_X,
	View_Clamp_Y,
	Focus_Active,
	Focus_Active_Disabled,
	Focus_Hot,
	Focus_Hot_Disabled,
	Default_Focus_Nav_X,
	Default_Focus_Nav_Y,
	Default_Focus_Edit,
	Focus_Nav_Skip,
	Disabled,

	// Note(rjf) : Layout
	Floating_X,
	Floating_Y,
	Fixed_Width,
	Fixed_Height,
	Allow_Overflow_X,
	Allow_Overflow_Y,
	Skip_View_Off_X,
	Skip_View_Off_Y,

	// Note(rjf) : Appearance / Animation
	Draw_Drop_Shadow,
	Draw_Background_Blur,
	Draw_Background,
	Draw_Border,
	Draw_Side_Top,
	Draw_Side_Bottom,
	Draw_Side_Left,
	Draw_Side_Right,
	Draw_Text,
	Draw_Text_Fastpath_Codepoint,
	Draw_Hot_Effects,
	Draw_Overlay,
	Draw_Bucket,
	Clip,
	Animate_Pos_X,
	Animate_Pos_Y,
	Disable_Text_Trunc,
	Disable_ID_String,
	Disable_Focus_Viz,
	Require_Focus_Background,
	Has_Display_String,
	Has_Fuzzy_Match_Ranges,
	Round_Children_By_Parent,

	Count,
}
UI_BoxFlags :: bit_set[UI_BoxFlag; u64]

UI_BoxFlags_Null      :: UI_BoxFlags {}
UI_BoxFlags_Clickable :: UI_BoxFlags { .Mouse_Clickable, .Keyboard_Clickable }

UI_NullLabel :: ""

UI_BoxCustomDrawProc :: #type proc( box : ^ UI_Box, user_data : rawptr )

UI_BoxCustomDraw :: struct {
	callback : UI_BoxCustomDrawProc,
	data     : rawptr,
}

UI_BoxRec :: struct {
	next       : ^ UI_BoxNode,
	push_count : i32,
	pop_count  : i32,
}

UI_BoxNode :: struct {
	next : ^ UI_BoxNode,
	box  : ^ UI_Box,
}

UI_BoxList :: struct {
	first : UI_BoxNode,
	last  : UI_BoxNode,
	count : u64,
}

UI_BoxHashSlot :: struct {
	first, last : ^ UI_Box
}

// Note(Ed) : This is called UI_Widget in the substack series, its called box in raddbg
// This eventually gets renamed by part 4 of the series to UI_Box.
// However, its essentially a UI_Node or UI_BaselineEntity, etc.
// Think of godot's Control nodes I guess.
// TODO(Ed) : We dumped all the fields present within raddbg, review which ones are actually needed.
UI_Box :: struct {
	// Note(rjf) : persistent links
	hash : struct {
		next, prev : ^ UI_Box,
	},

	// Note(rjf) : Per-build links & data
	// TODO(ED) : Put this in its own struct?
	first, last, prev, next : ^ UI_Box,
	num_children : i32,

	// Note(rjf) : Key + generation info
	// TODO(ED) : Put this in its own struct?
	key                      : UI_Key,
	last_frame_touched_index : u64,

	// Note(rjf) : Per-frame info provided by builders
	// TODO(ED) : Put this in its own struct?
	flags              : UI_BoxFlags,
	display_str        : string, // raddbg: string
	semantic_size      : [Axis2.Count]UI_Size,
	text_align         : UI_TextAlign,
	fixed_pos          : Vec2,
	fixed_size         : Vec2,
	pref_size          : [Axis2.Count]UI_Size,
	child_layout_axis  : Axis2,
	hover_cursor       : OS_Cursor,
	fastpath_codepoint : u32,
	draw_bucket        : DrawBucket, // TODO(Ed): Translate to equivalent in raylib if necessary
	custom_draw        : UI_BoxCustomDraw,
	bg_color           : Color,
	text_color         : Color,
	border_color       : Color,
	overlay_color      : Color,
	font               : FontID,
	font_size          : f32,
	corner_radii       : [Corner.Count]f32,
	blur_size          : f32, // TODO(Ed) : You would need to run a custom shader with raylib or have your own rendering backend for this.
	transparency       : f32,
	squish             : f32,
	text_padding       : f32,

	// Note(rjf) : Per-frame artifacts by builders
	// TODO(ED) : Put this in its own struct?
	display_string_runs : DrawFancyRunList, // TODO(Ed) : Translate to equivalent in raylib if necessary
	rect                : Range2,
	fixed_pos_animated  : Vec2,
	pos_delta           : Vec2,
	fuzzy_match_range   : FuzzyMatchRangeList, // TODO(Ed) : I'm not sure this is needed

	// Note(rjf) : Computed every frame
	// TODO(ED) : Put this in its own struct?
	computed_rel_pos : Vec2,  // TODO(Ed) : Raddbg doesn't have these, check what they became or if needed
	computed_size    : Vec2,

	// Note(rjf) : Persistent data
	// TODO(ED) : Put this in its own struct?
	first_touched_build_id     : u64,
	last_touched_build_id      : u64,
	hot_time                   : f32,
	active_time                : f32,
	disabled_time              : f32,
	focus_hot_time             : f32,
	focus_active_time          : f32,
	focus_active_disabled_time : f32,
	view_off                   : Vec2,
	view_off_target            : Vec2,
	view_bounds                : Vec2,
	default_nav_focus_hot_key         : UI_Key,
	default_nav_focus_active_key      : UI_Key,
	default_nav_focus_next_hot_key    : UI_Key,
	default_nav_focus_next_active_key : UI_Key,
}
