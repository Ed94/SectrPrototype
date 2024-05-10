package sectr

import "base:runtime"
import "core:math"
import "core:math/linalg"
import "core:os"
import str "core:strings"

import rl "vendor:raylib"

DebugActions :: struct {
	load_project   : b32,
	save_project   : b32,
	pause_renderer : b32,

	load_auto_snapshot : b32,
	record_replay      : b32,
	play_replay        : b32,

	show_mouse_pos : b32,

	mouse_select : b32,

	cam_move_up    : b32,
	cam_move_left  : b32,
	cam_move_down  : b32,
	cam_move_right : b32,
	cam_mouse_pan  : b32,
}

poll_debug_actions :: proc( actions : ^ DebugActions, input : ^ InputState )
{
	// profile(#procedure)
	using actions
	using input

	modifier_active := keyboard.right_alt.ended_down ||
		keyboard.right_control.ended_down ||
		keyboard.right_shift.ended_down ||
		keyboard.left_alt.ended_down ||
		keyboard.left_control.ended_down ||
		keyboard.left_shift.ended_down

	load_project = keyboard.left_control.ended_down && pressed( keyboard.O )
	save_project = keyboard.left_control.ended_down && pressed( keyboard.S )

	base_replay_bind := keyboard.right_alt.ended_down && pressed( keyboard.L)
	record_replay     = base_replay_bind &&   keyboard.right_shift.ended_down
	play_replay       = base_replay_bind && ! keyboard.right_shift.ended_down

	show_mouse_pos = keyboard.right_alt.ended_down && pressed(keyboard.M)

	mouse_select = pressed(mouse.left)

	cam_move_up    = keyboard.W.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_left  = keyboard.A.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_down  = keyboard.S.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_right = keyboard.D.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )

	cam_mouse_pan = mouse.right.ended_down && ! pressed(mouse.right)
}

frametime_delta32 :: #force_inline proc "contextless" () -> f32 {
	return cast(f32) get_state().frametime_delta_seconds
}

