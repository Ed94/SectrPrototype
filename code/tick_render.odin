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
			position.x -= 200
			position.y += debug.draw_debug_text_y

			content := fmt.bprintf( draw_text_scratch[:], format, ..args )
			debug_draw_text( content, position )

			debug.draw_debug_text_y += 16
		}

		// Debug Text
		{
			// debug_text( "Screen Width : %v", rl.GetScreenWidth () )
			// debug_text( "Screen Height: %v", rl.GetScreenHeight() )
			if replay.mode == ReplayMode.Record {
				debug_text( "Recording Input")
			}
			if replay.mode == ReplayMode.Playback {
				debug_text( "Replaying Input")
			}
		}

		if debug.mouse_vis {
			debug_text( "Position: %v", input.mouse.pos )
			cursor_pos :=  transmute(Vec2) state.app_window.extent + input.mouse.pos
			rl.DrawCircleV( cursor_pos, 10, Color_White_A125 )
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

	// debug.frame_1_on_top = true

	boxes : [2]^Box2
	if debug.frame_1_on_top {
		boxes = { & project.workspace.frame_2, & project.workspace.frame_1 }
	}
	else {
		boxes = { & project.workspace.frame_1, & project.workspace.frame_2 }
	}

	for box in boxes {
		screen_pos := world_to_screen_pos(box.position) - Vec2(box.extent)
		size       := transmute(Vec2) box.extent * 2.0

		rect : rl.Rectangle
		rect.x      = screen_pos.x
		rect.y      = screen_pos.y
		rect.width  = size.x
		rect.height = size.y
		rl.DrawRectangleRec( rect, box.color )
	}

	if debug.mouse_vis {
		// rl.DrawCircleV(  screen_to_world(input.mouse.pos), 10, Color_GreyRed )
	}

	rl.EndMode2D()
}
