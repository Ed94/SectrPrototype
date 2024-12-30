package sectr

UI_ScreenState :: struct
{
	using base : UI_State,

	floating : UI_FloatingManager,

	// TODO(Ed): The docked should be the base, floating is should be nested within as a 'veiwport' to a 'desktop' or 'canvas'
	// docked : UI_Docking,

	menu_bar : struct
	{
		pos, size    : Vec2,
		container    : UI_HBox,
		settings_btn : struct
		{
			using widget : UI_Widget,
		}
	},

	settings_menu : UI_SettingsMenu
}

ui_screen_reload :: proc() {
	using state := get_state()
	using screen_ui.settings_menu

	min_zoom_inputbox.input_str.backing = persistent_slab_allocator()
	max_zoom_inputbox.input_str.backing = persistent_slab_allocator()
}

ui_screen_tick :: proc() {
	profile("Screenspace Imgui")

	using state := get_state()
	ui_graph_build( & screen_ui )
	ui := ui_context

	ui_floating_manager( & screen_ui.floating )
	ui_floating("Menu Bar",      ui_screen_menu_bar)
	ui_floating("Settings Menu", ui_screen_settings_menu)
}

ui_screen_menu_bar :: proc( captures : rawptr = nil ) -> (should_raise : b32 = false )
{
	profile("App Menu Bar")

	theme_app_menu_bar :: proc() -> UI_Theme
	{
		@static theme  : UI_Theme
		@static loaded : b32 = false
		if ! loaded || true
		{
			app_color := app_color_theme()
			layout := UI_Layout {
				flags          = {},
				anchor         = range2({},{}),
				// alignment      = UI_Align_Presets.text_centered,
				text_alignment = {0.0, 0},
				font_size      = 10,
				margins        = {0, 0, 0, 0},
				padding        = {0, 0, 0, 0},
				border_width   = 1.0,
				pos            = {0, 0},
				size           = range2({},{})
			}
			style := UI_Style {
				bg_color     = app_color.bg,
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
			}
			theme = UI_Theme { layout_combo, style_combo }
			loaded = true
		}
		return theme
	}

	using state := get_state()
	using screen_ui
	using screen_ui.menu_bar

	scope(theme_app_menu_bar)
	container = ui_hbox( .Left_To_Right, "Menu Bar" ); {
		using container
		layout.flags = {.Fixed_Position_X, .Fixed_Position_Y, .Fixed_Width, .Fixed_Height, .Origin_At_Anchor_Center}
		layout.pos   = pos
		layout.size  = range2( size, {})
		text         = str_intern("menu_bar")
	}
	scope(theme_transparent)

	move_box : UI_Widget; {
		scope(theme_button)
		move_box = ui_button("Move Box")
		using move_box
		layout.size.min.x = 20
		if active {
			pos         += input.mouse.delta
			should_raise = true
		}
	}

	spacer := ui_spacer("Menu Bar: Move Spacer")
	spacer.layout.flags |= {.Fixed_Width}
	spacer.layout.size.min.x = 30

	Build_Settings_Btn: {
		scope(theme_button)
		using settings_btn
		widget              = ui_button("Menu Bar: Settings Btn")
		text                = str_intern("Settings")
		layout.flags        = { .Scale_Width_By_Height_Ratio }
		layout.size.ratio.x = 2.0
		if pressed do screen_ui.settings_menu.is_open = true
	}
	return
}
