package sectr

import      "core:io"
import      "core:fmt"
import      "core:mem"
import      "core:mem/virtual"
import      "core:strings"
import      "core:unicode/utf8"
import rl   "vendor:raylib"

kilobytes :: proc ( kb : $integer_type ) -> integer_type {
	return kb * 1024
}
megabytes :: proc ( kb : $integer_type ) -> integer_type {
	return kb * 1024 * 1024
}

Frame :: struct {
	bounds : rl.Rectangle
	// collision_bounds : rl.Rectangle, // Interaction space
	// nav_bounds       : rl.Rectangle  // Navigation space
}

TextLine :: [dynamic]u8
TextBox  :: struct {
	using frame      : Frame,
		  text       : strings.Builder,

		  // TODO(Ed) : Make use of the lines view, this will tell use when a line begins or ends
		  lines      : [dynamic]TextLine,
		  cursor_pos : i32
}

// TextBlob :: struct {
// 	buffer : string
// }

Null_Rune : rune = 0

Color_BG           :: rl.Color {  41,  41,  45, 255 }
Color_BG_TextBox   :: rl.Color {  32,  32,  32, 255 }
Color_Frame_Hover  :: rl.Color { 122, 122, 125, 255 }
Color_Frame_Select :: rl.Color { 188, 188, 188, 255 }

Path_Assets :: "../assets/"

main :: proc()
{
	// Rough setup of window with rl stuff
	screen_width  : i32     = 1280
	screen_height : i32     = 1000
	win_title     : cstring = "Sectr Prototype"
	rl.InitWindow( screen_width, screen_height, win_title )
	defer {
		rl.CloseWindow()
	}

	monitor_id           := rl.GetCurrentMonitor()
	monitor_refresh_rate := rl.GetMonitorRefreshRate( monitor_id )
	rl.SetTargetFPS( monitor_refresh_rate )

	font_rec_mono_semicasual_reg     :  rl.Font; {
		path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" } )
		cstr                         := strings.clone_to_cstring(path_rec_mono_semicasual_reg)
		font_rec_mono_semicasual_reg  = rl.LoadFontEx( cstr, 24, nil, 0 )
		delete( cstr )
	}

	hovered_frame : ^Frame = nil
	focused_frame : ^Frame = nil
	text_box      : TextBox
	{
		builder, err := strings.builder_make_len_cap( 0, megabytes( cast(int) 1 ) / 4 )
		if err != mem.Allocator_Error.None {
			fmt.println( "Failed to allocate text arena!" )
			return
		}
		text_box.text = builder
	}

	for ; ! rl.WindowShouldClose() ;
	{
		mouse_pos := rl.GetMousePosition()

		// Logic Update
		{
			rect := &text_box.bounds
			rect.width  = 900
			rect.height = 400
			rect.x      = cast(f32) (screen_width  / 2) - rect.width / 2.0
			rect.y      = cast(f32) (screen_height / 2) - rect.height

			if rl.CheckCollisionPointRec( mouse_pos, rect^ ) {
				hovered_frame = & text_box
			}
			else {
				hovered_frame = nil
			}

			if rl.IsMouseButtonPressed( rl.MouseButton.LEFT )
			{
				if hovered_frame != nil {
					focused_frame = hovered_frame
				}
				else {
					focused_frame = nil
				}
			}

			if focused_frame != nil {
				for code_point := rl.GetCharPressed();
					code_point != Null_Rune;
				{
					strings.write_rune( & text_box.text, code_point );
					code_point = rl.GetCharPressed()
				}
			}
		}

		// Rendering
		{
			rl.BeginDrawing()
			rl.ClearBackground( Color_BG )

			// Text Box
			{
				rl.DrawRectangleRec( text_box.bounds, Color_BG_TextBox )

				if focused_frame != nil {
					rl.DrawRectangleLinesEx( focused_frame.bounds, 2, Color_Frame_Select )
				}
				else if hovered_frame != nil {
					rl.DrawRectangleLinesEx( hovered_frame.bounds, 2, Color_Frame_Hover )
				}

				txt_str := strings.to_string( text_box.text )
				runes := utf8.string_to_runes(txt_str)

				rl.GuiSetFont( font_rec_mono_semicasual_reg )
				if len(txt_str) > 0 {
					rl.DrawTextCodepoints( font_rec_mono_semicasual_reg, raw_data( runes ),
						cast(i32) len(runes),
						rl.Vector2 { text_box.bounds.x + 10, text_box.bounds.y + 10 },
						24.0, // font size
						0.0,  // font spacing
						rl.WHITE
					)
				}
			}

			rl.EndDrawing()
		}
	}
}
