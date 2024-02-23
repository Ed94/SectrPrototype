package wip

// Based off Ryan Fleury's UI Series & Epic's RAD Debugger which directly implements a version of it.
// You will see Note(rjf) these are comments directly from the RAD Debugger codebase by Fleury.
// TODO(Ed) If I can, I would like this to be its own package, but the nature of packages in odin may make this difficult.

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

// TODO(Ed) : From Raddbg draw.h, consider if needed or covered by raylib.
DrawBucket :: struct {
	// passes : RenderPassList,
	stack_gen : u64,
	last_cmd_stack_gen : u64,
	// DrawBucketStackDeclares
}

// TODO(Ed) : From Raddbg draw.h, consider if needed or covered by raylib.
DrawFancyRunList :: struct {
	placeholder : int
}

// TODO(Ed) : From Raddbg base_string.h, consider if needed or covered by raylib.
FuzzyMatchRangeList :: struct {
	placeholder : int
}

// TODO(Ed): This is in Raddbg os_gfx.h, consider moving outside of UI.
OS_Cursor :: enum u32 {
	Pointer,
	IBar,
	Left_Right,
	Up_Down,
	Down_Right,
	Up_Right,
	Up_Down_left_Right,
	Hand_Point,
	Disabled,
	Count,
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

Side :: enum i32 {
	Invalid = -1,
	Min     = 0,
	Max     = 1,
	Count
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

UI_Key :: struct {
	opaque : [1]u64,
}

UI_Layout :: struct {
	placeholder : int
}

UI_Nav :: struct {
	moved : b32,
	new_p : Vec2i
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

UI_NavActionNode :: struct {
	next   : ^ UI_NavActionNode,
	last   : ^ UI_NavActionNode,
	action : UI_NavAction
}

UI_NavActionList :: struct {
	first : ^ UI_NavActionNode,
	last  : ^ UI_NavActionNode,
	count : u64,
}

UI_NavTextOpFlag :: enum u32 {
	Invalid,
	Copy,
}
UI_NavTextOpFlags :: bit_set[UI_NavTextOpFlag; u32]

UI_ScrollPt :: struct {
	idx    : i64,
	offset : f32
}
UI_ScrollPt2 :: [2]UI_ScrollPt

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

UI_TextAlign :: enum u32 {
	Left,
	Center,
	Right,
	Count
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

ui_spacer :: proc( label : string = UI_NullLabel ) -> UI_Signal {
	box    := ui_box_make( UI_BoxFlags_Null, label )
	signal := ui_signal_from_box( box )
	return signal
}
