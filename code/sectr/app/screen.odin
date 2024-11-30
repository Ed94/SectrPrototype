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
	settings_menu : struct
	{
		container               : UI_Widget,
		engine_refresh_inputbox : UI_TextInputBox,
		min_zoom_inputbox       : UI_TextInputBox,
		max_zoom_inputbox       : UI_TextInputBox,
		cfg_drop_down           : UI_DropDown,
		zoom_mode_drop_down     : UI_DropDown,
		pos, size, min_size     : Vec2,
		is_open                 : b32,
		is_maximized            : b32,
	},
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

ui_screen_settings_menu :: proc( captures : rawptr = nil ) -> ( should_raise : b32 = false)
{
	profile("Settings Menu")
	using state := get_state()
	using state.screen_ui

	if ! settings_menu.is_open do return
	app_color := app_color_theme()

	using settings_menu
	if size.x < min_size.x do size.x = min_size.x
	if size.y < min_size.y do size.y = min_size.y

	Construct_Container:
	{
		scope(theme_window_panel)
		container = ui_widget("Settings Menu", {}); 	{
			using container
			layout.flags = { .Fixed_Width, .Fixed_Height, .Fixed_Position_X, .Fixed_Position_Y, .Origin_At_Anchor_Center }
			layout.pos   = pos
			layout.size  = range2( size, {})
		}
		if settings_menu.is_maximized {
			using container
			layout.flags = {.Origin_At_Anchor_Center }
			layout.pos   = {}
		}

		should_raise |= ui_resizable_handles( & container, & pos, & size)
	}
	ui_parent(container)

	vbox := ui_vbox_begin( .Top_To_Bottom, "Settings Menu: VBox", {.Mouse_Clickable}, compute_layout = true)
	{
		should_raise |= b32(vbox.active)
		ui_parent(vbox)

		Frame_Bar:
		{
			scope(theme_window_bar)
			frame_bar := ui_hbox(.Left_To_Right, "Settings Menu: Frame Bar", { .Mouse_Clickable })
			{
				ui_parent(frame_bar)

				scope(theme_text)
				title := ui_text("Settings Menu: Title", str_intern("Settings Menu"), {.Disabled}); {
					using title
					layout.anchor.ratio.x = 1.0
					layout.margins        = { 0, 0, 15, 0}
					layout.font_size      = 14
				}

				scope(theme_window_bar_btn)
				maximize_btn := ui_button("Settings Menu: Maximize Btn"); {
					using maximize_btn
					if maximize_btn.pressed {
						settings_menu.is_maximized = ~settings_menu.is_maximized
						should_raise = true
					}
					if settings_menu.is_maximized do text = str_intern("min")
					else do text = str_intern("max")
				}
				close_btn := ui_button("Settings Menu: Close Btn"); {
					using close_btn
					text = str_intern("close")
					if close_btn.hot     do style.bg_color =  app_color.window_btn_close_bg_hot
					if close_btn.pressed do settings_menu.is_open = false
					style.corner_radii = { 0, 0, 0, 0 }
				}
			}
			if frame_bar.active {
				pos += input.mouse.delta
				should_raise = true
			}
		}

		app_config := ui_drop_down( & cfg_drop_down, "settings_menu.config", str_intern("App Config"), vb_compute_layout = true)
		app_config.title.layout.font_size = 12
		if app_config.is_open
		{
			Engine_Refresh_Hz:
			{
				scope(theme_table_row(is_even = false))
				hb := ui_hbox(.Left_To_Right, "settings_menu.engine_refresh_hz.hb"); { using hb
					layout.size.min = {0, 25}
					layout.flags    = {.Fixed_Height}
					layout.padding  = to_ui_layout_side(4)
				}

				title : UI_Widget; {
					scope(theme_text)
					title = ui_text("settings_menu.engine_refresh_hz.title", str_intern("Engine Refresh Hz"))
					using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
					title.layout.font_size = 12
				}

				engine_refresh_config: {
					using min_zoom_inputbox
					digits_only            = true
					disallow_leading_zeros = true
					disallow_decimal       = true
					digit_min              = 1
					digit_max              = 9999
					max_length             = 4
				}
				ui_text_input_box( & engine_refresh_inputbox, "settings_menu.engine_refresh_hz.inputbox", allocator = persistent_slab_allocator() )
				{
					using engine_refresh_inputbox
					layout.flags          = {.Fixed_Width}
					layout.margins.left   = 5
					layout.padding.right  = 5
					layout.size.min.x     = 80
					style.corner_radii    = { 3, 3, 3, 3 }

					if was_active
					{
						value, success := parse_uint(to_string(array_to_slice(input_str)))
						if success {
							value = clamp(value, 1, 9999)
							config.engine_refresh_hz = value
						}
					}
					else
					{
						clear( input_str )
						append( & input_str, to_runes(str_fmt("%v", config.engine_refresh_hz)))
					}
				}
			}

			Min_Zoom:
			{
				scope( theme_table_row(is_even = true))
				hb := ui_hbox(.Left_To_Right, "settings_menu.cam_min_zoom.hb"); {
					using hb
					layout.size.min = {0, 25}
					layout.flags    = {.Fixed_Height}
					layout.padding  = to_ui_layout_side(4)
				}
				scope(theme_text)
				title := ui_text("settings_menu.cam_min_zoom.title", str_intern("Camera: Min Zoom")); {
					using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
					layout.font_size      = 12
				}

				min_zoom_config: {
					using min_zoom_inputbox
					digits_only            = true
					disallow_leading_zeros = false
					disallow_decimal       = false
					digit_min              = 0.01
					digit_max              = 9999
					max_length             = 5
				}
				ui_text_input_box( & min_zoom_inputbox, "settings_menu.cam_min_zoom.input_box", allocator = persistent_slab_allocator() )
				{
					using min_zoom_inputbox
					layout.flags          = {.Fixed_Width}
					layout.margins.left   = 5
					layout.padding.right  = 5
					layout.size.min.x     = 80
					style.corner_radii    = { 3, 3, 3, 3 }

					if was_active
					{
						value, success := parse_f32(to_string(array_to_slice(input_str)))
						if success {
							value = clamp(value, 0.001, 9999.0)
							config.cam_min_zoom = value
						}
					}
					else
					{
						clear( input_str )
						append( & input_str, to_runes(str_fmt("%v", config.cam_min_zoom)))
					}
				}
			}

			Max_Zoom:
			{
				scope( theme_table_row(is_even = false))
				hb := ui_hbox(.Left_To_Right, "settings_menu.cam_max_zoom.hb"); {
					using hb
					layout.size.min = {0, 25}
					layout.flags    = {.Fixed_Height}
					layout.padding  = to_ui_layout_side(4)
				}
				scope(theme_text)
				title := ui_text("settings_menu.cam_max_zoom.title", str_intern("Camera: Max Zoom")); {
					using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
					layout.font_size      = 12
				}

				max_zoom_config: {
					using max_zoom_inputbox
					digits_only            = true
					disallow_leading_zeros = false
					disallow_decimal       = false
					digit_min              = 0.01
					digit_max              = 9999
					max_length             = 5
					ui_text_input_box( & max_zoom_inputbox, "settings_menu.cam_max_zoom.input_box", allocator = persistent_slab_allocator() )
					{
						using max_zoom_inputbox
						layout.flags          = {.Fixed_Width}
						layout.margins.left   = 5
						layout.padding.right  = 5
						layout.size.min.x     = 80
						style.corner_radii    = { 3, 3, 3, 3 }

						if was_active
						{
							value, success := parse_f32(to_string(array_to_slice(input_str)))
							if success {
								value = clamp(value, 0.001, 9999.0)
								config.cam_max_zoom = value
							}
						}
						else
						{
							clear( input_str )
							append( & input_str, to_runes(str_fmt("%v", config.cam_max_zoom)))
						}
					}
				}
			}

			Zoom_Mode:
			{
				scope( theme_table_row(is_even = true))
				hb := ui_hbox(.Left_To_Right, "settings_menu.cam_zoom_mode.hb"); {
					using hb

					layout.size.min = {0, 35}
					layout.flags    = {.Fixed_Height}
					layout.padding  = to_ui_layout_side(4)
				}

				scope(theme_text)
				title := ui_text("settings_menu.cam_zoom_mode.title", str_intern("Camera: Zoom Mode")); {
					using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
					layout.font_size      = 12
				}

				// TODO(Ed): This is technically a manual drop-down as the vbox within ui_dropdown is unusuable for attaching the buttons
				// This can be alleviated if we add an option for the drop-down to support a floating vbox (fixed position computed, following drop_down btn)
				// For now its buttons are attached to app_config vbox
				mode_selector := ui_drop_down( & zoom_mode_drop_down, "settings_menu.cam_zoom_mode.drop_down", str_intern_fmt("%s", config.cam_zoom_mode), vb_compute_layout = true )
				mode_selector.btn.layout.size.min = { 80, mode_selector.btn.layout.size.min.y }
				if mode_selector.is_open
				{
					idx := 1
					for entry in CameraZoomMode
					{
						ui_parent(app_config.vbox)
						scope(theme_button)
						btn := ui_button(str_intern_fmt("settings_menu.cam_zoom_mode.%s.btn", entry).str)
						{
								using btn
								layout.size.min    = {100, 25}
								layout.alignment   = {1.0, 0}
								layout.anchor.left = 1.0
								layout.flags       = {.Fixed_Height}
								layout.padding     = to_ui_layout_side(4)

								ui_parent(btn)
								scope(theme_text)
								text_widget := ui_text(str_intern_fmt("settings_menu.cam_zoom_mode.%s.text", entry).str, str_intern_fmt("%s", entry))
						}

						if btn.pressed {
							mode_selector.should_close = true
							config.cam_zoom_mode       = entry
							screen_ui.active           = 0
						}
					}
				}
			}
		}
	}
	ui_vbox_end(vbox, compute_layout = false )
	return
}
