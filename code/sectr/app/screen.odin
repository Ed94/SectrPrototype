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
		container           : UI_Widget,
		cfg_drop_down       : UI_DropDown,
		pos, size, min_size : Vec2,
		is_open             : b32,
		is_maximized        : b32,
	},
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
		@static theme : UI_Theme
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
			Engien_Refresh_Hz:
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

				iter_next :: next
				input_box := ui_widget("settings_menu.engine_refresh.input_box", {.Mouse_Clickable, .Focusable, .Click_To_Focus}); {
					using input_box
					layout.flags          = {.Fixed_Width}
					layout.margins.left   = 5
					layout.padding.right  = 5
					layout.size.min.x     = 80
					style.corner_radii = { 3, 3, 3, 3 }

					if      input_box.active do style.bg_color = app_color.input_box_bg_active
					else if input_box.hot    do style.bg_color = app_color.input_box_bg_hot
					else                     do style.bg_color = app_color.input_box_bg

					@static max_value_length : u64 = 4

					@static value_str : Array(rune)
					if value_str.header == nil {
						error : AllocatorError
						value_str, error = make( Array(rune), Kilo, persistent_slab_allocator())
						ensure(error == AllocatorError.None, "Failed to allocate array for value_str of input_box")
					}

					if input_box.pressed {
						array_clear( value_str )
					}

					if input_box.active {
						if ! input_box.was_active {
							debug.last_invalid_input_time._nsec = 0
						}

						iter_obj  := iterator( & input_events.key_events ); iter := & iter_obj
						for event := iter_next( iter ); event != nil; event = iter_next( iter )
						{
							if event.frame_id != state.frame do break

							if event.key == .backspace && event.type == .Key_Pressed {
								if value_str.num > 0 {
										pop( value_str)
										break
								}
							}

							if event.key == .enter && event.type == .Key_Pressed {
								screen_ui.active = 0
							}
						}

						// append( & value_str, input_events.codes_pressed )
						for code in to_slice(input_events.codes_pressed) {
								if value_str.num == 0 && code == '0' {
									debug.last_invalid_input_time = time_now()
									continue
								}

								if value_str.num >= max_value_length {
									debug.last_invalid_input_time = time_now()
									continue
								}

								// Only accept characters 0-9
								if '0' <= code && code <= '9' {

									append(&value_str, code)
								}
								else {
									debug.last_invalid_input_time = time_now()
									continue
								}
						}
						clear( input_events.codes_pressed )

						invalid_color := RGBA8 { 70, 50, 50, 255}

						// Visual feedback - change background color briefly when invalid input occurs
						feedback_duration :: 0.2 // seconds
						curr_duration := duration_seconds( time_diff( debug.last_invalid_input_time, time_now() ))
						if debug.last_invalid_input_time._nsec != 0 && curr_duration < feedback_duration {
								input_box.style.bg_color = invalid_color // Or a specific error color from your theme
						}
					}
					else if input_box.was_active
					{
						value, success := parse_uint(to_string(array_to_slice(value_str)))
						if success {
							value = clamp(value, 1, 9999)
							config.engine_refresh_hz = value
						}
					}
					else
					{
						clear( value_str)
						append( & value_str, to_runes(str_fmt("%v", config.engine_refresh_hz)))
					}
					ui_parent(input_box)

					value_txt : UI_Widget; {
						scope(theme_text)
						value_txt = ui_text("settings_menu.engine_refresh.input_box.value", to_str_runes_pair(array_to_slice(value_str)))
						using value_txt
						layout.alignment      = {0.0, 0.0}
						layout.text_alignment = {1.0, 0.5}
						layout.anchor.left    = 0.0
						// layout.flags          = {.Fixed_Width}
						layout.size.min       = cast(Vec2) measure_text_size( value_txt.text.str, value_txt.style.font, value_txt.layout.font_size, 0 )
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
			}
		}
	}
	ui_vbox_end(vbox, compute_layout = false )
	return
}
