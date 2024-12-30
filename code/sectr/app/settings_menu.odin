package sectr

UI_SettingsMenu :: struct
{
	container                      : UI_Widget,
	engine_refresh_inputbox        : UI_TextInputBox,
	min_zoom_inputbox              : UI_TextInputBox,
	max_zoom_inputbox              : UI_TextInputBox,
	zoom_smooth_snappiness_input   : UI_TextInputBox,
	zoom_smooth_sensitivity_input  : UI_TextInputBox,
	zoom_digital_sensitivity_input : UI_TextInputBox,
	zoom_scroll_delta_scale_input  : UI_TextInputBox,
	font_size_canvas_scalar_input  : UI_TextInputBox,
	font_size_screen_scalar_input  : UI_TextInputBox,
	cfg_drop_down                  : UI_DropDown,
	zoom_mode_drop_down            : UI_DropDown,
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
	if size.x < min_size.x do size.x = min_size.x
	if size.y < min_size.y do size.y = min_size.y

	scope(theme_window_panel)
	container = ui_widget("Settings Menu: Window", {});
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
				min_size.y = joined_size.y
				if min_size.y > size.y {
					pos.y            += (layout.size.min.y - min_size.y) * 0.5
					layout.pos        = pos
					layout.size.min.y = min_size.y
				}
			}
		}
	}
	ui_parent_push(container)

	vbox := ui_vbox_begin( .Top_To_Bottom, "Settings Menu: VBox", {.Mouse_Clickable}, compute_layout = true )
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
		dd_app_config := ui_drop_down( & cfg_drop_down, "settings_menu.config", str_intern("App Config"), vb_compute_layout = true);
		app_config_closed:
		{
			dd_app_config.title.layout.font_size = 12
			should_raise |= cast(b32) dd_app_config.btn.active
			if ! dd_app_config.is_open do break app_config_closed

			ui_settings_entry_inputbox :: proc( input_box : ^UI_TextInputBox, is_even : bool, label : string, setting_title : StrRunesPair, input_policy : UI_TextInput_Policy )
			{
				scope( theme_table_row(is_even))
				hb := ui_hbox(.Left_To_Right, str_intern_fmt("%v.hb", label).str); {
					using hb

					layout.size.min = {0, 25}
					layout.flags    = {.Fixed_Height}
					layout.padding  = to_ui_layout_side(4)
				}

				scope(theme_text)
				title := ui_text(str_intern_fmt("%v.title", label).str, setting_title); {
					using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
					layout.font_size      = 12
				}

				ui_text_input_box( input_box, str_intern_fmt("%v.input_box", label).str, allocator = persistent_slab_allocator(), policy = input_policy )
				{
					using input_box
					layout.flags          = {.Fixed_Width}
					layout.margins.left   = 5
					layout.padding.right  = 5
					layout.size.min.x     = 80
					style.corner_radii    = { 3, 3, 3, 3 }
				}
			}

			config := app_config()

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
				mode_selector := ui_drop_down( & zoom_mode_drop_down, "settings_menu.cam_zoom_mode.drop_down", str_intern_fmt("%s", config.cam_zoom_mode), vb_compute_layout = true );
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

			Font_Size_Screen_Scalar:
			{
				ui_settings_entry_inputbox( & font_size_screen_scalar_input, false, "settings_menu.font_size_screen_scalar", str_intern("Font: Size Screen Scalar"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using font_size_screen_scalar_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.font_size_screen_scalar = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.font_size_screen_scalar)))
				}
			}

			Font_Size_Canvas_Scalar:
			{
				ui_settings_entry_inputbox( & font_size_canvas_scalar_input, false, "settings_menu.font_size_canvas_scalar", str_intern("Font: Size Canvas Scalar"),
					UI_TextInput_Policy {
						digits_only            = true,
						disallow_leading_zeros = false,
						disallow_decimal       = false,
						digit_min              = 0.01,
						digit_max              = 9999,
						max_length             = 5,
					}
				)
				using font_size_canvas_scalar_input

				if was_active
				{
					value, success := parse_f32(to_string(array_to_slice(input_str)))
					if success {
						value = clamp(value, 0.001, 9999.0)
						config.font_size_canvas_scalar = value
					}
				}
				else
				{
					clear( input_str )
					append( & input_str, to_runes(str_fmt("%v", config.font_size_canvas_scalar)))
				}
			}
		}
	}
	ui_vbox_end(vbox, compute_layout = false )

	ui_parent_pop() // container
	return
}

ui_settings_menu_open :: #force_inline proc "contextless" () {
	get_state().screen_ui.settings_menu.is_open = true
}
