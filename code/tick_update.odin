package sectr

import "base:runtime"
import "core:math"
import "core:math/linalg"
import "core:os"

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

	//region Camera Manual Nav
	{
		// profile("Camera Manual Nav")
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
				workspace.zoom_target  = clamp(workspace.zoom_target, 0.05, 10.0)

				// Linearly interpolate cam.zoom towards zoom_target
				lerp_factor := config.cam_zoom_smooth_snappiness // Adjust this value to control the interpolation speed
				cam.zoom    += (workspace.zoom_target - cam.zoom) * lerp_factor * f32(delta_time)
				cam.zoom     = clamp(cam.zoom, 0.05, 10.0) // Ensure cam.zoom stays within bounds
			case .Digital:
				zoom_delta            := input.mouse.vertical_wheel * config.cam_zoom_sensitivity_digital
				workspace.zoom_target  = clamp(workspace.zoom_target + zoom_delta, 0.05, 10.0)
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
		profile("Imgui Tick")

		// Creates the root box node, set its as the first parent.
		ui_graph_build( & state.project.workspace.ui )
		ui := ui_context

		frame_style_flags : UI_StyleFlags = {
			.Fixed_Position_X, .Fixed_Position_Y,
			.Fixed_Width, .Fixed_Height,
		}
		default_layout := UI_Layout {
			anchor         = {},
			alignment      = { 0.0, 0.0 },
			text_alignment = { 0.0, 0.0 },
			// corner_radii   = { 0.2, 0.2, 0.2, 0.2 },
			pos            = { 0, 0 },
			size           = range2( { 1000, 1000 }, {}),
			// padding = { 20, 20, 20, 20 }
		}

		frame_style_default := UI_Style {
			flags    = frame_style_flags,
			bg_color = Color_BG_TextBox,

			font       = default_font,
			font_size  = 30,
			text_color = Color_White,

			layout = default_layout,
		}

		frame_theme := UI_StyleTheme { styles = {
			frame_style_default,
			frame_style_default,
			frame_style_default,
			frame_style_default,
		}}
		frame_theme.disabled.bg_color = Color_Frame_Disabled
		frame_theme.hot.bg_color      = Color_Frame_Hover
		frame_theme.active.bg_color   = Color_Frame_Select
		ui_style_theme( frame_theme )

		config.ui_resize_border_width = 2.5
		// test_draggable()
		// test_text_box()

		// test_parenting()
		if true
		{
			// frame := ui_widget( "Frame", {} )
			// ui_parent(frame)

			parent_layout := default_layout
			parent_layout.size      = range2( { 300, 300 }, {} )
			parent_layout.alignment = { 0.5, 0.5 }
			parent_layout.margins   = { 100, 100, 100, 100 }
			parent_layout.padding   = {}
			parent_layout.pos       = { 0, 0 }

			parent_theme := frame_style_default
			parent_theme.layout = parent_layout
			parent_theme.flags = {
				// .Fixed_Position_X, .Fixed_Position_Y,
				.Fixed_Width, .Fixed_Height,
			}
			ui_theme_via_style(parent_theme)

			parent :=	ui_widget( "Parent", { .Mouse_Clickable, .Mouse_Resizable })
			ui_parent(parent)
			{
				if parent.first_frame {
					debug.draggable_box_pos  = parent.style.layout.pos
					debug.draggable_box_size = parent.style.layout.size.min
				}

				if parent.dragging {
					debug.draggable_box_pos += mouse_world_delta()
				}

				if parent.resizing
				{
					og_layout := ui_context.active_start_style.layout

					center            := debug.draggable_box_pos
					original_distance := linalg.distance(ui.active_start_signal.cursor_pos, center)
					cursor_distance   := linalg.distance(parent.cursor_pos, center)
					scale_factor      := cursor_distance * (1 / original_distance)

					debug.draggable_box_size = og_layout.size.min * scale_factor
				}
				if (ui.hot == parent.key) && (ui.hot_resizable || ui.active_start_signal.resizing) {
					parent.style.bg_color = Color_Blue
				}

				parent.style.layout.pos      = debug.draggable_box_pos
				parent.style.layout.size.min = debug.draggable_box_size
			}

			child_layout := default_layout
			child_layout.size      = range2({ 75, 75 }, { 0, 0 })
			child_layout.alignment = { 0.5, 0.0 }
			child_layout.margins   = { 20, 20, 20, 20 }
			child_layout.padding   = {}
			child_layout.anchor    = range2({ 0.0, 0.0 }, { 0.0, 1.0 })
			child_layout.pos       = { 0, 0 }

			child_theme := frame_style_default
			child_theme.bg_color = Color_GreyRed
			child_theme.flags = {
				// .Fixed_Width, .Fixed_Height,
			}
			child_theme.layout = child_layout
			ui_theme_via_style(child_theme)
			child  := ui_widget( "Child", { .Mouse_Clickable })
		}

		// Whitespace AST test
		if false
		{
			profile("Whitespace AST test")

			text_style := frame_style_default
			text_style.flags = {
				.Size_To_Text,
				.Fixed_Position_X, .Fixed_Position_Y,
				// .Fixed_Width, .Fixed_Height,
			}

			text_theme := UI_StyleTheme { styles = {
				text_style,
				text_style,
				text_style,
				text_style,
			}}
			text_theme.default.bg_color  = Color_Transparent
			text_theme.disabled.bg_color = Color_Frame_Disabled
			text_theme.hot.bg_color      = Color_Frame_Hover
			text_theme.active.bg_color   = Color_Frame_Select

			layout_text := default_layout

			ui_style_theme( text_theme )

			alloc_error : AllocatorError; success : bool
			// debug.lorem_content, success = os.read_entire_file( debug.path_lorem, frame_allocator() )

			// debug.lorem_parse, alloc_error = pws_parser_parse( transmute(string) debug.lorem_content, frame_slab_allocator() )
			// verify( alloc_error == .None, "Faield to parse due to allocation failure" )

			text_space := str_intern( " " )
			text_tab   := str_intern( "\t")

			// index := 0
			widgets : Array(UI_Widget)
			widgets, alloc_error = array_init( UI_Widget, frame_slab_allocator() )
			widgets_ptr := & widgets

			label_id := 0

			for line in array_to_slice_num( debug.lorem_parse.lines )
			{
				profile("WS AST Line")

				head := line.first
				for ; head != nil;
				{
					ui_style_theme_set_layout( layout_text )
					widget : UI_Widget

					// We're assumping PWS_Token for now...
					// Eventually I'm going to flatten this, its not worth doing it the way I am...
					#partial switch head.type
					{
						case .Visible:
							label := str_intern( str_fmt_alloc( "%v %v", head.content.str, label_id ))
							widget = ui_text( label.str, head.content )
							label_id += 1

							layout_text.pos.x += size_range2( widget.computed.bounds ).x

						case .Spaces:
							label := str_intern( str_fmt_alloc( "%v %v", "space", label_id ))
							widget = ui_space( label.str )
							label_id += 1

							for idx in 1 ..< len( head.content.runes )
							{
								// TODO(Ed): VIRTUAL WHITESPACE
								// widget.style.layout.size.x += range2_size( widget.computed.bounds )
							}
							layout_text.pos.x += size_range2( widget.computed.bounds ).x

						case .Tabs:
							label := str_intern( str_fmt_alloc( "%v %v", "tab", label_id ))
							widget = ui_tab( label.str )
							label_id += 1

							for idx in 1 ..< len( head.content.runes )
							{
								// widget.style.layout.size.x += range2_size( widget.computed.bounds )
							}
							layout_text.pos.x += size_range2( widget.computed.bounds ).x
					}

					array_append( widgets_ptr, widget )
					head = head.next
				}

				layout_text.pos.x = default_layout.pos.x
				layout_text.pos.y -= 30
			}

			label_id += 1
		}
	}
	//endregion Imgui Tick

	debug.last_mouse_pos = input.mouse.pos

	should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}
