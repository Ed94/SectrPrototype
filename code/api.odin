package sectr

import    "core:dynlib"
import    "core:fmt"
import    "core:mem"
import    "core:os"
import    "core:strings"
import rl "vendor:raylib"

Path_Assets :: "../assets/"

ModuleAPI :: struct {
	lib         : dynlib.Library,
	load_time   : os.File_Time,
	lib_version : i32,

	startup  : type_of( startup       ),
	shutdown : type_of( sectr_shutdown),
	reload   : type_of( reload        ),
	update   : type_of( update        ),
	render   : type_of( render        )
}

Memory :: struct {
	persistent : ^ mem.Arena,
	transient  : ^ mem.Arena
}

memory : Memory

@export
startup :: proc( persistent, transient : ^ mem.Arena )
{
	memory.persistent      = persistent
	memory.transient       = transient
	context.allocator      = mem.arena_allocator( transient )
	context.temp_allocator = mem.arena_allocator( transient )

	state := cast(^State) memory.persistent

	// Rough setup of window with rl stuff
	screen_width  : i32 = 1280
	screen_height : i32 = 1000
	win_title     : cstring = "Sectr Prototype"
	rl.InitWindow( screen_width, screen_height, win_title )

	// Determining current monitor and setting the target frametime based on it..
	monitor_id         := rl.GetCurrentMonitor()
	monitor_refresh_hz := rl.GetMonitorRefreshRate( monitor_id )
	rl.SetTargetFPS( monitor_refresh_hz )
	fmt.println( "Set target FPS to: %v", monitor_refresh_hz )

	// Basic Font Setup
	{
		path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		cstr                         := strings.clone_to_cstring(path_rec_mono_semicasual_reg)
		font_rec_mono_semicasual_reg  = rl.LoadFontEx( cstr, 24, nil, 0 )
		delete( cstr)

		rl.GuiSetFont( font_rec_mono_semicasual_reg ) // TODO(Ed) : Does this do anything?
		default_font = font_rec_mono_semicasual_reg
	}
}

// For some reason odin's symbols conflict with native foreign symbols...
@export
sectr_shutdown :: proc()
{
	rl.UnloadFont( font_rec_mono_semicasual_reg )
	rl.CloseWindow()
}

@export
reload :: proc( persistent, transient : ^ mem.Arena )
{
	memory.persistent      = persistent
	memory.transient       = transient
	context.allocator      = mem.arena_allocator( persistent )
	context.temp_allocator = mem.arena_allocator( transient )
}

@export
update :: proc() -> b32
{
	should_shutdown : b32 =  ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}

draw_text_y : f32 = 50
@export
render :: proc()
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
		@static
		draw_text_scratch : [Kilobyte * 64]u8
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
