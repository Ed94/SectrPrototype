package sectr

import "core:fmt"

import rl "vendor:raylib"

render :: proc()
{
	state  := get_state(); using state
	replay := & Memory_App.replay
	cam    := & project.workspace.cam
	win_extent := state.app_window.extent

	screen_top_left : Vec2 = {
		-win_extent.x  + cam.target.x,
		-win_extent.y + cam.target.y,
	}

	rl.BeginDrawing()
	rl.ClearBackground( Color_BG )
	render_mode_2d()
	//region Render Screenspace
	{
		fps_msg       := str_fmt_tmp( "FPS: %f", 1 / (frametime_elapsed_ms * MS_To_S) )
		fps_msg_width := measure_text_size( fps_msg, default_font, 16.0, 0.0 ).x
		fps_msg_pos   := screen_get_corners().top_right - { fps_msg_width, 0 }
		debug_draw_text( fps_msg, fps_msg_pos, 16.0, color = rl.GREEN )

		debug_text :: proc( format : string, args : ..any )
		{
			@static draw_text_scratch : [Kilobyte * 64]u8

			state := get_state(); using state
			if debug.draw_debug_text_y > 800 {
				debug.draw_debug_text_y = 50
			}

			cam            := & project.workspace.cam
			screen_corners := screen_get_corners()

			position   := screen_corners.top_right
			position.x -= 800
			position.y += debug.draw_debug_text_y

			content := str_fmt_buffer( draw_text_scratch[:], format, ..args )
			debug_draw_text( content, position, 14.0 )

			debug.draw_debug_text_y += 14
		}

		// Debug Text
		{
			// debug_text( "Screen Width : %v", rl.GetScreenWidth () )
			// debug_text( "Screen Height: %v", rl.GetScreenHeight() )
			debug_text( "frametime_target_ms       : %f ms", frametime_target_ms )
			debug_text( "frametime                 : %f ms", frametime_delta_ms )
			// debug_text( "frametime_last_elapsed_ms : %f ms", frametime_elapsed_ms )
			if replay.mode == ReplayMode.Record {
				debug_text( "Recording Input")
			}
			if replay.mode == ReplayMode.Playback {
				debug_text( "Replaying Input")
			}
		}

		debug_text("Zoom Target: %v", project.workspace.zoom_target)

		if debug.mouse_vis {
			debug_text( "Mouse Vertical Wheel: %v", input.mouse.vertical_wheel )
			debug_text( "Mouse Position (Screen): %v", input.mouse.pos )
			debug_text("Mouse Position (World): %v", screen_to_world(input.mouse.pos) )
			cursor_pos :=  transmute(Vec2) state.app_window.extent + input.mouse.pos
			rl.DrawCircleV( cursor_pos, 10, Color_White_A125 )
		}

		ui := project.workspace.ui

		hot_box    := zpl_hmap_get( ui.curr_cache, u64(ui.hot) )
		active_box := zpl_hmap_get( ui.curr_cache, u64(ui.active) )
		if hot_box != nil {
			debug_text("Hot    Box: %v", hot_box.label.str )
		}
		if active_box != nil{
			debug_text("Active Box: %v", active_box.label.str )
		}
		// debug_text("Active Resizing: %v", ui.active_start_signal.resizing)

		debug.draw_debug_text_y = 50
	}
	//endregion Render Screenspace
	rl.EndDrawing()
}

render_mode_2d :: proc()
{
	state  := get_state(); using state
	cam    := & project.workspace.cam

	win_extent := state.app_window.extent

	rl.BeginMode2D( project.workspace.cam )

	// draw_text( "This is text in world space", { 0, 200 }, 16.0  )

	cam_zoom_ratio := 1.0 / cam.zoom

	ImguiRender:
	{
		ui   := & state.project.workspace.ui
		root := ui.root
		if root.num_children == 0 {
			break ImguiRender
		}

		current := root.first
		for ; current != nil; {
			parent := current.parent

			style    := current.style
			computed := & current.computed

			// bg_color := 

			// TODO(Ed) : Render Borders

			render_bounds := Range2 { pts = {
				world_to_screen_pos(computed.bounds.min),
				world_to_screen_pos(computed.bounds.max),
			}}

			render_padding := range2(
				world_to_screen_pos(computed.padding.min),
				world_to_screen_pos(computed.padding.max),
			)
			render_content := range2(
				world_to_screen_pos(computed.content.min),
				world_to_screen_pos(computed.content.max),
			)

			rect_bounds := rl.Rectangle {
				render_bounds.min.x,
				render_bounds.min.y,
				render_bounds.max.x - render_bounds.min.x,
				render_bounds.max.y - render_bounds.min.y,
			}
			rect_padding := rl.Rectangle {
				render_padding.min.x,
				render_padding.min.y,
				render_padding.max.x - render_padding.min.x,
				render_padding.max.y - render_padding.min.y,
			}
			rect_content := rl.Rectangle {
				render_content.min.x,
				render_content.min.y,
				render_content.max.x - render_content.min.x,
				render_content.max.y - render_content.min.y,
			}

			rl.DrawRectangleRounded( rect_bounds, style.layout.corner_radii[0], 9, style.bg_color )

			line_thickness := 1 * cam_zoom_ratio

			rl.DrawRectangleRoundedLines( rect_padding, style.layout.corner_radii[0], 9, line_thickness, Color_Debug_UI_Padding_Bounds )
			rl.DrawRectangleRoundedLines( rect_content, style.layout.corner_radii[0], 9, line_thickness, Color_Debug_UI_Content_Bounds )
			if .Mouse_Resizable in current.flags
			{
				resize_border_width  := cast(f32) get_state().config.ui_resize_border_width
				resize_percent_width := style.size * (resize_border_width * 1.0/ 200.0)
				resize_border_non_range := add(current.computed.bounds, range2(
						{  resize_percent_width.x, -resize_percent_width.x },
						{ -resize_percent_width.x,  resize_percent_width.x }))

				render_resize := range2(
					world_to_screen_pos(resize_border_non_range.min),
					world_to_screen_pos(resize_border_non_range.max),
				)
				rect_resize := rl.Rectangle {
					render_resize.min.x,
					render_resize.min.y,
					render_resize.max.x - render_resize.min.x,
					render_resize.max.y - render_resize.min.y,
				}
				rl.DrawRectangleRoundedLines( rect_resize, style.layout.corner_radii[0], 9, line_thickness, Color_Red )
			}

			point_radius := 3 * cam_zoom_ratio
			rl.DrawCircleV( render_bounds.p0, point_radius, Color_Red )
			rl.DrawCircleV( render_bounds.p1, point_radius, Color_Blue )

			if len(current.text.str) > 0 {
				draw_text_string_cached( current.text, world_to_screen_pos(computed.text_pos), style.font_size, style.text_color )
			}

			current = ui_box_tranverse_next( current )
		}
	}
	//endregion Imgui Render


	if debug.mouse_vis {
		cursor_world_pos := screen_to_world(input.mouse.pos)
		rl.DrawCircleV( world_to_screen_pos(cursor_world_pos), 5, Color_GreyRed )
	}

	rl.DrawCircleV( { 0, 0 }, 1 * cam_zoom_ratio, Color_White )

	rl.EndMode2D()
}
