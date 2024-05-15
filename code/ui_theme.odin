package sectr

UI_ThemePtr :: struct {
	layout : ^UI_LayoutCombo,
	style  : ^UI_StyleCombo,
}

UI_Theme :: struct {
	layout : UI_LayoutCombo,
	style  : UI_StyleCombo,
}

ui_theme_pop :: #force_inline proc() {
	ui_layout_pop()
	ui_style_pop()
}

@(deferred_none = ui_theme_pop)
ui_theme_via_layout_style :: #force_inline proc( layout : UI_Layout, style : UI_Style ) {
	using ui := get_state().ui_context
	ui_layout_push( layout )
	ui_style_push( style )
}

@(deferred_none = ui_theme_pop)
ui_theme_via_combos :: #force_inline proc( layout : UI_LayoutCombo, style : UI_StyleCombo ) {
	using ui := get_state().ui_context
	ui_layout_push( layout )
	ui_style_push( style )
}

@(deferred_none = ui_theme_pop)
ui_theme_via_theme :: #force_inline proc( theme : UI_Theme ) {
	using ui := get_state().ui_context
	ui_layout_push( theme.layout )
	ui_style_push( theme.style )
}

/*
UI Themes: Comprise of UI_Box's layout & style

Provides presets for themes and their interface for manipulating the combo stacks in UI_State in pairs
*/
// TODO(Ed): Eventually this will have a configuration wizard, and we'll save the presets

@(deferred_none = ui_theme_pop)
ui_theme_btn_default :: proc()
{
	@static theme : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		layout := UI_Layout {
			flags          = {},
			anchor         = range2({},{}),
			alignment      = {0, 0},
			text_alignment = {0.5, 0.5},
			font_size      = 16,
			margins        = {0, 0, 0, 0},
			padding        = {0, 0, 0, 0},
			border_width   = 1,
			pos            = {0, 0},
			size           = range2({},{})
		}
		style := UI_Style {
			bg_color     = Color_ThmDark_Btn_BG_Default,
			border_color = Color_ThmDark_Border_Default,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = Color_ThmDark_Text_Default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		{
			using layout_combo.hot
			using style_combo.hot
			bg_color   = Color_ThmDark_Btn_BG_Hot
			text_color = Color_ThmDark_Text_Hot
			margins    = {2, 2, 2, 2}
		}
		{
			using layout_combo.active
			using style_combo.active
			bg_color   = Color_ThmDark_Btn_BG_Active
			text_color = Color_ThmDark_Text_Active
			margins    = {2, 2, 2, 2}
		}
		theme = UI_Theme {
			layout_combo, style_combo
		}
		loaded = true
	}
	ui_layout_push(theme.layout)
	ui_style_push(theme.style)
}

@(deferred_none = ui_theme_pop)
ui_theme_transparent :: proc()
{
	@static theme : UI_Theme
	@static loaded : b32 = false
	if ! loaded || true
	{
		layout := UI_Layout {
			flags          = {},
			anchor         = range2({},{}),
			alignment      = {0, 0},
			text_alignment = {0.0, 0.0},
			font_size      = 16,
			margins        = {0, 0, 0, 0},
			padding        = {0, 0, 0, 0},
			border_width   = 0,
			pos            = {0, 0},
			size           = range2({},{})
		}
		style := UI_Style {
			bg_color     = Color_Transparent,
			border_color = Color_Transparent,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = Color_ThmDark_Text_Default,
			cursor       = {},
		}

		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		{
			using layout_combo.disabled
			using style_combo.disabled
		}
		{
			using layout_combo.hot
			using style_combo.hot
		}
		{
			using layout_combo.active
			using style_combo.active
		}

		theme = UI_Theme {
			layout_combo, style_combo
		}
		loaded = true
	}
	ui_layout_push(theme.layout)
	ui_style_push(theme.style)
}
