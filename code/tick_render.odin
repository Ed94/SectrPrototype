package sectr

import "core:fmt"

import rl "vendor:raylib"

render :: proc()
{
	state  := get_state(); using state
	replay := & memory.replay

	half_screen_width  := f32(screen_width)  / 2
	half_screen_height := f32(screen_height) / 2

	rl.BeginDrawing()
	rl.ClearBackground( Color_BG )
	rl.BeginMode2D( project.workspace.cam )
	// rl.BeginMode3D( project.workspace.cam )
	defer {
		fps_msg := fmt.tprint( "FPS:", rl.GetFPS() )
		debug_text( fps_msg, { -half_screen_width, -half_screen_height }, color = rl.GREEN )

		rl.EndMode2D()
		// rl.EndMode3D()
		rl.EndDrawing()
		// Note(Ed) : Polls input as well.
	}

	// Frame 1
	{
		frame_1 := & project.workspace.frame_1
		rect := get_rect( frame_1 )
		rect.width  = points_to_pixels( rect.width )
		rect.height = points_to_pixels( rect.height )
		rect.x      = points_to_pixels( rect.x )
		rect.y      = points_to_pixels( rect.y )

		rl.DrawRectangleRec( rect, frame_1.color )
		// rl.DrawRectangleV( frame_1.position, { frame_1.width, frame_1.height }, frame_1.color )
		// rl.DrawRectanglePro( rect, frame_1.position, 0, frame_1.color )
	}

	debug_draw_text :: proc( format : string, args : ..any )
	{
		@static draw_text_scratch : [Kilobyte * 64]u8

		state := get_state(); using state
		if debug.draw_debug_text_y > 800 {
			debug.draw_debug_text_y = 50
		}

		content := fmt.bprintf( draw_text_scratch[:], format, ..args )
		debug_text( content, { 25, debug.draw_debug_text_y } )

		debug.draw_debug_text_y += 16
	}

	// Debug Text
	{
		debug_draw_text( "Screen Width : %v", rl.GetScreenWidth () )
		debug_draw_text( "Screen Height: %v", rl.GetScreenHeight() )
		if replay.mode == ReplayMode.Record {
			debug_draw_text( "Recording Input")
		}
		if replay.mode == ReplayMode.Playback {
			debug_draw_text( "Replaying Input")
		}
	}

	if debug.mouse_vis {
		width : f32 = 32
		pos   := debug.mouse_pos

		debug_draw_text( "Position: %v", rl.GetMousePosition() )

		mouse_rect : rl.Rectangle
		mouse_rect.x      = pos.x - width/2
		mouse_rect.y      = pos.y - width/2
		mouse_rect.width  = width
		mouse_rect.height = width
		// rl.DrawRectangleRec( mouse_rect, Color_White )
	}

	debug.draw_debug_text_y = 50
}