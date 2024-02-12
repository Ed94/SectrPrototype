package sectr

import "core:fmt"

import rl "vendor:raylib"

render :: proc()
{
	state  := get_state(); using state
	replay := & memory.replay
	cam    := & project.workspace.cam
	win_extent := state.app_window.extent

	screen_top_left : Vec2 = {
		-win_extent.x  + cam.target.x,
		-win_extent.y + cam.target.y,
	}

	rl.BeginDrawing()
	rl.ClearBackground( Color_BG )
	render_mode_2d()
	{
		fps_msg       := fmt.tprint( "FPS:", rl.GetFPS() )
		fps_msg_width := measure_text_size( fps_msg, default_font, 16.0, 0.0 ).x
		fps_msg_pos   := screen_get_corners().top_right - { fps_msg_width, 0 }
		debug_draw_text( fps_msg, fps_msg_pos, color = rl.GREEN )

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
			position.x -= 300
			position.y += debug.draw_debug_text_y

			content := fmt.bprintf( draw_text_scratch[:], format, ..args )
			debug_draw_text( content, position )

			debug.draw_debug_text_y += 16
		}

		// Debug Text
		{
			debug_text( "Screen Width : %v", rl.GetScreenWidth () )
			debug_text( "Screen Height: %v", rl.GetScreenHeight() )
			if replay.mode == ReplayMode.Record {
				debug_text( "Recording Input")
			}
			if replay.mode == ReplayMode.Playback {
				debug_text( "Replaying Input")
			}
		}

		if debug.mouse_vis {
			debug_text( "Position: %v", input.mouse.pos )
			rect_pos :=  transmute(Vec2) state.app_window.extent + input.mouse.pos

			width : f32 = 32
			mouse_rect : rl.Rectangle
			mouse_rect.x      = rect_pos.x - width * 0.5
			mouse_rect.y      = rect_pos.y - width * 0.5
			mouse_rect.width  = width
			mouse_rect.height = width
			rl.DrawRectangleRec( mouse_rect, Color_White )
		}

		debug.draw_debug_text_y = 50
	}
	rl.EndDrawing()
}

render_mode_2d :: proc() {
	state  := get_state(); using state
	cam    := & project.workspace.cam
	win_extent := state.app_window.extent

	rl.BeginMode2D( project.workspace.cam )

	// Frame 1
	{
		frame_1 := & project.workspace.frame_1
		rect := get_rl_rect( frame_1 )
		screen_pos := world_to_screen_pos(frame_1.position)

		rect.width  = points_to_pixels( rect.width )
		rect.height = points_to_pixels( rect.height )
		rect.x      = points_to_pixels( screen_pos.x )
		rect.y      = points_to_pixels( screen_pos.y )

		rl.DrawRectangleRec( rect, frame_1.color )
		// rl.DrawRectangleV( frame_1.position, { frame_1.width, frame_1.height }, frame_1.color )
		// rl.DrawRectanglePro( rect, frame_1.position, 0, frame_1.color )
	}

		// Frame 2
		when false
		{
			frame_1 := & project.workspace.frame_1
			rect := get_rl_rect( frame_1 )
			screen_pos := world_to_screen_pos(frame_1.position)

			rect.width  = points_to_pixels( rect.width )
			rect.height = points_to_pixels( rect.height )
			rect.x      = points_to_pixels( screen_pos.x )
			rect.y      = points_to_pixels( screen_pos.y )

			rl.DrawRectangleRec( rect, frame_1.color )
			// rl.DrawRectangleV( frame_1.position, { frame_1.width, frame_1.height }, frame_1.color )
			// rl.DrawRectanglePro( rect, frame_1.position, 0, frame_1.color )
		}

	rl.EndMode2D()
}
