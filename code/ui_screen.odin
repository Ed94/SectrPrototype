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
			is_open      : b32,
		}
	},
	settings_menu : struct
	{
		pos, size, min_size : Vec2,
		container           : UI_VBox,
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
		ui_theme_via_style({
			flags        = {},
			bg_color     = { 0, 0, 0, 30 },
			border_color = { 0, 0, 0, 200 },
			font         = default_font,
			text_color   = Color_White,
			layout = {
				anchor       = {},
				alignment    = { 0, 1 },
				border_width = 1.0,
				font_size    = 12,
				pos          = menu_bar.pos,
				size         = range2( menu_bar.size, {}),
			},
		})
		container = ui_hbox( .Left_To_Right, "App Menu Bar", { .Mouse_Clickable} )

		theme := to_ui_styletheme({
			bg_color   = Color_Frame_Disabled,
			font       = default_font,
			text_color = Color_White,
			layout = {
				anchor         = range2( {0, 0}, {0, 0} ),
				alignment      = { 0.0, 0.0 },
				font_size      = 18,
				text_alignment = { 0.5, 0.5 },
				size           = range2({25, 0}, {0, 0})
			}
		})
		theme.hot.bg_color    = Color_Blue
		theme.active.bg_color = Color_Frame_Select
		ui_style_theme(theme)

		move_box := ui_button("Move Box");
		{
			using move_box
			if active {
				menu_bar.pos += input.mouse.delta
			}
			style.anchor.ratio.x = 0.2
		}

		spacer := ui_spacer("Menu Bar: Move Spacer")
		spacer.style.flags |= {.Fixed_Width}
		spacer.style.size.min.x = 50
		// spacer.style.bg_color = Color_Red

		settings_btn.widget = ui_button("Settings Btn")
		settings_btn.text = str_intern("Settings")
		settings_btn.style.flags = {
			// .Scale_Width_By_Height_Ratio,
			.Fixed_Width
		}
		settings_btn.style.size.min.x = 100
		if settings_btn.pressed {
			settings_btn.is_open = true
		}

		spacer = ui_spacer("Menu Bar: End Spacer")
		spacer.style.anchor.ratio.x = 1.0
		// spacer.style.bg_color = Color_Red
	}
}

ui_screen_settings_menu :: proc()
{
	profile("Settings Menu")
	using state := get_state()
	using state.screen_ui
	if menu_bar.settings_btn.pressed || ! menu_bar.settings_btn.is_open do return

	using settings_menu
	if size.x < min_size.x do size.x = min_size.x
	if size.y < min_size.y do size.y = min_size.y

	container = ui_vbox_begin( .Top_To_Bottom, "Settings Menu", {.Mouse_Clickable})
	{
		using container
		style.flags = {
			// .Origin_At_Anchor_Center
		}
		style.pos       = pos
		style.alignment = { 0.5, 0.5 }
		style.bg_color  = Color_BG_Panel_Translucent
		style.size      = range2( size, {})
	}
	ui_parent(container)
	{
		ui_theme_via_style({
			bg_color   = Color_Transparent,
			font       = default_font,
			text_color = Color_White,
			layout     = { font_size = 16 },
		})
		ui_style_theme_ref().hot.bg_color = Color_Blue
		frame_bar := ui_hbox_begin(.Left_To_Right, "Settings Menu: Frame Bar", { .Mouse_Clickable, .Focusable, .Click_To_Focus })
		{
			frame_bar.style.bg_color   = Color_BG_Panel
			frame_bar.style.flags      = {.Fixed_Height}
			frame_bar.style.alignment  = { 0, 0 }
			frame_bar.style.size.min.y = 50
			if frame_bar.active {
				pos += input.mouse.delta
			}
			ui_parent(frame_bar)

			title := ui_text("Settings Menu: Title", str_intern("Settings Menu"), {.Disabled})
			{
				using title
				style.margins        = { 0, 0, 15, 0}
				style.text_alignment = {0 , 0.5}
				style.anchor.ratio.x = 1.0
			}

			ui_style_theme(ui_style_theme_peek())
			theme := ui_style_theme_ref()
			theme.default.bg_color = Color_GreyRed
			theme.hot.    bg_color = Color_Red
			close_btn := ui_button("Settings Menu: Close Btn")
			{
				using close_btn
				text = str_intern("close")
				style.flags          = {.Fixed_Width}
				style.size.min       = {50, 0}
				style.text_alignment = {0.5, 0.5}
				style.anchor.ratio.x = 1.0
				if close_btn.pressed {
					menu_bar.settings_btn.is_open = false
				}
			}

			ui_hbox_end(frame_bar)//, & size.x)
		}

		spacer := ui_spacer("Settings Menu: Spacer")
		spacer.style.anchor.ratio.y = 1.0

		ui_vbox_end(container)//, & size.y)
	}

	ui_resizable_handles( & container, & pos, & size )
}
