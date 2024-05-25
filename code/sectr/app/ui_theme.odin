package sectr

/*
UI Themes: Comprise of UI_Box's layout & style

Provides presets for themes and their interface for manipulating the combo stacks in UI_State in pairs

The preset UI_Theme structs are populated using theme_<name> procedures.
There are boilerplate procedures that do ui_theme( theme_<name>()) for the user as ui_theme_<name>().
*/
// TODO(Ed): Eventually this will have a configuration wizard, and we'll save the presets

theme_button :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
		layout := UI_Layout {
			flags          = {},
			anchor         = range2_zero,
			alignment      = {0, 0},
			text_alignment = {0.5, 0.5},
			font_size      = 16,
			margins        = {0, 0, 0, 0},
			padding        = {0, 0, 0, 0},
			border_width   = 1,
			pos            = {0, 0},
			size           = range2_zero,
		}
		style := UI_Style {
			bg_color     = app_color.btn_bg_default,
			border_color = app_color.border_default,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = app_color.text_default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		Hot: {
			using layout_combo.hot
			using style_combo.hot
			bg_color   = app_color.btn_bg_hot
			text_color = app_color.text_hot
		}
		Active: {
			using layout_combo.active
			using style_combo.active
			bg_color   = app_color.btn_bg_active
			text_color = app_color.text_active
			margins    = {2, 2, 2, 2}
		}
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_drop_down_btn :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
		layout := UI_Layout {
			flags          = {.Fixed_Height},
			anchor         = range2({0, 0},{}),
			alignment      = {0, 0},
			text_alignment = {0.5, 0.5},
			font_size      = 14,
			margins        = {0, 0, 0, 0},
			padding        = {0, 0, 0, 0},
			border_width   = 1,
			pos            = {0, 0},
			size           = range2({0,20},{})
		}
		style := UI_Style {
			bg_color     = app_color.btn_bg_default,
			border_color = app_color.border_default,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = app_color.text_default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		Hot: {
			using layout_combo.hot
			using style_combo.hot
			bg_color   = app_color.btn_bg_hot
			text_color = app_color.text_hot
			margins    = {2, 2, 2, 2}
		}
		Active: {
			using layout_combo.active
			using style_combo.active
			bg_color   = app_color.btn_bg_active
			text_color = app_color.text_active
			margins    = {2, 2, 2, 2}
		}
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_table_row :: proc( is_even : bool ) -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
		table_bg : RGBA8
		if is_even {
			table_bg = app_color.table_even_bg
		}
		else {
			table_bg = app_color.table_odd_bg
		}
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
			bg_color     = table_bg,
			border_color = Color_Transparent,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = app_color_theme().text_default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		Hot: {
			using layout_combo.disabled
			using style_combo.disabled
		}
		Active: {
			using layout_combo.hot
			using style_combo.hot
		}
		{
			using layout_combo.active
			using style_combo.active
		}
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_window_bar :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
		layout := UI_Layout {
			flags          = {.Fixed_Height},
			anchor         = range2({},{}),
			alignment      = {0, 0},
			text_alignment = {0.0, 0.0},
			font_size      = 16,
			margins        = {0, 0, 0, 0},
			padding        = {0, 0, 0, 0},
			border_width   = 0.0,
			pos            = {0, 0},
			size           = range2({0, 35},{})
		}
		style := UI_Style {
			bg_color     = app_color.window_bar_bg,
			border_color = Color_Transparent,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = app_color.text_default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		Disabled : {
			using layout_combo.disabled
			using style_combo.disabled
		}
		Hot: {
			using layout_combo.hot
			using style_combo.hot
			border_color = app_color.window_bar_border
			border_width = 1.0
		}
		Active: {
			using layout_combo.active
			using style_combo.active
			border_color = app_color.window_bar_border
			border_width = 2.0
		}
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_window_bar_title :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
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
			text_color   = app_color.text_default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		Disabed: {
			using layout_combo.disabled
			using style_combo.disabled
		}
		Hot: {
			using layout_combo.hot
			using style_combo.hot
		}
		Active: {
			using layout_combo.active
			using style_combo.active
		}
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_window_bar_btn :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
		layout := UI_Layout {
			flags          = {.Fixed_Width},
			anchor         = range2({1, 0},{}),
			alignment      = {0, 0},
			text_alignment = {0.5, 0.5},
			font_size      = 16,
			margins        = {0, 0, 0, 0},
			padding        = {0, 0, 0, 0},
			border_width   = 1,
			pos            = {0, 0},
			size           = range2({50,0},{})
		}
		style := UI_Style {
			bg_color     = app_color.btn_bg_default,
			border_color = app_color.border_default,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = app_color.text_default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		Hot: {
			using layout_combo.hot
			using style_combo.hot
			bg_color   = app_color.btn_bg_hot
			text_color = app_color.text_hot
		}
		Active: {
			using layout_combo.active
			using style_combo.active
			bg_color   = app_color.btn_bg_active
			text_color = app_color.text_active
			margins    = {2, 2, 2, 2}
		}
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_window_panel :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
		layout := UI_Layout {
			flags          = {},
			anchor         = range2({},{}),
			alignment      = {0, 0},
			text_alignment = {0.0, 0.0},
			font_size      = 16,
			margins        = {0, 0, 0, 0},
			padding        = {0, 0, 0, 0},
			border_width   = 1,
			pos            = {0, 0},
			size           = range2({},{})
		}
		style := UI_Style {
			bg_color     = app_color.window_panel_bg,
			border_color = app_color.window_panel_border,
			corner_radii = {},
			blur_size    = 0,
			font         = get_state().default_font,
			text_color   = app_color.text_default,
			cursor       = {},
		}
		layout_combo := to_ui_layout_combo(layout)
		style_combo  := to_ui_style_combo(style)
		Disabled: {
			using layout_combo.disabled
			using style_combo.disabled
		}
		Hot: {
			using layout_combo.hot
			using style_combo.hot
		}
		Active: {
			using layout_combo.active
			using style_combo.active
		}
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_transparent :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
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
			text_color   = app_color.text_default,
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
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}

theme_text :: proc() -> UI_Theme
{
	@static theme  : UI_Theme
	@static loaded : b32 = false
	if ! loaded
	{
		app_color := app_color_theme()
		layout := UI_Layout {
			flags          = {},
			anchor         = range2({},{}),
			alignment      = {0, 0},
			text_alignment = {0.0, 0.5},
			font_size      = 14,
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
			text_color   = app_color.text_default,
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
		theme  = UI_Theme { layout_combo, style_combo }
		loaded = true
	}
	return theme
}
