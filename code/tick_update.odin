package sectr

import "base:runtime"
import "core:math"
import "core:fmt"

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

update :: proc( delta_time : f64 ) -> b32
{
	state  := get_state(); using state
	replay := & memory.replay

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
			project_load( fmt.tprint( project.path, project.name, ".sectr_proj", sep = "" ), & project )
		}
	}

	//region Input Replay
	{
		if debug_actions.record_replay { #partial switch replay.mode
		{
			case ReplayMode.Off : {
				save_snapshot( & memory.snapshot[0] )
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
					save_snapshot( & memory.snapshot[0] )
					replay_recording_begin( Path_Input_Replay )
				}
				else {
					load_snapshot( & memory.snapshot[0] )
					replay_playback_begin( Path_Input_Replay )
				}
			}
			case ReplayMode.Playback : {
				replay_playback_end()
				load_snapshot( & memory.snapshot[0] )
			}
			case ReplayMode.Record : {
				replay_recording_end()
				load_snapshot( & memory.snapshot[0] )
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

	//region Camera Manual Nav
	{
		cam := & project.workspace.cam

		digital_move_speed : f32 = 200.0
		// zoom_sensitivity   : f32 = 0.2 // Digital
		zoom_sensitivity   : f32 = 4.0  // Smooth

		if debug.zoom_target == 0.0 {
			debug.zoom_target = cam.zoom
		}

		// Adjust zoom_target based on input, not the actual zoom
		zoom_delta        := input.mouse.vertical_wheel * zoom_sensitivity
		debug.zoom_target *= 1 + zoom_delta * f32(delta_time)
		debug.zoom_target  = clamp(debug.zoom_target, 0.25, 10.0)

		// Linearly interpolate cam.zoom towards zoom_target
		lerp_factor := cast(f32) 4.0 // Adjust this value to control the interpolation speed
		cam.zoom    += (debug.zoom_target - cam.zoom) * lerp_factor * f32(delta_time)
		cam.zoom     = clamp(cam.zoom, 0.25, 10.0) // Ensure cam.zoom stays within bounds

		move_velocity : Vec2 = {
			- cast(f32) i32(debug_actions.cam_move_left) + cast(f32) i32(debug_actions.cam_move_right),
		  - cast(f32) i32(debug_actions.cam_move_up)   + cast(f32) i32(debug_actions.cam_move_down),
		}
		move_velocity *= digital_move_speed * f32(delta_time)
		cam.target    += move_velocity

		if debug_actions.cam_mouse_pan
		{
			if is_within_screenspace(input.mouse.pos) {
				pan_velocity := input.mouse.delta * (1/cam.zoom)
				cam.target   -= pan_velocity
			}
		}
	}
	//endregion

	//region Imgui Tick
	{
		ui_context := & state.project.workspace.ui

		// Build Graph (Determines if layout is dirty)
		ui_graph_build_begin( ui_context )

		

		// Regnerate compute if layout is dirty.
	}
	// endregion

	debug.last_mouse_pos = input.mouse.pos

	should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}
