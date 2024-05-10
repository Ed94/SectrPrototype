package sectr

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

// Desiered constraints on the UI_Box.
UI_Layout :: struct {
	anchor         : Range2,
	alignment      : Vec2,
	text_alignment : Vec2,

	font_size : f32,

	margins : UI_LayoutSide,
	padding : UI_LayoutSide,

	// TODO(Ed): We cannot support individual corners unless we add it to raylib (or finally change the rendering backend)
	corner_radii : [Corner.Count]f32,
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

// TODO(Ed): Change this to layout flags? Everything so far is just related to auto-layout
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
	text_color     : Color,

	cursor : UI_Cursor,

	// TODO(Ed): Should layout be separate from style?
	// It technically entirely makes up style flags
	// and the only thing shared I guess is the font determining the measured text size + transition time
	// Technically we can provide a separate transition time option just for layout...
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

to_ui_layoutside :: #force_inline proc( pixels : f32 ) -> UI_LayoutSide { return { pixels, pixels, pixels, pixels } }

to_ui_styletheme :: #force_inline proc( style : UI_Style ) -> UI_StyleTheme { return { styles = {style, style, style, style} } }

ui_style_peek :: #force_inline proc( box_state : UI_StylePreset ) -> UI_Style     { return stack_peek_ref( & get_state().ui_context.theme_stack ).array[box_state] }
ui_style_ref  :: #force_inline proc( box_state : UI_StylePreset ) -> (^ UI_Style) { return & stack_peek_ref( & get_state().ui_context.theme_stack ).array[box_state] }

ui_style_set :: #force_inline proc ( style : UI_Style, box_state : UI_StylePreset ) { stack_peek_ref( & get_state().ui_context.theme_stack ).array[box_state] = style }

ui_style_set_layout :: #force_inline proc ( layout : UI_Layout, preset : UI_StylePreset ) { stack_peek_ref( & get_state().ui_context.theme_stack ).array[preset].layout = layout }

ui_style_theme_push :: #force_inline proc( preset : UI_StyleTheme ) { push( & get_state().ui_context.theme_stack, preset ) }
ui_style_theme_pop  :: #force_inline proc()                         { pop(  & get_state().ui_context.theme_stack ) }

@(deferred_none = ui_style_theme_pop)
ui_style_theme :: #force_inline proc( preset : UI_StyleTheme ) { ui_style_theme_push( preset ) }

ui_style_theme_peek :: #force_inline proc() -> UI_StyleTheme     { return stack_peek( & get_state().ui_context.theme_stack ) }
ui_style_theme_ref  ::  #force_inline proc() -> (^ UI_StyleTheme) { return stack_peek_ref( & get_state().ui_context.theme_stack ) }

@(deferred_none = ui_style_theme_pop)
ui_theme_via_style :: #force_inline proc ( style : UI_Style ) { ui_style_theme_push( UI_StyleTheme { styles = { style, style, style, style } }) }

ui_style_theme_set_layout :: proc ( layout : UI_Layout ) {
	for & preset in stack_peek_ref( & get_state().ui_context.theme_stack ).array {
		preset.layout = layout
	}
}

ui_style_theme_layout_push :: proc ( layout : UI_Layout ) {
	ui := get_state().ui_context
	ui_style_theme_push( stack_peek( & ui.theme_stack) )
	ui_style_theme_set_layout(layout)
}

@(deferred_none = ui_style_theme_pop)
ui_style_theme_layout :: #force_inline proc( layout : UI_Layout ) { ui_style_theme_layout_push(layout) }
