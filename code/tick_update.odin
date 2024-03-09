package sectr

import "base:runtime"
import "core:math"
import "core:math/linalg"

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

frametime_delta32 :: #force_inline proc "contextless" () -> f32 {
	return cast(f32) get_state().frametime_delta_seconds
}

update :: proc( delta_time : f64 ) -> b32
{
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

	//region Camera Manual Nav
	{
		digital_move_speed : f32 = 200.0

		if workspace.zoom_target == 0.0 {
			workspace.zoom_target = cam.zoom
		}

		config.cam_zoom_smooth_snappiness = 10.0
		config.cam_zoom_mode = .Smooth
		switch config.cam_zoom_mode
		{
			case .Smooth:
				zoom_delta            := input.mouse.vertical_wheel * config.cam_zoom_sensitivity_smooth
				workspace.zoom_target *= 1 + zoom_delta * f32(delta_time)
				workspace.zoom_target  = clamp(workspace.zoom_target, 0.25, 10.0)

				// Linearly interpolate cam.zoom towards zoom_target
				lerp_factor := config.cam_zoom_smooth_snappiness // Adjust this value to control the interpolation speed
				cam.zoom    += (workspace.zoom_target - cam.zoom) * lerp_factor * f32(delta_time)
				cam.zoom     = clamp(cam.zoom, 0.25, 10.0) // Ensure cam.zoom stays within bounds
			case .Digital:
				zoom_delta            := input.mouse.vertical_wheel * config.cam_zoom_sensitivity_digital
				workspace.zoom_target  = clamp(workspace.zoom_target + zoom_delta, 0.25, 10.0)
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
				pan_velocity := input.mouse.delta * ( 1 / cam.zoom )
				cam.target   -= pan_velocity
			}
		}
	}
	//endregion Camera Manual Nav

	//region Imgui Tick
	{
		// Creates the root box node, set its as the first parent.
		ui_graph_build( & state.project.workspace.ui )
		ui := ui_context

		frame_style_flags : UI_StyleFlags = {
			.Fixed_Position_X, .Fixed_Position_Y,
			.Fixed_Width, .Fixed_Height,
		}
		frame_style_default := UI_Style {
			flags    = frame_style_flags,
			bg_color = Color_BG_TextBox,
			font = default_font,
			font_size = 30,
			text_color = Color_White,
		}
		frame_style_disabled := UI_Style {
			flags    = frame_style_flags,
			bg_color = Color_Frame_Disabled,
			font = default_font,
			font_size = 30,
			text_color = Color_White,
		}
		frame_style_hovered := UI_Style {
			flags    = frame_style_flags,
			bg_color = Color_Frame_Hover,
			font = default_font,
			font_size = 30,
			text_color = Color_White,
		}
		frame_style_select := UI_Style {
			flags    = frame_style_flags,
			bg_color = Color_Frame_Select,
			font = default_font,
			font_size = 30,
			text_color = Color_White,
		}
		frame_theme := UI_StyleTheme { styles = {
			frame_style_default,
			frame_style_disabled,
			frame_style_hovered,
			frame_style_select,
		}}
		ui_style_theme( frame_theme )

		default_layout := UI_Layout {
			anchor    = {},
			// alignment = { 0.0, 0.5 },
			alignment = { 0.5, 0.5 },
			text_alignment = { 1.0, 1.0 },
			// alignment = { 1.0, 1.0 },
			corner_radii = { 0.3, 0.3, 0.3, 0.3 },
			pos       = { 0, 0 },
			size      = { 200, 200 },
		}
		ui_set_layout( default_layout )

		// test_hover_n_click()
		// test_draggable()

		config.ui_resize_border_width = 2
		// First box with text!!!!
		{
			@static pos : Vec2

			text := str_intern( "Lorem ipsum dolor sit amet")

			text_size := measure_text_size( text.str, default_font, 30, 0 )

			ui_style_theme( { styles = {
				frame_style_default,
				frame_style_default,
				frame_style_default,
				frame_style_default,
			}})

			layout        := default_layout
			layout.size    = cast(Vec2) text_size
			layout.size.y *= 4
			layout.size.x *= 1.5
			// layout.size.y *= 3.248
			// layout.size.x *= 1.348
			// layout.size.x *= 1.348
			layout.padding = ui_layout_padding( 30 )
			ui_set_layout( layout )

			text_box := ui_widget( "TEXT BOX!", UI_BoxFlags { .Mouse_Clickable, .Focusable, .Click_To_Focus } )
			if text_box.first_frame {
				pos = text_box.style.layout.pos
				text_box.text = text
			}

			if text_box.dragging {
				pos += mouse_world_delta()
			}

			text_box.style.layout.pos = pos
		}
	}
	//endregion Imgui Tick

	debug.last_mouse_pos = input.mouse.pos

	should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}
