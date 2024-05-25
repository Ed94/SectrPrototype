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

	base_replay_bind := keyboard.right_alt.ended_down && pressed( keyboard.L)
	record_replay     = base_replay_bind &&   keyboard.right_shift.ended_down
	play_replay       = base_replay_bind && ! keyboard.right_shift.ended_down

	show_debug_text = keyboard.right_alt.ended_down && pressed(keyboard.T)
	show_mouse_pos  = keyboard.right_alt.ended_down && pressed(keyboard.M)

	mouse_select = pressed(mouse.left)

	cam_move_up    = keyboard.W.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_left  = keyboard.A.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_down  = keyboard.S.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )
	cam_move_right = keyboard.D.ended_down && ( ! modifier_active || keyboard.left_shift.ended_down )

	cam_mouse_pan = mouse.right.ended_down && ! pressed(mouse.right)
}

frametime_delta32 :: #force_inline proc "contextless" () -> f32 {
	return cast(f32) get_state().frametime_avg_ms
}

//TODO(Ed): Just use avg delta not this.
update :: proc( delta_time : f64 ) -> b32
{
	profile(#procedure)
	state  := get_state(); using state
	replay := & Memory_App.replay
	workspace := & project.workspace
	cam       := & workspace.cam

	window := & state.app_window
	if window.resized {
		project.workspace.cam.view = transmute(Vec2) window.extent
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
	if debug_actions.show_debug_text {
		debug.debug_text_vis = !debug.debug_text_vis
	}

	//region 2D Camera Manual Nav
	// TODO(Ed): This should be per workspace view
	{
		// profile("Camera Manual Nav")
		digital_move_speed : f32 = 1000.0

		if workspace.zoom_target == 0.0 {
			workspace.zoom_target = cam.zoom
		}

		config.cam_max_zoom = 30
		config.cam_zoom_sensitivity_digital = 0.04
		config.cam_min_zoom = 0.04
		config.cam_zoom_mode = .Digital
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
		cam.position  += move_velocity

		if debug_actions.cam_mouse_pan
		{
			if is_within_screenspace(input.mouse.pos) {
				pan_velocity := input.mouse.delta * vec2(1, -1) * ( 1 / cam.zoom )
				cam.position -= pan_velocity
			}
		}
	}
	//endregion 2D Camera Manual Nav

	// TODO(Ed): We need input buffer so that we can consume input actions based on the UI with priority

	ui_screen_tick()

	//region WorkspaceImgui Tick
	{
		profile("Workspace Imgui")

		// Creates the root box node, set its as the first parent.
		ui_graph_build( & state.project.workspace.ui )
		ui := ui_context

		frame_style_flags : UI_LayoutFlags = {
			.Fixed_Position_X, .Fixed_Position_Y,
			.Fixed_Width, .Fixed_Height,
			.Origin_At_Anchor_Center,
		}
		default_layout := UI_Layout {
			flags          = frame_style_flags,
			anchor         = {},
			// alignment      = { 0.5, 0.5 },
			font_size      = 30,
			text_alignment = { 0.0, 0.0 },
			// corner_radii   = { 0.2, 0.2, 0.2, 0.2 },
			pos            = { 0, 0 },
			// size           = range2( { 1000, 1000 }, {}),
			// padding = { 20, 20, 20, 20 }
		}
		scope( default_layout )
		frame_style_default := UI_Style {
			bg_color   = Color_BG_TextBox,
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
		// test_whitespace_ast( & default_layout, & frame_style_default )
	}
	//endregion Workspace Imgui Tick

	debug.last_mouse_pos = input.mouse.pos

	// should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	should_shutdown : b32 = false
	return should_shutdown
}
