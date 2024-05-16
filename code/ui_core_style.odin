package sectr

// TODO(Ed): We problably can embedd this info into the UI_Layout with the regular text_alignment
UI_TextAlign :: enum u32 {
	Left,
	Center,
	Right,
	Count
}

UI_StylePreset :: enum u32 {
	Default,
	Disabled,
	Hot,
	Active,
	Count,
}

UI_Style :: struct {
	bg_color     : Color,
	border_color : Color,

	// TODO(Ed): We cannot support individual corners unless we add it to raylib (or finally change the rendering backend)
	corner_radii : [Corner.Count]f32,

	// TODO(Ed) : Add support for this eventually
	blur_size : f32,

	// TODO(Ed): Add support for textures
	// texture : Texture2,

	// TODO(Ed): Add support for custom shader
	// shader : UI_Shader,

	font       : FontID,
	text_color : Color,

	// TODO(Ed) : Support setting the cursor state
	cursor : UI_Cursor,
}

UI_StyleCombo :: struct #raw_union {
	array : [UI_StylePreset.Count] UI_Style,
	using styles : struct {
		default, disabled, hot, active : UI_Style,
	}
}

to_ui_style_combo :: #force_inline proc( style : UI_Style ) -> UI_StyleCombo { return { styles = {style, style, style, style} } }

/*
Style Interface

Style for UI_Boxes in the state graph is stored on a per-graph UI_State basis in the fixed sized stack called style_combo_stack.
The following provides a convient way to manipulate this stack from the assuption of the program's state.ui_context

The following procedure overloads are available from grime.odin :
* ui_style
* ui_style_push
*/

ui_style_peek :: #force_inline proc() -> UI_StyleCombo     { return stack_peek( & get_state().ui_context.style_combo_stack ) }
ui_style_ref  :: #force_inline proc() -> (^ UI_StyleCombo) { return stack_peek_ref( & get_state().ui_context.style_combo_stack ) }

ui_style_push_style :: #force_inline proc( style : UI_Style )      { push( & get_state().ui_context.style_combo_stack, to_ui_style_combo(style)) }
ui_style_push_combo :: #force_inline proc( combo : UI_StyleCombo ) { push( & get_state().ui_context.style_combo_stack, combo ) }
ui_style_pop        :: #force_inline proc()                        { pop(  & get_state().ui_context.style_combo_stack ) }

@(deferred_none = ui_style_pop) ui_style_via_style :: #force_inline proc( style : UI_Style )      { ui_style_push( style) }
@(deferred_none = ui_style_pop) ui_style_via_combo :: #force_inline proc( combo : UI_StyleCombo ) { ui_style_push( combo) }

ui_style_set :: #force_inline proc ( style : UI_Style, preset : UI_StylePreset ) { stack_peek_ref( & get_state().ui_context.style_combo_stack ).array[preset] = style }
