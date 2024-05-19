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
		pos, size, min_size : Vec2,
		container           : UI_Widget,
		is_open             : b32,
		is_maximized        : b32,
	},
}

ui_screen_tick :: proc() {
	profile("Screenspace Imgui")

	using state := get_state()
	ui_graph_build( & screen_ui )
	ui := ui_context

	ui_floating_manager_begin( & screen_ui.floating )
	{
		ui_floating("Menu Bar",      ui_screen_menu_bar)
		ui_floating("Settings Menu", ui_screen_settings_menu)
	}
	ui_floating_manager_end()
}

ui_screen_menu_bar :: proc( captures : rawptr = nil ) -> (should_raise : b32 = false )
{
	profile("App Menu Bar")
	fmt :: str_fmt_alloc

	@(deferred_none = ui_theme_pop)
	ui_theme_app_menu_bar_default :: proc()
	{
		@static theme : UI_Theme
		@static loaded : b32 = false
		if ! loaded
		{
			app_color := app_color_theme()
			layout := UI_Layout {
				flags          = {},
				anchor         = range2({},{}),
				// alignment      = UI_Align_Presets.text_centered,
				text_alignment = {0.0, 1.5},
				font_size      = 12,
				margins        = {0, 0, 0, 0},
				padding        = {0, 0, 0, 0},
				border_width   = 0.6,
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
		ui_layout_push(theme.layout)
		ui_style_push(theme.style)
	}

	using state := get_state()
	using screen_ui
	{
		using screen_ui.menu_bar
		ui_theme_app_menu_bar_default()
		container = ui_hbox_begin( .Left_To_Right, "Menu Bar" )
		ui_parent(container)
		{
			using container
			layout.flags = {.Fixed_Position_X, .Fixed_Position_Y, .Fixed_Width, .Fixed_Height, .Origin_At_Anchor_Center}
			layout.pos            = pos
			layout.size           = range2( size, {})
			text = str_intern("menu_bar")
		}

		ui_theme_btn()
		move_box := ui_button("Move Box");
		{
			using move_box
			if active {
				pos += input.mouse.delta
				should_raise = true
			}
			layout.anchor.ratio.x = 1.0
		}

		spacer := ui_spacer("Menu Bar: Move Spacer")
		spacer.layout.flags |= {.Fixed_Width}
		spacer.layout.size.min.x = 30

		// TODO(Ed): Implement an external composition for theme interpolation using the settings btn
		settings_btn.widget = ui_button("Menu Bar: Settings Btn")
		{
			using settings_btn
			text = str_intern("Settings")
			layout.flags = {
				.Scale_Width_By_Height_Ratio,
				// .Fixed_Width
			}
			layout.size.ratio.x = 2.0
			if pressed {
				screen_ui.settings_menu.is_open = true
			}
		}
		spacer = ui_spacer("Menu Bar: End Spacer")
		spacer.layout.anchor.ratio.x = 2.0

		ui_hbox_end(container, compute_layout = false)
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

	ui_theme_window_panel()
	container = ui_widget("Settings Menu", {}); 	{
		using container
		layout.flags = { .Fixed_Width, .Fixed_Height, .Fixed_Position_X, .Fixed_Position_Y, .Origin_At_Anchor_Center }
		layout.pos   = pos
		layout.size  = range2( size, {})
	}
	ui_parent(container)
	if settings_menu.is_maximized {
		using container
		layout.flags = {.Origin_At_Anchor_Center }
		layout.pos   = {}
	}
	should_raise |= ui_resizable_handles( & container, & pos, & size)

	vbox := ui_vbox_begin( .Top_To_Bottom, "Settings Menu: VBox", {.Mouse_Clickable}, compute_layout = true)
	{
		should_raise |= b32(vbox.active)
		ui_parent(vbox)

		ui_theme_window_bar()
		frame_bar := ui_hbox_begin(.Left_To_Right, "Settings Menu: Frame Bar", { .Mouse_Clickable })
		{
			ui_parent(frame_bar)
			ui_theme_text()
			title := ui_text("Settings Menu: Title", str_intern("Settings Menu"), {.Disabled}); {
				using title
				layout.anchor.ratio.x = 1.0
				layout.margins        = { 0, 0, 15, 0}
				layout.font_size      = 16
			}
			ui_theme_window_bar_btn()
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
			}
			ui_hbox_end(frame_bar, compute_layout = true)
		}
		if frame_bar.active {
			pos += input.mouse.delta
			should_raise = true
		}

		@static config_drop_down_open := false
		ui_theme_drop_down()
		drop_down_bar := ui_hbox_begin(.Left_To_Right, "settings_menu.vbox: config drop_down_bar", {.Mouse_Clickable })
		{
			ui_parent_push(drop_down_bar)
			{
				using drop_down_bar
				text = str_intern("drop_down_bar")
				layout.text_alignment = {1, 0}
				layout.anchor.ratio.y = 1.0
			}
			ui_theme_text()
			title := ui_text("drop_down_bar.btn", str_intern("drop_down_bar.btn")); {
				using title
				text = str_intern("App Config")
				style.text_color      = drop_down_bar.style.text_color
				layout.alignment      = {0.0, 0.0}
				layout.text_alignment = {0.0, 0.5}
				layout.anchor.ratio.x = 1.0
			}
			ui_parent_pop()
			ui_hbox_end(drop_down_bar, compute_layout = true)
			if drop_down_bar.pressed do config_drop_down_open = !config_drop_down_open
		}

		if config_drop_down_open
		{
			{
				ui_theme_table_row(is_even = false)
				hb := ui_hbox(.Left_To_Right, "settings_menu.engine_refresh_hz.hb"); { using hb
					layout.size.min = {0, 30}
					layout.flags = {.Fixed_Height}
					layout.padding = to_ui_layout_side(4)
				}
				ui_theme_text(); title := ui_text("settings_menu.engine_refresh_hz.title", str_intern("Engine Refresh Hz")); { using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left = 10
					layout.text_alignment = {0, 0.5}

				}
				input_box := ui_widget("settings_menu.engine_refresh.input_box", {.Mouse_Clickable, .Focusable, .Click_To_Focus}); { using input_box
					layout.flags = {.Fixed_Width}
					layout.margins.left = 5
					layout.padding.right = 10
					layout.size.min.x = 80
					if input_box.active do style.bg_color = app_color.input_box_bg_active
					else if input_box.hot do style.bg_color = app_color.input_box_bg_hot
					else do style.bg_color = app_color.input_box_bg
					style.corner_radii[0] = 0.35
				}
				@static value_str : Array(rune)
				if value_str.data == nil {
					error : AllocatorError
					value_str, error = array_init_reserve(rune, persistent_slab_allocator(), Kilo)
					ensure(error != AllocatorError.None, "Failed to allocate array for value_str of input_box")
					array_append( & value_str, rune('_'))
				}
				if input_box.active {
					array_append( & value_str, input.keyboard_events.chars_pressed )
					array_clear( input.keyboard_events.chars_pressed )
				}
				else if input_box.was_active {

				}
				else {
					array_clear( value_str)
					array_append( & value_str, to_runes(str_fmt_alloc("%v", config.engine_refresh_hz)))
				}
				// input_box
				{
					ui_parent(input_box)
					value_txt := ui_text("settings_menu.engine_refresh.refresh_value", to_str_runes_pair(value_str))
					value_txt.layout.text_alignment = vec2(1, 0.5)
				}

				spacer := ui_spacer("settings_menu.engine_refresh.end_spacer")
				spacer.layout.flags = {.Fixed_Width}
				spacer.layout.size.min.x = 10
				// input_text := ui_text("settings_menu.engine_refresh", str_fmt_alloc(value_str))
			}
			{
				ui_theme_table_row(is_even = true)
				hb := ui_hbox(.Left_To_Right, "settings_menu.cam_min_zoom.hb"); { using hb
					layout.size.min = {0, 30}
					layout.flags = {.Fixed_Height}
				}
				ui_theme_text(); title := ui_text("settings_menu.cam_min_zoom.title", str_intern("Camera: Min Zoom")); { using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
				}
			}
			{
				ui_theme_table_row(is_even = false)
				hb := ui_hbox(.Left_To_Right, "settings_menu.cam_max_zoom.hb"); { using hb
					layout.size.min = {0, 30}
					layout.flags = {.Fixed_Height}
				}
				ui_theme_text(); title := ui_text("settings_menu.cam_max_zoom.title", str_intern("Camera: Max Zoom")); { using title
					layout.anchor.ratio.x = 1.0
					layout.margins.left   = 10
				}
			}
		}
		ui_vbox_end(vbox, compute_layout = false )
	}
	return
}
