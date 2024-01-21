package sectr

import "core:strings"

import rl "vendor:raylib"

Path_Assets :: "../assets/"


WindowState :: struct {

}

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

	// Basic Font Setup
	{
		path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" } )
		cstr                         := strings.clone_to_cstring(path_rec_mono_semicasual_reg)
		font_rec_mono_semicasual_reg  = rl.LoadFontEx( cstr, 24, nil, 0 )
		delete( cstr )

		rl.GuiSetFont( font_rec_mono_semicasual_reg ) // TODO(Ed) : Does this do anything?
		default_font = font_rec_mono_semicasual_reg
	}

	running : b32 = true
	run_cycle( & running )
}
