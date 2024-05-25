package sectr

import "core:math"
import "core:math/linalg"


// Anchor_

// Alignment presets

LayoutAlign_OriginTL_Top          :: Vec2{0.5,   0}
LayoutAlign_OriginTL_TopLeft      :: Vec2{  0,   0}
LayoutAlign_OriginTL_TopRight     :: Vec2{  1,   0}
LayoutAlign_OriginTL_Centered     :: Vec2{0.5, 0.5}
LayoutAlign_OriginTL_Bottom       :: Vec2{0.5,   1}
LayoutAlign_OriginTL_BottomLeft   :: Vec2{  0,   1}
LayoutAlign_OriginTL_BottomRight  :: Vec2{  1,   1}


Layout_OriginCenter_Centered :: Vec2{0.5, 0.5}

UI_Align_Presets_Struct :: struct {
	origin_tl_centered : Vec2,
	text_centered  : Vec2,
}
UI_Align_Presets :: UI_Align_Presets_Struct {
	origin_tl_centered = {0.5, 0.5},
	text_centered      = {0.5, 0.5},
}


// The UI_Box's actual positioning and sizing
// There is an excess of rectangles here for debug puproses.
UI_Computed :: struct {
	// anchors    : Range2, // Bounds for anchors within parent
	// margins    : Range2, // Bounds for margins within parent
	padding    : Range2, // Bounds for padding's starting bounds (will be offset by border if there is one), only here for debug vis

	bounds     : Range2, // Bounds for box itself
	content    : Range2, // Bounds for content (text or children)
	text_pos   : Vec2,   // Position of text within content
	text_size  : Vec2,   // Size of text within content
	fresh      : b32,    // If the auto-layout has been computed for the current frame
}

UI_LayoutDirectionX :: enum(i32) {
	Left_To_Right,
	Right_To_Left,
}

UI_LayoutDirectionY :: enum(i32) {
	Top_To_Bottom,
	Bottom_To_Top,
}

UI_LayoutSide :: struct {
	// using _ :  struct {
		top, bottom : UI_Scalar,
		left, right : UI_Scalar,
	// }
}

UI_LayoutFlag :: enum u32 {

	// Will NOT perform scissor pass on children to their parent's bounds
	// (Specified in the parent)
	Dont_Clip_Children_To_bounds,

	// Enforces the box will always remain in a specific position relative to the parent.
	// Overriding the anchors and margins.
	Fixed_Position_X,
	Fixed_Position_Y,

	// Enforces box will always be within the bounds of the parent box.
	Clamp_Position_X,
	Clamp_Position_Y,

	// Enroces the widget will maintain its size reguardless of any constraints
	// Will override parent constraints (use the size.min.xy to specify the width & height)
	Fixed_Width,
	Fixed_Height,

	// Enforces the widget will have a width specified as a ratio of its height (use the size.min/max.x to specify the scalar)
	// If you wish for the width to stay fixed couple with the Fixed_Width flag
	Scale_Width_By_Height_Ratio,
	// Enforces the widget will have a height specified as a ratio of its width (use the size.min/max.y to specify the scalar)
	// If you wish for the height to stay fixed couple with the Fixed_Height flag
	Scale_Height_By_Width_Ratio,

	// Sets the (0, 0) position of the child box to the parents anchor's center (post-margins bounds)
	// By Default, the origin is at the top left of the anchor's bounds (traditional)
	Origin_At_Anchor_Center,

	// TODO(Ed): Implement this!
	// For this to work, the children must have a minimum size set & their size overall must be greater than the parent's minimum size
	Size_To_Content,

	// Will size the box to its text.
	Size_To_Text,

	// TODO(Ed): Implement this!
	// ?Note(Ed): This can get pretty complicated... Maybe its better to leave this to composition of boxes.
	// ?A text wrapping panel can organize text and wrap it via procedrually generated lines in a hbox/vbox.
	// ?It would be a non-issue so long as the text rendering bottleneck is resolved.
	// Wrap text around the box, text_alignment specifies the justification for its compostion when wrapping.
	Text_Wrap,

	Count,
}
UI_LayoutFlags :: bit_set[UI_LayoutFlag; u32]

// Used within UI_Box, provides the layout (spacial constraints & specification) of the widget and
UI_Layout :: struct {
	flags          : UI_LayoutFlags,
	anchor         : Range2,
	alignment      : Vec2,
	text_alignment : Vec2,

	font_size : UI_Scalar,

	margins : UI_LayoutSide,
	padding : UI_LayoutSide,

	border_width : UI_Scalar,

	// Position in relative coordinate space.
	// If the box's flags has Fixed_Position, then this will be its aboslute position in the relative coordinate space
	pos  : Vec2,
	size : Range2,

	// TODO(Ed) :  Should thsi just always be WS_Pos for workspace UI?
	// (We can union either varient and just know based on checking if its the screenspace UI)
	// If the box is a child of the root parent, its automatically in world space and thus will use the tile_pos.
	// tile_pos : WS_Pos,
}

UI_LayoutCombo :: struct #raw_union {
	array : [UI_StylePreset.Count] UI_Layout,
	using layouts : struct {
		default, disabled, hot, active : UI_Layout,
	}
}

to_ui_layout_side_f32  :: #force_inline proc( pixels : f32 )       -> UI_LayoutSide  { return { pixels, pixels, pixels, pixels } }
to_ui_layout_side_vec2 :: #force_inline proc( v      : Vec2)       -> UI_LayoutSide  { return { v.x, v.x, v.y, v.y} }
to_ui_layout_combo     :: #force_inline proc( layout : UI_Layout ) -> UI_LayoutCombo { return { layouts = {layout, layout, layout, layout} } }

/*
Layout Interface

Layout for UI_Boxes in the state graph is stored on a per-graph UI_State basis in the fixed sized stack called layout_combo_stack.
The following provides a convient way to manipulate this stack from the assuption of the program's state.ui_context

The following procedure overloads are available from grime.odin:
* ui_layout
* ui_layout_push
*/

ui_layout_peek :: #force_inline proc() ->  UI_LayoutCombo { return stack_peek( & get_state().ui_context.layout_combo_stack) }
ui_layout_ref  :: #force_inline proc() -> ^UI_LayoutCombo { return stack_peek_ref( & get_state().ui_context.layout_combo_stack) }

ui_layout_push_layout :: #force_inline proc( layout : UI_Layout )     { push( & get_state().ui_context.layout_combo_stack, to_ui_layout_combo(layout)) }
ui_layout_push_combo  :: #force_inline proc( combo : UI_LayoutCombo ) { push( & get_state().ui_context.layout_combo_stack, combo ) }
ui_layout_pop         :: #force_inline proc()                         { pop(  & get_state().ui_context.layout_combo_stack ) }

@(deferred_none = ui_layout_pop) ui_layout_scope_via_layout :: #force_inline proc( layout : UI_Layout )      { ui_layout_push( layout) }
@(deferred_none = ui_layout_pop) ui_layout_scope_via_combo  :: #force_inline proc( combo  : UI_LayoutCombo ) { ui_layout_push( combo) }

ui_set_layout :: #force_inline proc( layout : UI_Layout, preset : UI_StylePreset ) { stack_peek_ref( & get_state().ui_context.layout_combo_stack).array[preset] = layout }
