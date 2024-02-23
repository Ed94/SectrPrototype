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

	size : UI_ScalarConstraint,
}

UI_Style :: struct {
	bg_color      : Color,
	overlay_color : Color,
	border_color  : Color,

	// blur_size : f32,

	font                    : FontID,
	font_size               : f32,
	text_color              : Color,
	text_alignment          : UI_TextAlign,
	// text_wrap_width_pixels  : f32,
	// text_wrap_width_percent : f32,

	// cursors       : [CursorKind.Count]UI_Cursor,
	// active_cursor : ^UI_Cursor,
	// hover_cursor : ^ UI_Cursor,
}

UI_TextAlign :: enum u32 {
	Left,
	Center,
	Right,
	Count
}

UI_Box :: struct {
	first, last, prev, next : ^ UI_Box,
	num_children : i32,

	flags : UI_BoxFlags,

	key   : UI_Key,
	label : string,

	computed : UI_Computed,

	layout : UI_Layout,
	style  : UI_Style,

	// Persistent Data
	hot_time      : f32,
	active_time   : f32,
	disabled_time : f32,
}

UI_State :: struct {
	box_cache : HashTable( UI_Box ),

	box_tree_dirty : b32,
	root           : ^ UI_Box,

	hot                : UI_Key,
	active             : UI_Key,
	clipboard_copy_key : UI_Key,

	drag_start_mouse : Vec2,
	// drag_state_arena : ^ Arena,
	// drag_state data  : string,
}

ui_box_make :: proc( flags : UI_BoxFlags, label : string ) -> (^ UI_Box)
{
	return nil
}
