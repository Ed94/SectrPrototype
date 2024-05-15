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
		vb_container        : UI_VBox,
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

ui_screen_menu_bar :: proc( captures : rawptr = nil ) -> (should_raise : b32 )
{
	profile("App Menu Bar")
	fmt :: str_fmt_alloc

	using state := get_state()
	using screen_ui
	{
		using state := get_state();
		using screen_ui.menu_bar
		ui_layout( UI_Layout {
			flags        = {.Fixed_Position_X, .Fixed_Position_Y, .Fixed_Width, .Fixed_Height, .Origin_At_Anchor_Center},
			// anchor       = range2({0.5, 0.5}, {0.5, 0.5} ),
			alignment    = { 0.5, 0.5 },
			border_width = 1.0,
			font_size    = 12,
			// pos = {},
			pos          = pos,
			size         = range2( size, {}),
		})
		ui_style( UI_Style {
			bg_color     = { 0, 0, 0, 30 },
			border_color = { 0, 0, 0, 200 },
			font         = default_font,
			text_color   = Color_White,
		})
		container = ui_hbox( .Left_To_Right, "Menu Bar" )

		ui_layout( UI_Layout {
			flags        = {},
			anchor       = {},
			alignment    = { 0.0, 0.0 },
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
				pos += input.mouse.delta
				should_raise = true
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
			screen_ui.settings_menu.is_open = true
		}

		spacer = ui_spacer("Menu Bar: End Spacer")
		spacer.layout.anchor.ratio.x = 1.0
	}
	return
}

ui_screen_settings_menu :: proc( captures : rawptr = nil ) -> ( should_raise : b32)
{
	profile("Settings Menu")
	using state := get_state()
	using state.screen_ui
	if ! settings_menu.is_open do return false

	using settings_menu
	if size.x < min_size.x do size.x = min_size.x
	if size.y < min_size.y do size.y = min_size.y

	resize_box_base := ui_widget("Settings Menu Wrapper", {})
	{
		using resize_box_base
		layout.flags     = { .Fixed_Width, .Fixed_Height, .Origin_At_Anchor_Center, .Fixed_Position_X, .Fixed_Position_Y }
		layout.pos       = pos
		layout.alignment = { 0.5, 0.5 }
		layout.size      = range2( size, {})
		style.bg_color   = Color_3D_BG
	}
	ui_parent(resize_box_base)
	if settings_menu.is_maximized {
		using resize_box_base
		layout.flags = {.Origin_At_Anchor_Center }
		layout.pos   = {}
	}
	ui_resizable_handles( & resize_box_base, & pos, & size)

	vb_container = ui_vbox_begin( .Top_To_Bottom, "Settings Menu", {.Mouse_Clickable}, compute_layout = true)
	{
		{
			using vb_container
			flags = {}
			style.bg_color = Color_BG_Panel_Translucent
		}
		ui_parent(vb_container)

		ui_layout( UI_Layout {
			font_size = 16,
			alignment = {0, 0},
		})
		ui_style( UI_Style {
			bg_color   = Color_Transparent,
			font       = default_font,
			text_color = Color_White,
		})
		ui_style_ref().hot.bg_color = Color_Blue
		frame_bar : UI_HBox
		frame_bar = ui_hbox_begin(.Left_To_Right, "Settings Menu: Frame Bar", { .Mouse_Clickable, .Focusable, .Click_To_Focus })
		{
			frame_bar.style.bg_color    = Color_BG_Panel
			frame_bar.layout.flags      = {.Fixed_Height}
			frame_bar.layout.size.min.y = 50
			frame_bar.layout.anchor.ratio.y = 0.25
			ui_parent(frame_bar)

			ui_layout( UI_Layout {
				font_size = 16,
				// alignment = {1, 0},
				// anchor = range2({}, {})
			})
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

			ui_hbox_end(frame_bar, compute_layout = true)
		}
		if frame_bar.active {
			pos += input.mouse.delta
			should_raise = true
		}

		ui_style( UI_Style {
			bg_color   = Color_Red,
			font       = default_font,
			text_color = Color_White,
		})

		// Populate settings with values from config (hardcoded for now)
		{
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
					bg_color = Color_GreyRed
			})
			{
				drop_down_bar := ui_hbox_begin(.Left_To_Right, "settings_menu.vbox: config drop_down_bar", {.Mouse_Clickable})
				drop_down_bar.layout.anchor.ratio.y = 1.0
				// drop_down_bar.style.bg_color = Color_Red

				ui_parent(drop_down_bar)
				btn := ui_button("pls")
				btn.text = str_intern("Config")
				btn.style.font = default_font
				btn.layout.font_size = 32
				btn.layout.size.min.y = 50
				btn.layout.text_alignment = { 0.5, 0.5 }
				btn.layout.flags = {.Fixed_Width, .Size_To_Text}
				// btn.layout.size.min = {50, 0}
				btn.style.bg_color = Color_Green
				ui_hbox_end(drop_down_bar, compute_layout = false)
			}

			// ui_layout(UI_Layout {

			// })
			// ui_style( UI_Style {

			// })
			// res_width_hbox := ui_hbox_begin(.Left_To_Right, "settings_menu.vbox: config.resolution_width: hbox", {})
			// ui_parent(res_width_hbox)
		}

		// ui_layout_ref().default.flags = {.Fixed_Width, .Fixed_Height, .Fixed_Position_Y}
		// ui_layout_ref().default.size.min = {50, 50}
		spacer := ui_spacer("Settings Menu: Spacer")
		// spacer.style.bg_color = Color_Red
		spacer.layout.anchor.ratio.y = 1.0
		// spacer.layout.flags = {.Origin_At_Anchor_Center}
		// spacer.layout.alignment = {0.5, 0.5}

		// ui_box_compute_layout(spacer)
		ui_vbox_end(vb_container, compute_layout = false )
		// ui_box_compute_layout(spacer)
	}
	return
}
