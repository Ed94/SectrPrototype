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
		if true && ! loaded
		{
			layout := UI_Layout {
				flags          = {},
				anchor         = range2({},{}),
				alignment      = {0.5, 0.5},
				text_alignment = {0.0, 1.5},
				font_size      = 12,
				margins        = {0, 0, 0, 0},
				padding        = {0, 0, 0, 0},
				border_width   = 0.6,
				pos            = {0, 0},
				size           = range2({},{})
			}
			style := UI_Style {
				bg_color     = Color_ThmDark_BG,
				border_color = Color_ThmDark_Border_Default,
				corner_radii = {},
				blur_size    = 0,
				font         = get_state().default_font,
				text_color   = Color_ThmDark_Text_Default,
				cursor       = {},
			}

			// loaded = true
			layout_combo := to_ui_layout_combo(layout)
			style_combo  := to_ui_style_combo(style)
			{
				using layout_combo.hot
				using style_combo.hot
				bg_color   = Color_ThmDark_Btn_BG_Hot
				text_color = Color_ThmDark_Text_Hot
			}
			{
				using layout_combo.active
				using style_combo.active
				bg_color   = Color_ThmDark_Btn_BG_Active
				text_color = Color_ThmDark_Text_Active
			}

			theme = UI_Theme {
				layout_combo, style_combo
			}
		}
		ui_layout_push(theme.layout)
		ui_style_push(theme.style)
	}

	using state := get_state()
	using screen_ui
	{
		using screen_ui.menu_bar
		ui_theme_app_menu_bar_default()
		container = ui_hbox( .Left_To_Right, "Menu Bar" )
		{
			using container
			layout.flags = {.Fixed_Position_X, .Fixed_Position_Y, .Fixed_Width, .Fixed_Height, .Origin_At_Anchor_Center}
			layout.pos            = pos
			layout.size           = range2( size, {})
			text = str_intern("menu_bar")
		}

		ui_theme_btn_default()
		move_box := ui_button("Move Box");
		{
			using move_box
			if active {
				pos += input.mouse.delta
				should_raise = true
			}
			layout.anchor.ratio.x = 0.4
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
				// .Scale_Width_By_Height_Ratio,
				.Fixed_Width
			}
			layout.size.min.x = 100
			if pressed {
				screen_ui.settings_menu.is_open = true
			}
		}

		spacer = ui_spacer("Menu Bar: End Spacer")
		spacer.layout.anchor.ratio.x = 1.0
	}
	return
}

