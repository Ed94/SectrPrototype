package sectr

import "core:fmt"

import rl "vendor:raylib"

draw_text_y : f32 = 50

run_cycle :: proc( running : ^b32 )
{
	for ; running^ ;
	{
		if rl.WindowShouldClose() {
			running^ = false;
		}

		// Logic Update
		{

		}

		// Rendering
		{
			rl.BeginDrawing()
			rl.ClearBackground( Color_BG )
			defer {
				rl.DrawFPS( 0, 0 )
				rl.EndDrawing()
				// Note(Ed) : Polls input as well.
			}

			draw_text :: proc( format : string, args : ..any )
			{
			    @static draw_text_scratch : [65536]u8
				if ( draw_text_y > 500 ) {
					draw_text_y = 50
				}
				content := fmt.bprintf( draw_text_scratch[:], format, ..args )
				debug_text( content, 25, draw_text_y )
				draw_text_y += 16
			}

			draw_text( "Monitor      : %v", rl.GetMonitorName(0) )
			draw_text( "Screen Width : %v", rl.GetScreenWidth() )
			draw_text( "Screen Height: %v", rl.GetScreenHeight() )


			draw_text_y = 50
		}
	}
}
