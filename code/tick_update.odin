package sectr

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

	cam_move_up    : b32,
	cam_move_left  : b32,
	cam_move_down  : b32,
	cam_move_right : b32,
}

poll_debug_actions :: proc( actions : ^ DebugActions, input : ^ InputState )
{
	using actions
	using input

	load_project = keyboard.left_control.ended_down && pressed( keyboard.O )
	save_project = keyboard.left_control.ended_down && pressed( keyboard.S )

	base_replay_bind := keyboard.right_alt.ended_down && pressed( keyboard.L)
	record_replay     = base_replay_bind &&   keyboard.right_shift.ended_down
	play_replay       = base_replay_bind && ! keyboard.right_shift.ended_down

	show_mouse_pos = keyboard.right_alt.ended_down && pressed(keyboard.M)

	cam_move_up    = keyboard.W.ended_down
	cam_move_left  = keyboard.A.ended_down
	cam_move_down  = keyboard.S.ended_down
	cam_move_right = keyboard.D.ended_down
}

update :: proc( delta_time : f64 ) -> b32
{
	state  := get_state(); using state
	replay := & memory.replay

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

	// Input Replay
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

	if debug_actions.show_mouse_pos {
		debug.mouse_vis = !debug.mouse_vis
	}

	debug.mouse_pos = { input.mouse.X, input.mouse.Y }

	// Camera Manual Nav
	{
		move_speed        : f32 = 200.0
		zoom_sensitiviity : f32 = 3.5

		cam := & project.workspace.cam
		cam.zoom *= 1 + input.mouse.vertical_wheel * zoom_sensitiviity * f32(delta_time)
		cam.zoom  = clamp( cam.zoom, 0.05, 10.0 )

		move_velocity : Vec2 = {
			- cast(f32) i32(debug_actions.cam_move_left) + cast(f32) i32(debug_actions.cam_move_right),
		  - cast(f32) i32(debug_actions.cam_move_up)   + cast(f32) i32(debug_actions.cam_move_down),
		}
		move_velocity *= move_speed * f32(delta_time)
		cam.target    += move_velocity
	}

	should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}
