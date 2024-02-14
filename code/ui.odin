package sectr

// Based off Ryan Fleury's UI Series & Epic's RAD Debugger which directly implements a version of it.
// You will see Note(rjf) these are comments directly from the RAD Debugger codebase by Fleury.
// TODO(Ed) If I can, I would like this to be its own package, but the nature of packages in odin may make this difficult.

// TODO(Ed) : This is in Raddbg base_types.h, consider moving outside of UI.
Axis2 :: enum {
	Invalid =  -1,
	X,
	Y,
	Count,
}

UI_FocusKind :: enum u32 {
	Null,
	Off,
	On,
	Root,
	Count,
}

UI_IconKind :: enum u32 {
	Null,
	Arrow_Up,
	Arrow_Left,
	Arrow_Right,
	Arrow_Down,
	Caret_Up,
	Caret_Left,
	Caret_Right,
	Caret_Down,
	Check_Hollow,
	Check_Filled,
	Count,
}

UI_IconInfo :: struct {
	placehodler : int
}

UI_NavDeltaUnit :: enum u32 {
	Element,
	Chunk,
	Whole,
	End_Point,
	Count,
}

UI_NavActionFlag :: enum u32 {
	Keep_Mark,
	Delete,
	Copy,
	Paste,
	Zero_Delta_On_Select,
	Pick_Select_Side,
	Can_At_Line,
	Explicit_Directional,
	Replace_And_Commit,
}
UI_NavActionFlags :: bit_set[UI_NavActionFlag; u32]

UI_NavAction :: struct {
	flags      : UI_NavActionFlags,
	delta      : Vec2i,
	delta_unit : UI_NavDeltaUnit,
	insertion  : string,
}

UI_SizeKind :: enum u32 {
	Null,
	Pixels,
	Points,
	TextContent,
	PercentOfParent,
	ChildrenSum,
	Count,
}

UI_Size :: struct {
	kind       : UI_SizeKind,
	value      : f32,
	strictness : f32,
}

UI_Size2 : struct {
	kind       : [Axis2.Count]UI_SizeKind,
	value      : Vec2,
	strictness : Vec2,
}

UI_Layout :: struct {
	placeholder : int
}

UI_Key :: struct {
	opaque : [1]u64,
}

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

// Note(Ed) : This is called UI_Widget in the substack series, its called box in raddbg
// This eventually gets renamed by part 4 of the series to UI_Box.
// However, its essentially a UI_Node or UI_BaselineEntity, etc.
// Think of godot's Control nodes I guess.
UI_Box :: struct {
	// Note(rjf) : persistent links
	hash : struct {
		next, prev : ^ UI_Box,
	},

	// Note(rjf) : Per-build links & data
	first, last, prev, next : ^ UI_Box,
	num_children : i32,

	// Note(rjf) : Key + generation info
	key                      : UI_Key,
	last_frame_touched_index : u64,

	// Note(rjf) : Per-frame info provided by builders
	flags : UI_BoxFlags,
	display_str : string,
	semantic_size : [Axis2.Count]UI_Size,


	// Note(rjf) : Computed every frame
	computed_rel_pos : Vec2,
	computed_size    : Vec2,
	//rect : Rng2F32

	// Note(rjf) : Persistent data
	hot    : f32,
	active : f32,

	// bg_color  : Color,
	// txt_color : Color,
}

UI_Signal :: struct {
	box : UI_Box,
	cursor_pos : Vec2,
	drag_delta : Vec2,
	scroll     : Vec2,
	left_clicked     : b8,
	right_clicked    : b8,
	double_clicked   : b8,
	keyboard_clicked : b8,
	pressed    : b8,
	released   : b8,
	dragging   : b8,
	hovering   : b8,
	mouse_over : b8,
	commit     : b8,
}

ui_key_null :: proc() -> UI_Key {
	return {}
}

ui_key_from_string :: proc( value : string ) -> UI_Key {
	 return {}
}

ui_key_match :: proc( a, b : UI_Key ) -> b32 {
	 return false
}

ui_box_make :: proc( flags : UI_BoxFlags, label : string ) -> (^ UI_Box) {
	return nil
}

ui_box_equip_display_string :: proc( box : ^ UI_Box, display_string : string ) {

}

ui_box_equip_child_layout_axis :: proc( box : ^ UI_Box, axis : Axis2 ) {

}

ui_push_parent :: proc( box : ^ UI_Box ) -> (^ UI_Box) {
	return nil
}

ui_pop_parent :: proc() -> (^ UI_Box) {
	return nil
}

ui_signal_from_box :: proc( box : ^ UI_Box ) -> UI_Signal {
	return {}
}

ui_button :: proc( label : string ) -> UI_Signal {
	button_flags : UI_BoxFlags =
		UI_BoxFlags_Clickable & {
			.Draw_Border,
			.Draw_Text,
			.Draw_Background,
			.Focus_Hot,
			.Focus_Active,
		}
	box    := ui_box_make( button_flags, label )
	signal := ui_signal_from_box( box )
	return signal
}

ui_spacer :: proc ( label : string = UI_NullLabel ) -> UI_Signal {
	box    := ui_box_make( UI_BoxFlags_Null, label )
	signal := ui_signal_from_box( box )
	return signal
}
