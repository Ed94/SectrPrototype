package sectr

UI_ScreenState :: struct
{
	using base : UI_State,
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
		container           : UI_VBox,
		is_open             : b32,
		is_maximized        : b32,
	},
}

ui_screen_tick :: proc() {
	profile("Screenspace Imgui")

	using state := get_state()
	ui_graph_build( & screen_ui )
	ui := ui_context

	ui_screen_menu_bar()
	ui_screen_settings_menu()
}

ui_screen_menu_bar :: proc()
{
	profile("App Menu Bar")
	fmt :: str_fmt_alloc

	using state := get_state()
	using screen_ui
	{
		using menu_bar
		ui_layout( UI_Layout {
			flags        = {.Fixed_Position_X, .Fixed_Position_Y, .Fixed_Width, .Fixed_Height, .Origin_At_Anchor_Center},
			// anchor       = range2({0.5, 0.5}, {0.5, 0.5} ),
			alignment    = { 0.5, 0.5 },
			border_width = 1.0,
			font_size    = 12,
			// pos = {},
			pos          = menu_bar.pos,
			size         = range2( menu_bar.size, {}),
		})
		ui_style( UI_Style {
			bg_color     = { 0, 0, 0, 30 },
			border_color = { 0, 0, 0, 200 },
			font         = default_font,
			text_color   = Color_White,
		})
		// ui_hbox( & container, .Left_To_Right, "App Menu Bar", { .Mouse_Clickable} )
		container = ui_hbox( .Left_To_Right, "Menu Bar" )
		// ui_parent(container)

		ui_layout( UI_Layout {
			flags        = {},
			anchor       = {},
			text_alignment = {0.5, 0.5},
			border_width = 1.0,
			font_size    = 12,
		})
		style_theme := to_ui_style_combo({
			bg_color   = Color_Frame_Disabled,
			font       = default_font,
			text_color = Color_White,
		})
		style_theme.hot.bg_color    = Color_Blue
		style_theme.active.bg_color = Color_Frame_Select
		ui_style(style_theme)

		move_box := ui_button("Move Box");
		{
			using move_box
			if active {
				menu_bar.pos += input.mouse.delta
			}
			layout.anchor.ratio.x = 0.2
		}

		spacer := ui_spacer("Menu Bar: Move Spacer")
		spacer.layout.flags |= {.Fixed_Width}
		spacer.layout.size.min.x = 50

		settings_btn.widget = ui_button("Settings Btn")
		settings_btn.text = str_intern("Settings")
		settings_btn.layout.flags = {
			// .Scale_Width_By_Height_Ratio,
			.Fixed_Width
		}
		settings_btn.layout.size.min.x = 100
		if settings_btn.pressed {
			settings_menu.is_open = true
		}

		spacer = ui_spacer("Menu Bar: End Spacer")
		spacer.layout.anchor.ratio.x = 1.0

		// ui_hbox_end( container)
	}
}

ui_screen_settings_menu :: proc()
{
	profile("Settings Menu")
	using state := get_state()
	using state.screen_ui
	if ! settings_menu.is_open do return

	using settings_menu
	if size.x < min_size.x do size.x = min_size.x
	if size.y < min_size.y do size.y = min_size.y

	container = ui_vbox_begin( .Top_To_Bottom, "Settings Menu", {.Mouse_Clickable})
	{
		{
			using container
			// flags = {}
			layout.flags     = { .Fixed_Width, .Fixed_Height, .Origin_At_Anchor_Center }
			layout.pos       = pos
			layout.alignment = { 0.5, 0.5 }
			// layout.alignment = {}
			layout.size      = range2( size, {})
			style.bg_color   = Color_BG_Panel_Translucent
		}
		ui_parent(container)

		ui_layout( UI_Layout {
			font_size = 16,
			alignment = {0, 1}
		})
		ui_style( UI_Style {
			bg_color   = Color_Transparent,
			font       = default_font,
			text_color = Color_White,
		})
		ui_style_ref().hot.bg_color = Color_Blue
		frame_bar := ui_hbox_begin(.Left_To_Right, "Settings Menu: Frame Bar", { .Mouse_Clickable, .Focusable, .Click_To_Focus })
		{
			frame_bar.style.bg_color    = Color_BG_Panel
			frame_bar.layout.flags      = {.Fixed_Height}
			frame_bar.layout.size.min.y = 50
			ui_parent(frame_bar)

			title := ui_text("Settings Menu: Title", str_intern("Settings Menu"), {.Disabled})
			{
				using title
				layout.margins        = { 0, 0, 15, 0}
				layout.text_alignment = {0 , 0.5}
				layout.anchor.ratio.x = 1.0
			}

			ui_style(ui_style_peek())
			style := ui_style_ref()
			style.default.bg_color = Color_Black
			style.hot.bg_color = Color_Frame_Hover
			maximize_btn := ui_button("Settings Menu: Maximize Btn")
			{
				using maximize_btn
				layout.flags          = {.Fixed_Width}
				layout.size.min       = {50, 0}
				layout.text_alignment = {0.5, 0.5}
				layout.anchor.ratio.x = 1.0
				if maximize_btn.pressed {
					settings_menu.is_maximized = ~settings_menu.is_maximized
				}
				if settings_menu.is_maximized do text = str_intern("min")
				else do text = str_intern("max")
			}

			style.default.bg_color = Color_GreyRed
			style.hot.    bg_color = Color_Red
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

			ui_hbox_end(frame_bar)
		}
		if frame_bar.active {
			pos += input.mouse.delta
		}

		spacer := ui_spacer("Settings Menu: Spacer")
		spacer.layout.anchor.ratio.y = 1.0

		ui_vbox_end(container, compute_layout = false )
	}
	if settings_menu.is_maximized {
		using settings_menu.container
		layout.flags = {.Origin_At_Anchor_Center }
		layout.pos   = {}
	}

	ui_resizable_handles( & container, & pos, & size)
}