ui_screen_settings_menu :: proc( captures : rawptr = nil ) -> ( should_raise : b32 = false)
{
	profile("Settings Menu")
	using state := get_state()
	using state.screen_ui
	if ! settings_menu.is_open do return

	using settings_menu
	if size.x < min_size.x do size.x = min_size.x
	if size.y < min_size.y do size.y = min_size.y

	ui_theme_transparent()
	container = ui_widget("Settings Menu", {})
	{
		using container
		layout.flags        = { .Fixed_Width, .Fixed_Height, .Fixed_Position_X, .Fixed_Position_Y, .Origin_At_Anchor_Center }
		style.bg_color      = Color_ThmDark_Translucent_Panel
		style.border_color  = { 0, 0, 0, 200 }
		layout.alignment    = {0.0, 0.0}
		layout.border_width = 1.0
		layout.pos          = pos
		layout.size         = range2( size, {})
	}
	ui_parent(container)
	if settings_menu.is_maximized {
		using container
		layout.flags = {.Origin_At_Anchor_Center }
		layout.pos   = {}
	}
	should_raise |= ui_resizable_handles( & container, & pos, & size/*, compute_layout = true*/)
	// ui_box_compute_layout(container)

	vbox := ui_vbox_begin( .Top_To_Bottom, "Settings Menu: VBox", {.Mouse_Clickable}, compute_layout = true)
	{
		should_raise |= b32(vbox.active)
		ui_parent(vbox)

		ui_layout( UI_Layout {
		// 	font_size = 16,
			// alignment = {0, 1},
		})
		ui_style( UI_Style {
			// bg_color   = Color_Transparent,
			font       = default_font,
			text_color = Color_White,
		})
		ui_style_ref().hot.bg_color = Color_Blue
		frame_bar := ui_hbox_begin(.Left_To_Right, "Settings Menu: Frame Bar", { .Mouse_Clickable, .Focusable, .Click_To_Focus })
		{
			frame_bar.layout.flags      = {.Fixed_Height}
			frame_bar.layout.size.min.y = 50
			ui_parent(frame_bar)

			ui_layout( UI_Layout {
				font_size = 18,
			})
			title := ui_text("Settings Menu: Title", str_intern("Settings Menu"), {.Disabled})
			{
				using title
				layout.margins        = { 0, 0, 15, 0}
				layout.text_alignment = {0 , 0.5}
				layout.anchor.ratio.x = 1.0
			}

			ui_layout( UI_Layout {
				font_size = 16,
			})

			ui_style(ui_style_peek())
			style := ui_style_ref()
			maximize_btn := ui_button("Settings Menu: Maximize Btn")
			{
				using maximize_btn
				layout.flags          = {.Fixed_Width}
				layout.size.min       = {50, 50}
				layout.text_alignment = {0.5, 0.5}
				layout.anchor.ratio.x = 1.0
				if maximize_btn.pressed {
					settings_menu.is_maximized = ~settings_menu.is_maximized
					should_raise = true
				}
				if settings_menu.is_maximized do text = str_intern("min")
				else do text = str_intern("max")
			}
			close_btn := ui_button("Settings Menu: Close Btn")
			{
				using close_btn
				text = str_intern("close")
				layout.flags          = {.Fixed_Width}
				layout.size.min       = {50, 0}
				layout.text_alignment = {0.5, 0.5}
				layout.anchor.ratio.x = 1.0
				if close_btn.pressed {
					settings_menu.is_open = false
				}
			}

			ui_hbox_end(frame_bar, compute_layout = true)
		}
		if frame_bar.active {
			pos += input.mouse.delta
			should_raise = true
		}

		// Populate settings with values from config (hardcoded for now)
		ui_layout(UI_Layout {
			flags = {
				// .Origin_At_Anchor_Center,
				// .Fixed_Height,
			},
			// pos = {0, 50},
			// size = range2({100, 100},{}),
			// alignment = {0,0},
		})
		ui_style( UI_Style {
				// bg_color = Color_GreyRed
		})
		drop_down_bar := ui_hbox_begin(.Left_To_Right, "settings_menu.vbox: config drop_down_bar", {.Mouse_Clickable})
		btn : UI_Widget
		{
			drop_down_bar.layout.anchor.ratio.y = 0.1
			{
				using drop_down_bar
				text = str_intern("drop_down_bar")
				// style.bg_color        = { 55, 55, 55, 100 }
				style.font            = default_font
				style.text_color      = Color_White
				layout.flags          = {.Fixed_Height}
				layout.font_size      = 12
				layout.text_alignment = {1, 0}
				layout.size.min.y     = 35
			}
			ui_parent(drop_down_bar)

			btn = ui_text("pls", str_intern("Lets figure this out..."))
			{
				using btn
				text = str_intern("Config")
				style.font            = default_font
				style.text_color      = Color_White
				// layout.flags          = {.Origin_At_Anchor_Center}
				layout.alignment      = {0.0, 0.0}
				layout.anchor.ratio.x = 1.0
				layout.font_size      = 12
				layout.margins        = {0,0, 15, 0}
				layout.size.min.y     = 35
			}
			um := ui_spacer("um...")
			um.layout.anchor.ratio.x = 1.0
			ui_hbox_end(drop_down_bar, compute_layout = true)
		}

		// ui_layout(UI_Layout {

		// })
		// ui_style( UI_Style {

		// })
		// res_width_hbox := ui_hbox_begin(.Left_To_Right, "settings_menu.vbox: config.resolution_width: hbox", {})
		// ui_parent(res_width_hbox)

		spacer := ui_spacer("Settings Menu: Spacer")
		spacer.layout.anchor.ratio.y = 1.0

		ui_vbox_end(vbox, compute_layout = false )
	}
	return
}
