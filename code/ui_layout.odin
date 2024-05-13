package sectr

import "core:math"
import "core:math/linalg"

// The UI_Box's actual positioning and sizing
// There is an excess of rectangles here for debug puproses.
UI_Computed :: struct {
	fresh      : b32,    // If the auto-layout has been computed for the current frame
	// anchors    : Range2, // Bounds for anchors within parent
	// margins    : Range2, // Bounds for margins within parent
	bounds     : Range2, // Bounds for box itself
	padding    : Range2, // Bounds for padding's starting bounds (will be offset by border if there is one)
	content    : Range2, // Bounds for content (text or children)
	text_pos   : Vec2,   // Position of text within content
	text_size  : Vec2,   // Size of text within content
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
	// Will override parent constraints (use the size.min.xy to specify the width & height)
	Fixed_Width,
	Fixed_Height,

	// TODO(Ed): Implement this!
	// Enforces the widget will have a width specified as a ratio of its height (use the size.min/max.x to specify the scalar)
	// If you wish for the width to stay fixed couple with the Fixed_Width flag
	Scale_Width_By_Height_Ratio,
	// Enforces the widget will have a height specified as a ratio of its width (use the size.min/max.y to specify the scalar)
	// If you wish for the height to stay fixed couple with the Fixed_Height flag
	Scale_Height_By_Width_Ratio,

	// Sets the (0, 0) position of the child box to the parents anchor's center (post-margins bounds)
	// By Default, the origin is at the top left of the anchor's bounds
	Origin_At_Anchor_Center,

	// TODO(Ed): Implement this!
	// For this to work, the children must have a minimum size set & their size overall must be greater than the parent's minimum size
	Size_To_Content,

	// Will size the box to its text.
	Size_To_Text,

	// TODO(Ed): Implement this!
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

	font_size : f32,

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

	transition_time : f32,
}

UI_LayoutCombo :: struct #raw_union {
	array : [UI_StylePreset.Count] UI_Layout,
	using layouts : struct {
		default, disabled, hot, active : UI_Layout,
	}
}

to_ui_layout_side  :: #force_inline proc( pixels : f32 )       -> UI_LayoutSide  { return { pixels, pixels, pixels, pixels } }
to_ui_layout_combo :: #force_inline proc( layout : UI_Layout ) -> UI_LayoutCombo { return { layouts = {layout, layout, layout, layout} } }

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
ui_layout_push_theme  :: #force_inline proc( combo : UI_LayoutCombo ) { push( & get_state().ui_context.layout_combo_stack, combo ) }
ui_layout_pop         :: #force_inline proc()                         { pop(  & get_state().ui_context.layout_combo_stack ) }

@(deferred_none = ui_layout_pop) ui_layout_via_layout :: #force_inline proc( layout : UI_Layout )      { ui_layout_push( layout) }
@(deferred_none = ui_layout_pop) ui_layout_via_combo  :: #force_inline proc( combo  : UI_LayoutCombo ) { ui_layout_push( combo) }

ui_set_layout :: #force_inline proc( layout : UI_Layout, preset : UI_StylePreset ) { stack_peek_ref( & get_state().ui_context.layout_combo_stack).array[preset] = layout }

/*
Widget Layout Ops
*/

ui_layout_children_horizontally :: proc( container : ^UI_Box, direction : UI_LayoutDirectionX, width_ref : ^f32 )
{
	container_width : f32
	if width_ref != nil {
		container_width = width_ref ^
	}
	else {
		container_width = container.computed.content.max.x - container.computed.content.min.x
	}

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := container.first; child != nil; child = child.next
	{
		using child.layout
		scaled_width_by_height : b32 = b32(.Scale_Width_By_Height_Ratio in flags)
		if .Fixed_Width in flags
		{
			if scaled_width_by_height {
				height := size.max.y != 0 ? size.max.y : container_width
				width  := height * size.min.x

				size_req_children += width
				continue
			}

			size_req_children += size.min.x
			continue
		}

		total_stretch_ratio += anchor.ratio.x
	}

	avail_flex_space := container_width - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space : f32 )
	{
		using child.layout
		if ! (.Fixed_Width in flags) {
			size.min.x = anchor.ratio.x * (1 / total_stretch_ratio) * avail_flex_space
		}
		flags    |= {.Fixed_Width}
	}

	space_used : f32 = 0.0
	switch direction{
		case .Right_To_Left:
			for child := container.last; child != nil; child = child.prev {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 0})
				alignment   = { 0, 1 }// - hbox.layout.alignment
				pos.x       = space_used
				space_used += size.min.x
				size.min.y  = container.computed.content.max.y - container.computed.content.min.y
			}
		case .Left_To_Right:
			for child := container.first; child != nil; child = child.next {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 0})
				alignment   = { 0, 1 }
				pos.x       = space_used
				space_used += size.min.x
				size.min.y  = container.computed.content.max.y - container.computed.content.min.y
			}
	}
}

ui_layout_children_vertically :: proc( container : ^UI_Box, direction : UI_LayoutDirectionY, height_ref : ^f32 )
{
	container_height : f32
	if height_ref != nil {
		container_height = height_ref ^
	}
	else {
		container_height = container.computed.content.max.y - container.computed.content.min.y
	}

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := container.first; child != nil; child = child.next
	{
		using child.layout
		scaled_width_by_height : b32 = b32(.Scale_Width_By_Height_Ratio in flags)
		if .Fixed_Height in flags
		{
			if scaled_width_by_height {
				width  := size.max.x != 0 ? size.max.x : container_height
				height := width * size.min.y

				size_req_children += height
				continue
			}

			size_req_children += size.min.y
			continue
		}

		total_stretch_ratio += anchor.ratio.y
	}

	avail_flex_space := container_height - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space : f32 )
	{
		using child.layout
		if ! (.Fixed_Height in flags) {
			size.min.y = anchor.ratio.y * (1 / total_stretch_ratio) * avail_flex_space
		}
		flags    |= {.Fixed_Height}
		alignment = {0, 0}
	}

	space_used : f32 = 0.0
	switch direction {
		case .Top_To_Bottom:
			for child := container.last; child != nil; child = child.prev {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 1})
				// alignment   = {0, 1}
				pos.y       = space_used
				space_used += size.min.y
				size.min.x  = container.computed.content.max.x - container.computed.content.min.x
			}
		case .Bottom_To_Top:
			for child := container.first; child != nil; child = child.next {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 1})
				// alignment   = {0, 1}
				pos.y       = space_used
				space_used += size.min.y
				size.min.x  = container.computed.content.max.x - container.computed.content.min.x
			}
	}
}