update :: proc( delta_time : f64 ) -> b32
{
	profile(#procedure)
	state  := get_state(); using state
	replay := & Memory_App.replay
	workspace := & project.workspace
	cam       := & workspace.cam

	if rl.IsWindowResized() {
		window := & state.app_window
		window.extent.x = f32(rl.GetScreenWidth())  * 0.5
		window.extent.y = f32(rl.GetScreenHeight()) * 0.5

		project.workspace.cam.offset = transmute(Vec2) window.extent
	}

	state.input, state.input_prev = swap( state.input, state.input_prev )
	poll_input( state.input_prev, state.input )

	debug_actions : DebugActions = {}
	poll_debug_actions( & debug_actions, state.input )

	// Saving & Loading
	{
		if debug_actions.save_project {
			project_save( & project )
		}
		if debug_actions.load_project {
			project_load( str_tmp_from_any( project.path, project.name, ".sectr_proj", sep = "" ), & project )
		}
	}

	//region Input Replay
	// TODO(Ed) : Implment host memory mapping api
	when false
	{
		if debug_actions.record_replay { #partial switch replay.mode
		{
			case ReplayMode.Off : {
				save_snapshot( & Memory_App.snapshot )
				replay_recording_begin( Path_Input_Replay )
			}
			case ReplayMode.Record : {
				replay_recording_end()
			}
		}}

		if debug_actions.play_replay { switch replay.mode
		{
			case ReplayMode.Off : {
				if ! file_exists( Path_Input_Replay ) {
					save_snapshot( & Memory_App.snapshot )
					replay_recording_begin( Path_Input_Replay )
				}
				else {
					load_snapshot( & Memory_App.snapshot )
					replay_playback_begin( Path_Input_Replay )
				}
			}
			case ReplayMode.Playback : {
				replay_playback_end()
				load_snapshot( & Memory_App.snapshot )
			}
			case ReplayMode.Record : {
				replay_recording_end()
				load_snapshot( & Memory_App.snapshot )
				replay_playback_begin( Path_Input_Replay )
			}
		}}

		if replay.mode == ReplayMode.Record {
			record_input( replay.active_file, input )
		}
		else if replay.mode == ReplayMode.Playback {
			play_input( replay.active_file, input )
		}
	}
	//endregion Input Replay

	if debug_actions.show_mouse_pos {
		debug.mouse_vis = !debug.mouse_vis
	}

	//region 2D Camera Manual Nav
	// TODO(Ed): This should be per workspace view
	{
		// profile("Camera Manual Nav")
		digital_move_speed : f32 = 200.0

		if workspace.zoom_target == 0.0 {
			workspace.zoom_target = cam.zoom
		}

		switch config.cam_zoom_mode
		{
			case .Smooth:
				zoom_delta            := input.mouse.vertical_wheel * config.cam_zoom_sensitivity_smooth
				workspace.zoom_target *= 1 + zoom_delta * f32(delta_time)
				workspace.zoom_target  = clamp(workspace.zoom_target, config.cam_min_zoom, config.cam_max_zoom)

				// Linearly interpolate cam.zoom towards zoom_target
				lerp_factor := config.cam_zoom_smooth_snappiness // Adjust this value to control the interpolation speed
				cam.zoom    += (workspace.zoom_target - cam.zoom) * lerp_factor * f32(delta_time)
				cam.zoom     = clamp(cam.zoom, config.cam_min_zoom, config.cam_max_zoom) // Ensure cam.zoom stays within bounds
			case .Digital:
				zoom_delta            := input.mouse.vertical_wheel * config.cam_zoom_sensitivity_digital
				workspace.zoom_target  = clamp(workspace.zoom_target + zoom_delta, config.cam_min_zoom, config.cam_max_zoom)
				cam.zoom = workspace.zoom_target
		}

		move_velocity : Vec2 = {
			- cast(f32) i32(debug_actions.cam_move_left) + cast(f32) i32(debug_actions.cam_move_right),
		  - cast(f32) i32(debug_actions.cam_move_up)   + cast(f32) i32(debug_actions.cam_move_down),
		}
		move_velocity *= digital_move_speed * f32(delta_time)
		cam.target    += move_velocity

		if debug_actions.cam_mouse_pan
		{
			if is_within_screenspace(input.mouse.pos) {
				pan_velocity := input.mouse.delta * vec2(1, -1) * ( 1 / cam.zoom )
				cam.target   -= pan_velocity
			}
		}
	}
	//endregion 2D Camera Manual Nav

	// TODO(Ed): We need input buffer so that we can consume input actions based on the UI with priority

	//region App UI Tick
	{
		profile("App Screenspace Imgui")

		ui_graph_build( & state.app_ui )
		ui := ui_context

		/*
			Prototype app menu
			This is a menu bar for the app for now inside the same ui as the workspace's UI state
			Eventually this will get moved out to its own UI state for the app itself.
		*/
		if true
		{
			fmt :: str_fmt_alloc

			@static bar_pos := Vec2{0, 100}
			bar_size := vec2( 400, 40 )

			menu_bar : UI_Widget
			{
				theme := UI_Style {
					flags = {
					},
					bg_color     = { 0, 0, 0, 30 },
					border_color = { 0, 0, 0, 200 },

					font = default_font,
					text_color = Color_White,

					layout = UI_Layout {
						anchor = {},
						border_width = 1.0,
						font_size = 12,
						pos    = bar_pos,
						size   = range2( bar_size, {}),
						// padding = { 10, 10, 10, 10 },
					},
				}

				ui_theme_via_style(theme)
				menu_bar = ui_widget("App Menu Bar", {} )
				menu_bar.text = to_str_runes_pair( fmt("%v", bar_pos))

				if (menu_bar.first_frame) {
					// bar_pos = screen_get_corners().top_right - vec2(0, app_window.extent.y * 0.5)
				}
			}
			// Setup Children
			settings_btn : UI_Widget
			{
				ui_parent(menu_bar)

				style := UI_Style {
					flags = {
						// .Origin_At_Anchor_Center
						.Fixed_Height
					},
					bg_color = Color_Frame_Disabled,

					font       = default_font,
					text_color = Color_White,

					layout = UI_Layout {
						anchor         = range2( {0, 0}, {0.0, 0} ),
						alignment      = { 0.0, 1.0 },
						font_size      = 18,
						text_alignment = { 0.5, 0.5 },
						pos            = { 0, 0 },
						size           = range2( {25, bar_size.y}, {0, 0})
					}
				}
				theme := to_ui_styletheme(style)
				theme.disabled.bg_color = Color_Frame_Disabled
				theme.hot.bg_color      = Color_Red
				theme.active.bg_color   = Color_Frame_Select
				ui_style_theme(theme)

				move_box : UI_Widget
				{
					move_box = ui_button("Move Box")
					if move_box.active {
						bar_pos += input.mouse.delta
					}
				}

				move_settings_spacer := ui_widget("Move-Settings Spacer", {})
				{
					using move_settings_spacer
					text                   = str_intern("spacer")
					style.bg_color         = Color_Transparent
					style.layout.font_size = 10
				}

				settings_btn      = ui_button("Settings Btn")
				settings_btn.text = str_intern("Settings")
				settings_btn.style.flags = {
					.Scale_Width_By_Height_Ratio,
				}

				// HBox layout calculation?
				{
					hb_space_ratio_move_box := 0.1
					hb_space_ratio_move_settings_spacer := 0.05
					hb_space_ratio_settings_btn := 1.0

					style := & move_box.box.style
					style.anchor.max.x = 0.9

					style = & move_settings_spacer.box.style
					style.anchor.min.x = 0.1
					style.anchor.max.x = 0.8

					style = & settings_btn.box.style
					style.anchor.min.x = 0.2
					style.anchor.max.x = 0.55
				}
			}

			@static settings_open := true
			if settings_btn.pressed || settings_open
			{
				settings_open = true

				resize_border_width : f32 = 20
				@static pos  := Vec2 {0, 0}
				@static size := Vec2 { 200, 200 }
				if size.x < 200 {
					size.x = 200
				}
				if size.y < 200 {
					size.y = 200
				}
				settings_menu := ui_widget("Settings Menu", {.Mouse_Clickable})
				{
					using settings_menu
					style.flags = {
						// .Origin_At_Anchor_Center
					}
					style.pos       = pos
					style.alignment = { 1.0, 0.5 }
					style.bg_color  = Color_BG_Panel_Translucent
					style.size      = range2( size, {})
				}

				ui_parent(settings_menu)
				ui_theme_via_style({
					bg_color   = Color_Transparent,
					font       = default_font,
					text_color = Color_White,
					size       = range2({0, 40}, {0, 40}), // TODO(Ed): Implment ratio scaling for height
					layout     = { font_size = 16 },
				})
				ui_style_theme_ref().hot.bg_color = Color_Blue
				frame_bar := ui_widget("Settings Menu: Frame Bar", { .Mouse_Clickable, .Focusable, .Click_To_Focus })
				{
					using frame_bar
					style.bg_color  = Color_BG_Panel
					style.flags     = {}
					style.alignment = { 0, 1 }
				}
				ui_parent(frame_bar)

				if frame_bar.active {
					pos += input.mouse.delta
				}

				title := ui_text("Settings Menu: Title", str_intern("Settings Menu"), {.Disabled})
				{
					using title
					style.alignment      = {0, 1}
					style.margins        = { 0, 0, 15, 0}
					style.text_alignment = {0 , 0.5}
				}

				ui_style_theme(ui_style_theme_peek())
				ui_style_theme_ref().default.bg_color = Color_GreyRed
				ui_style_theme_ref().hot.    bg_color = Color_Red
				close_btn := ui_button("Settings Menu: Close Btn")
				{
					using close_btn
					text = str_intern("close")
					// style.bg_color = Color_GreyRed
					style.size.min       = {50, 0}
					style.anchor         = range2( {1.0, 0}, {})
					style.alignment      = {1, 1}
					style.text_alignment = {0.5, 0.5}
					if close_btn.pressed {
						settings_open = false
					}
				}

				ui_resizable_handles( & settings_menu, & pos, & size )
			}
		}
	}
	//endregion App UI Tick

	//region WorkspaceImgui Tick
	{
		profile("Workspace Imgui")

		// Creates the root box node, set its as the first parent.
		ui_graph_build( & state.project.workspace.ui )
		ui := ui_context

		frame_style_flags : UI_StyleFlags = {
			.Fixed_Position_X, .Fixed_Position_Y,
			.Fixed_Width, .Fixed_Height,
		}
		default_layout := UI_Layout {
			anchor         = {},
			alignment      = { 0., 0.0 },
			font_size      = 30,
			text_alignment = { 0.0, 0.0 },
			// corner_radii   = { 0.2, 0.2, 0.2, 0.2 },
			pos            = { 0, 0 },
			size           = range2( { 1000, 1000 }, {}),
			// padding = { 20, 20, 20, 20 }
		}

		frame_style_default := UI_Style {
			flags      = frame_style_flags,
			bg_color   = Color_BG_TextBox,
			font       = default_font,
			text_color = Color_White,

			layout = default_layout,
		}

		frame_theme := to_ui_styletheme(frame_style_default)
		frame_theme.disabled.bg_color = Color_Frame_Disabled
		frame_theme.hot.     bg_color = Color_Frame_Hover
		frame_theme.active.  bg_color = Color_Frame_Select
		ui_style_theme( frame_theme )

		config.ui_resize_border_width = 2.5
		// test_draggable()
		// test_text_box()
		// test_parenting( & default_layout, & frame_style_default )
		// test_whitespace_ast( & default_layout, & frame_style_default )
	}
	//endregion Workspace Imgui Tick

	debug.last_mouse_pos = input.mouse.pos

	should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}
