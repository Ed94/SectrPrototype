package sectr

UI_SettingsMenu :: struct
{
	// using window : UI_Window,
	engine_refresh_inputbox        : UI_TextInputBox,
	min_zoom_inputbox              : UI_TextInputBox,
	max_zoom_inputbox              : UI_TextInputBox,
	zoom_smooth_snappiness_input   : UI_TextInputBox,
	zoom_smooth_sensitivity_input  : UI_TextInputBox,
	zoom_digital_sensitivity_input : UI_TextInputBox,
	zoom_scroll_delta_scale_input  : UI_TextInputBox,
	text_snap_glyph_shape_posiiton : UI_TextInputBox,
	text_snap_glyph_render_height  : UI_TextInputBox,
	text_size_canvas_scalar_input  : UI_TextInputBox,
	text_size_screen_scalar_input  : UI_TextInputBox,
	text_alpha_sharpen             : UI_TextInputBox,
	cfg_drop_down                  : UI_DropDown,
	zoom_mode_drop_down            : UI_DropDown,

	// Window
	container                      : UI_Widget,
	pos, size, min_size            : Vec2,
	is_open                        : b32,
	is_maximized                   : b32,
}

ui_settings_menu_builder :: proc( captures : rawptr = nil ) -> ( should_raise : b32 = false)
{
	profile("Settings Menu")
	settings_menu := cast(^UI_SettingsMenu) captures
	if ! settings_menu.is_open do return

	app_color := app_color_theme()

	using settings_menu
	if size.x < settings_menu.min_size.x do size.x = settings_menu.min_size.x
	if size.y < settings_menu.min_size.y do size.y = settings_menu.min_size.y

	scope(theme_window_panel)
	// ui_window(& window, "settings_menu.window",  )
	container = ui_widget("Settings Menu: Window", {});
	// when false
	setup_container:
	{
		using container
		if ! is_maximized
		{
			layout.flags = {
				// .Size_To_Content,
				.Fixed_Width, .Fixed_Height,
				// .Min_Size_To_Content_Y,
				.Fixed_Position_X, .Fixed_Position_Y,
				.Origin_At_Anchor_Center
			}
			layout.pos   = pos
			layout.size  = range2( size, {})
		}
		else
		{
			layout.flags = {.Origin_At_Anchor_Center }
			layout.pos   = {}
		}

		dragged      := ui_resizable_handles( & container, & pos, & size)
		should_raise |= dragged

		// TODO(Ed): This demonstrated a minimum viable-size window to content, however we still need to support a scroll box and switch this window to that.
		old_vbox := ui_box_from_key(get_ui_context_mut().prev_cache, ui_key_from_string("Settings Menu: VBox"))
		if old_vbox != nil
		{
			vbox_children_bounds := ui_compute_children_overall_bounds(old_vbox)
			joined_size          := size_range2( vbox_children_bounds )
			if ! dragged
			{
				// TODO(Ed): Figure out what this value is
				extra_padding :: 3
				min_size.y = joined_size.y + layout.border_width + extra_padding
				if min_size.y > size.y {
					pos.y            += (layout.size.min.y - min_size.y) * 0.5
					layout.pos        = pos
					layout.size.min.y = min_size.y
				}
			}
		}
	}
	ui_parent(container)

	scope(theme_transparent)
	vbox := ui_vbox_begin( .Top_To_Bottom, "Settings Menu: VBox", {.Mouse_Clickable}, compute_layout = false )
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
				pos += get_input_state().mouse.delta
				should_raise = true
			}
		}

		// TODO(Ed): This will eventually be most likely generalized/compressed. For now its the main scope for implementing new widgets.
		dd_app_config := ui_drop_down( & cfg_drop_down, "settings_menu.dd_app_config", str_intern("App Config"), vb_compute_layout = false);
		app_config_closed:
		{
			dd_app_config.title.layout.font_size = 12
			should_raise |= cast(b32) dd_app_config.btn.active
			if ! dd_app_config.is_open do break app_config_closed
			ui_size_to_content_y( dd_app_config.vbox)

			ui_settings_entry_inputbox :: proc( input_box : ^UI_TextInputBox, is_even : bool, label : string, setting_title : StrCached, input_policy : UI_TextInput_Policy )
			{
				scope( theme_table_row(is_even))
				hb := ui_hbox(.Left_To_Right, str_fmt("%v.hb", label)); {
					using hb

					layout.size.min  = {0, 25}
					layout.flags    |= {.Fixed_Height}
					layout.padding   = to_ui_layout_side(4)
				}

				scope(theme_text)
				title := ui_text(str_fmt("%v.title", label), setting_title); {
					using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
					layout.font_size      = 12
				}

				ui_text_input_box( input_box, str_fmt("%v.input_box", label), policy = input_policy, allocator = persistent_slab_allocator() )
				{
					using input_box
					layout.flags          |= {.Fixed_Width}
					layout.margins.left    = 5
					layout.padding.right   = 5
					layout.size.min.x      = 80
					style.corner_radii     = { 3, 3, 3, 3 }
				}
			}

			config := & get_state().config

			Engine_Refresh_Hz:
			{
				scope(theme_table_row(is_even = false))
				hb := ui_hbox(.Left_To_Right, "settings_menu.engine_refresh_hz.hb"); { using hb
					layout.size.min  = {0, 25}
					layout.flags    |= {.Fixed_Height}
					layout.padding   = to_ui_layout_side(4)
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
					layout.size.min  = {0, 25}
					layout.flags    |= {.Fixed_Height}
					layout.padding   = to_ui_layout_side(4)
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
					digit_min              = 0.00001
					digit_max              = 1.0
					max_length             = 7
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
							value = clamp(value, 0.000001, 1.0)
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
					layout.size.min  = {0, 25}
					layout.flags    |= {.Fixed_Height}
					layout.padding   = to_ui_layout_side(4)
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
					digit_min              = 1.0
					digit_max              = 99
					max_length             = 2
					ui_text_input_box( & max_zoom_inputbox, "settings_menu.cam_max_zoom.input_box", allocator = persistent_slab_allocator() )
					{
						using max_zoom_inputbox
						layout.flags          |= {.Fixed_Width}
						layout.margins.left    = 5
						layout.padding.right   = 5
						layout.size.min.x      = 80
						style.corner_radii     = { 3, 3, 3, 3 }

						if was_active
						{
							value, success := parse_f32(to_string(array_to_slice(input_str)))
							if success {
								value = clamp(value, 0.001, 99.0)
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

					layout.size.min  = {0, 35}
					layout.flags    |= {.Fixed_Height}
					layout.padding   = to_ui_layout_side(4)
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
				mode_selector := ui_drop_down( & zoom_mode_drop_down, "settings_menu.cam_zoom_mode.drop_down", str_intern_fmt("%s", config.cam_zoom_mode), vb_compute_layout = false );
				mode_selector_closed:
				{
					using mode_selector
					btn.layout.size.min = { 80, btn.layout.size.min.y }
					if ! is_open do break mode_selector_closed

					idx := 1
					for entry in CameraZoomMode
					{
						ui_parent(dd_app_config.vbox)
						scope(theme_button)
						btn := ui_button(str_fmt("settings_menu.cam_zoom_mode.%s.btn", entry))
						{
								using btn
								layout.size.min     = {100, 25}
								layout.alignment    = {1.0, 0}
								layout.anchor.left  = 1.0
								layout.flags       |= {.Fixed_Height}
								layout.padding      = to_ui_layout_side(4)

								ui_parent(btn)
								scope(theme_text)
								text_widget := ui_text(str_fmt("settings_menu.cam_zoom_mode.%s.text", entry), str_intern_fmt("%s", entry))
						}

						if btn.pressed {
							mode_selector.should_close  = true
							config.cam_zoom_mode        = entry
							get_ui_context_mut().active = 0
						}
					}
				}
			}

			Cam_Zoom_Smooth_Snappiness:
			{
				ui_settings_entry_inputbox( & zoom_smooth_snappiness_input, false, "settings_menu.cam_zoom_smooth_snappiness", str_intern("Camera: Zoom Smooth Snappiness"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using zoom_smooth_snappiness_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.cam_zoom_smooth_snappiness = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.cam_zoom_smooth_snappiness)))
				}
			}

			Cam_Zoom_Sensitivity_Smooth:
			{
				ui_settings_entry_inputbox( & zoom_smooth_sensitivity_input, true, "settings_menu.cam_zoom_sensitivity_smooth", str_intern("Camera: Zoom Smooth Sensitivity"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using zoom_smooth_sensitivity_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.cam_zoom_sensitivity_smooth = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.cam_zoom_sensitivity_smooth)))
				}
			}

			Cam_Zoom_Sensitivity_Digital:
			{
				ui_settings_entry_inputbox( & zoom_digital_sensitivity_input, false, "settings_menu.cam_zoom_sensitivity_digital", str_intern("Camera: Zoom Digital Sensitivity"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using zoom_digital_sensitivity_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.cam_zoom_sensitivity_digital = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.cam_zoom_sensitivity_digital)))
				}
			}

			Cam_Zoom_Scroll_Delta_Scale:
			{
				ui_settings_entry_inputbox( & zoom_scroll_delta_scale_input, true, "settings_menu.cam_zoom_scroll_delta_scale", str_intern("Camera: Zoom Scroll Delta Scale"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using zoom_scroll_delta_scale_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.cam_zoom_scroll_delta_scale = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.cam_zoom_scroll_delta_scale)))
				}
			}

			Text_Snap_Glyph_Shape_Position:
			{
				ui_settings_entry_inputbox( & text_snap_glyph_shape_posiiton, false, "settings_menu.text_snap_glyph_shape_posiiton", str_intern("Text: Snap Glyph Shape Position"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0,
						digit_max              = 1,
						max_length             = 1,
					}
				)
				using text_snap_glyph_shape_posiiton

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0, 1)
						value_b32 := cast(b32) i32(value)
						if config.text_snap_glyph_shape_position != value_b32 {
							font_provider_flush_caches()
							font_provider_set_snap_glyph_shape_position( value_b32 )
							config.text_snap_glyph_shape_position = value_b32
						}
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes( str_fmt("%v", i32(config.text_snap_glyph_shape_position) ) ))
				}
			}

			Text_Snap_Glyph_Render_Height:
			{
				ui_settings_entry_inputbox( & text_snap_glyph_render_height, false, "settings_menu.text_snap_glyph_render_height", str_intern("Text: Snap Glyph Render Height"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0,
						digit_max              = 1,
						max_length             = 1,
					}
				)
				using text_snap_glyph_render_height

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0, 1)
						value_b32 := cast(b32) i32(value)
						if config.text_snap_glyph_render_height != value_b32 {
							font_provider_flush_caches()
							font_provider_set_snap_glyph_render_height( value_b32 )
							config.text_snap_glyph_render_height = value_b32
						}
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes( str_fmt("%v", i32(config.text_snap_glyph_render_height) ) ))
				}
			}

			Text_Size_Screen_Scalar:
			{
				ui_settings_entry_inputbox( & text_size_screen_scalar_input, false, "settings_menu.text_size_screen_scalar", str_intern("Text: Size Screen Scalar"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using text_size_screen_scalar_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.text_size_screen_scalar = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.text_size_screen_scalar)))
				}
			}

			Text_Size_Canvas_Scalar:
			{
				ui_settings_entry_inputbox( & text_size_canvas_scalar_input, false, "settings_menu.text_size_canvas_scalar", str_intern("Text: Size Canvas Scalar"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using text_size_canvas_scalar_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.text_size_canvas_scalar = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.text_size_canvas_scalar)))
				}
			}

			Text_Alpha_Sharpen:
			{
				ui_settings_entry_inputbox( & text_alpha_sharpen, false, "settings_menu.text_alpha_sharpen", str_intern("Text: Alpha Sharpen"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.001,
						digit_max              = 999,
						max_length             = 4,
					}
				)
				using text_alpha_sharpen

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0, 10.0)
						config.text_alpha_sharpen = value
						font_provider_set_alpha_sharpen(value)
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.text_alpha_sharpen)))
				}
			}
		}
	}
	ui_vbox_end(vbox, compute_layout = false )
	return
}

ui_settings_menu_open :: #force_inline proc "contextless" () {
	get_state().screen_ui.settings_menu.is_open = true
}
