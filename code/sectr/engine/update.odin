package sectr

import "base:runtime"
import "core:math"
import "core:math/linalg"
import "core:os"
import str "core:strings"

DebugActions :: struct {
	load_project   : b32,
	save_project   : b32,
	pause_renderer : b32,

	load_auto_snapshot : b32,
	record_replay      : b32,
	play_replay        : b32,

	show_debug_text : b32,
	show_mouse_pos  : b32,

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

	show_debug_text = keyboard.right_alt.ended_down && pressed(keyboard.T)
	show_mouse_pos  = keyboard.right_alt.ended_down && pressed(keyboard.M)

	mouse_select = pressed(mouse.left)

	cam_move_up    = keyboard.W.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_left  = keyboard.A.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_down  = keyboard.S.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_right = keyboard.D.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )

	cam_mouse_pan = mouse.right.ended_down && ! pressed(mouse.right)
}

//TODO(Ed): Just use avg delta not this.
update :: proc( delta_time : f64 ) -> b32
{
	profile(#procedure)
	// TODO(Ed): Remove usage of mutable reference to state here.
	state  := get_state(); using state
	replay := & Memory_App.replay
	workspace := & project.workspace
	cam       := & workspace.cam

	window := & state.app_window
	if window.resized {
		project.workspace.cam.view = transmute(Vec2) window.extent
	}

	// state.input, state.input_prev = swap( state.input, state.input_prev )
	{
		temp := state.input_prev
		state.input_prev = state.input
		state.input      = temp
	}
	pull_staged_input_events( state.input, & state.input_events, state.staged_input_events )
	poll_input_events( state.input, state.input_prev, state.input_events )

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
	if debug_actions.show_debug_text {
		debug.debug_text_vis = !debug.debug_text_vis
	}

	//region 2D Camera Manual Nav
	// TODO(Ed): This should be per workspace view
	{
		Digial_Zoom_Snap_Levels := []f32{
			0.0258,   // 0.4px (not practical for text, but allows extreme zoom out)
			0.03125, // 0.5px
			0.0375,  // 0.6px
			0.04375, // 0.7px
			0.05,    // 0.8px
			0.05625, // 0.9px
			0.0625,  // 1px
			0.075,   // 1.2px
			0.0875,  // 1.4px
			0.1,     // 1.6px
			0.1125,  // 1.8px
			0.125,   // 2px (first practical font size)
			0.15,    //
			0.20,    //
			0.25,    // 4px
			0.375,   // 6px
			0.5,     // 8px
			0.625,   // 10px
			0.75,    // 12px
			0.875,   // 14px
			1.0,     // 16px (base size)
			1.125,   // 18px
			1.25,    // 20px
			1.375,   // 22px
			1.5,     // 24px
			1.625,   // 26px
			1.75,    // 28px
			1.875,   // 30px
			2.0,     // 32px
			2.125,   // 34px
			2.25,    // 36px
			2.375,   // 38px
			2.5,     // 40px
			2.625,   // 42px
			2.75,    // 44px
			2.875,   // 46px
			3.0,     // 48px
			3.125,   // 50px
			3.25,    // 52px
			3.375,   // 54px
			3.5,     // 56px
			3.625,   // 58px
			3.75,    // 60px
			3.875,   // 62px
			4.0,     // 64px
			4.125,   // 66px
			4.25,    // 68px
			4.375,   // 70px
			4.5,     // 72px
			4.625,   // 74px
			4.75,    // 76px
			4.875,   // 78px
			5.0,     // 80px
		}

		Min_Zoom := Digial_Zoom_Snap_Levels[ 0 ]
		Max_zoom := Digial_Zoom_Snap_Levels[ len(Digial_Zoom_Snap_Levels) - 1 ]

		// profile("Camera Manual Nav")
		digital_move_speed : f32 = 1000.0

		if workspace.zoom_target == 0.0 {
			workspace.zoom_target = cam.zoom
		}

		binary_search_closest :: proc(arr: []f32, target: f32) -> int
		{
			low, high := 0, len(arr) - 1

			for low <= high {
				mid := (low + high) / 2
				if      arr[ mid ] == target do return mid
				else if arr[ mid ]  < target do low  = mid + 1
				else                         do high = mid - 1
			}

			if low == 0        do return 0
			if low == len(arr) do return len(arr) - 1

			if abs(arr[low-1] - target) < abs(arr[low] - target) {
				return low - 1
			}
			return low
		}

		find_closest_zoom_index :: proc(zoom: f32, levels : []f32) -> int {
			return clamp(binary_search_closest(levels, zoom), 0, len(levels) - 1)
		}

		switch config.cam_zoom_mode
		{
			case .Smooth:
				zoom_delta            := input.mouse.scroll.y * config.cam_zoom_sensitivity_smooth
				workspace.zoom_target *= 1 + zoom_delta * f32(delta_time)
				workspace.zoom_target  = clamp(workspace.zoom_target, config.cam_min_zoom, config.cam_max_zoom)

				// Linearly interpolate cam.zoom towards zoom_target
				lerp_factor := config.cam_zoom_smooth_snappiness // Adjust this value to control the interpolation speed
				cam.zoom    += (workspace.zoom_target - cam.zoom) * lerp_factor * f32(delta_time)
				cam.zoom     = clamp(cam.zoom, config.cam_min_zoom, config.cam_max_zoom) // Ensure cam.zoom stays within bounds
			case .Digital:
				zoom_delta := input.mouse.scroll.y

				if zoom_delta != 0 {
						current_index := find_closest_zoom_index(cam.zoom, Digial_Zoom_Snap_Levels)
						scroll_speed := max( cast(f32) 1, abs(zoom_delta) * config.cam_zoom_scroll_delta_scale)  // Adjust this factor to control sensitivity
						target_index := current_index

						if zoom_delta > 0 {
								target_index = min(len(Digial_Zoom_Snap_Levels) - 1, current_index + int(scroll_speed))
						} else if zoom_delta < 0 {
								target_index = max(0, current_index - int(scroll_speed))
						}

						if target_index != current_index {
								proposed_target := Digial_Zoom_Snap_Levels[target_index]
								if proposed_target < config.cam_min_zoom {
									workspace.zoom_target = Digial_Zoom_Snap_Levels[find_closest_zoom_index(config.cam_min_zoom, Digial_Zoom_Snap_Levels)]
								}
								else if proposed_target > config.cam_max_zoom {
									workspace.zoom_target = Digial_Zoom_Snap_Levels[find_closest_zoom_index(config.cam_max_zoom, Digial_Zoom_Snap_Levels)]
								}
								else {
									workspace.zoom_target = proposed_target
								}
						}
				}

				// Smooth transition to target zoom
				cam.zoom = lerp(cam.zoom, workspace.zoom_target, cast(f32) config.cam_zoom_sensitivity_digital)
		}

		move_velocity : Vec2 = {
			- cast(f32) i32(debug_actions.cam_move_left) + cast(f32) i32(debug_actions.cam_move_right),
		  - cast(f32) i32(debug_actions.cam_move_up)   + cast(f32) i32(debug_actions.cam_move_down),
		}
		move_velocity *= digital_move_speed * f32(delta_time)
		cam.position  += move_velocity

		if debug_actions.cam_mouse_pan
		{
			if is_within_screenspace(input.mouse.pos) {
				pan_velocity := input.mouse.delta * ( 1 / cam.zoom )
				cam.position += pan_velocity
			}
		}
	}
	//endregion 2D Camera Manual Nav

	// TODO(Ed): We need input buffer so that we can consume input actions based on the UI with priority

	font_provider_set_px_scalar( app_config().text_size_screen_scalar )
	ui_screen_tick( & get_state().screen_ui )

	//region WorkspaceImgui Tick
	if true
	{
		font_provider_set_px_scalar( app_config().text_size_canvas_scalar )
		profile("Workspace Imgui")

		// Creates the root box node, set its as the first parent.
		ui_graph_build( & state.project.workspace.ui )
		ui := ui_context

		ui.zoom_scale = state.project.workspace.cam.zoom

		frame_style_flags : UI_LayoutFlags = {
			.Fixed_Position_X, .Fixed_Position_Y,
			.Fixed_Width, .Fixed_Height,
			.Origin_At_Anchor_Center,
		}
		default_layout := UI_Layout {
			flags          = frame_style_flags,
			anchor         = {},
			// alignment      = { 0.5, 0.5 },
			font_size      = 16,
			text_alignment = { 0.0, 0.0 },
			// corner_radii   = { 0.2, 0.2, 0.2, 0.2 },
			pos            = { 0, 0 },
			// size           = range2( { 1000, 1000 }, {}),
			// padding = { 20, 20, 20, 20 }
		}
		scope( default_layout )
		frame_style_default := UI_Style {
			// bg_color   = Color_BG_TextBox,
			bg_color   = Color_Transparent,
			font       = default_font,
			text_color = Color_White,
		}
		frame_style := to_ui_style_combo(frame_style_default)
		frame_style.disabled.bg_color = Color_Frame_Disabled
		frame_style.hot.     bg_color = Color_Frame_Hover
		frame_style.active.  bg_color = Color_Frame_Select
		scope( frame_style )

		config.ui_resize_border_width = 2.5
		// test_hover_n_click()
		// test_draggable()
		// test_text_box()
		// test_parenting( & default_layout, & frame_style_default )
		test_whitespace_ast( & default_layout, & frame_style_default )
	}
	//endregion Workspace Imgui Tick

	debug.last_mouse_pos = input.mouse.pos

	// should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	should_shutdown : b32 = false
	return should_shutdown
}
