package sectr

import    "base:runtime"
import    "core:dynlib"
import    "core:fmt"
import    "core:mem"
import    "core:mem/virtual"
import    "core:os"
import    "core:slice"
import    "core:strings"
import rl "vendor:raylib"

Path_Assets       :: "../assets/"
Path_Input_Replay :: "scratch.sectr_replay"

ModuleAPI :: struct {
	lib         : dynlib.Library,
	write_time  : os.File_Time,
	lib_version : i32,

	startup    : type_of( startup ),
	shutdown   : type_of( sectr_shutdown),
	reload     : type_of( reload ),
	update     : type_of( update ),
	render     : type_of( render ),
	clean_temp : type_of( clean_temp ),
}

@export
startup :: proc( live_mem : virtual.Arena, snapshot_mem : []u8 )
{
	// Setup memory for the first time
	{
		arena_size     :: size_of( mem.Arena)
		internals_size :: 4 * Megabyte

		using memory;
		block := live_mem.curr_block

		live     = live_mem
		snapshot = snapshot_mem

		persistent_slice := slice_ptr( block.base, memory_persistent_size )
		transient_slice  := slice_ptr( memory_after( persistent_slice), memory_trans_temp_size )
		temp_slice       := slice_ptr( memory_after( transient_slice),  memory_trans_temp_size )

		// We assign the beginning of the block to be the host's persistent memory's arena.
		// Then we offset past the arena and determine its slice to be the amount left after for the size of host's persistent.
		persistent = tracked_allocator_init_vmem( persistent_slice, internals_size )
		transient  = tracked_allocator_init_vmem( transient_slice,  internals_size )
		temp       = tracked_allocator_init_vmem( temp_slice ,      internals_size )

		context.allocator      = tracked_allocator( transient )
		context.temp_allocator = tracked_allocator( temp )
	}
	state := new( State, tracked_allocator( memory.persistent ) )
	using state

	input      = & input_data[1]
	input_prev = & input_data[0]

	// Rough setup of window with rl stuff
	screen_width  = 1280
	screen_height = 1000
	win_title     : cstring = "Sectr Prototype"
	rl.InitWindow( screen_width, screen_height, win_title )

	// Determining current monitor and setting the target frametime based on it..
	monitor_id         = rl.GetCurrentMonitor    ()
	monitor_refresh_hz = rl.GetMonitorRefreshRate( monitor_id )
	rl.SetTargetFPS( monitor_refresh_hz )
	fmt.println( "Set target FPS to: %v", monitor_refresh_hz )

	// Basic Font Setup
	{
		path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		cstr                         := strings.clone_to_cstring( path_rec_mono_semicasual_reg )
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
	if memory.persistent == nil {
		return
	}
	state := get_state()

	// Replay
	{
		os.close( memory.replay.active_file )
	}

	// Raylib
	{
		rl.UnloadFont ( state.font_rec_mono_semicasual_reg )
		rl.CloseWindow()
	}
}

@export
reload :: proc( live_mem : virtual.Arena, snapshot_mem : []u8 )
{
	using memory;
	block := live_mem.curr_block

	live     = live_mem
	snapshot = snapshot_mem

	persistent_slice := slice_ptr( block.base, memory_persistent_size )
	transient_slice  := slice_ptr( memory_after( persistent_slice), memory_trans_temp_size )
	temp_slice       := slice_ptr( memory_after( transient_slice),  memory_trans_temp_size )

	persistent = cast( ^TrackedAllocator ) & persistent_slice[0]
	transient  = cast( ^TrackedAllocator ) & transient_slice[0]
	temp       = cast( ^TrackedAllocator ) & temp_slice[0]
}

// TODO(Ed) : This lang really not have a fucking swap?
swap :: proc( a, b : ^ $Type ) -> ( ^ Type, ^ Type ) {
	return b, a
}

@export
update :: proc() -> b32
{
	state  := get_state(); using state
	replay := & memory.replay

	state.input, state.input_prev = swap( state.input, state.input_prev )
	poll_input( state.input_prev, state.input )

	debug_actions : DebugActions = {}
	poll_debug_actions( & debug_actions, state.input )

	// Input Replay
	{
		if debug_actions.record_replay { #partial switch replay.mode
		{
			case ReplayMode.Off : {
				save_snapshot( & memory.snapshot[0] )
				replay_recording_begin( Path_Input_Replay )
			}
			case ReplayMode.Record : {
				replay_recording_end()
			}
		}}

		DO_NOT_CONTINUE : b32 = false

		if debug_actions.play_replay { switch replay.mode
		{
			case ReplayMode.Off : {
				if ! file_exists( Path_Input_Replay ) {
					save_snapshot( & memory.snapshot[0] )
					replay_recording_begin( Path_Input_Replay )
					break
				}
				else {
					load_snapshot( & memory.snapshot[0] )
					replay_playback_begin( Path_Input_Replay )
					break
				}
			}
			case ReplayMode.Playback : {
				replay_playback_end()
				load_snapshot( & memory.snapshot[0] )
				break
			}
			case ReplayMode.Record : {
				replay_recording_end()
				load_snapshot( & memory.snapshot[0] )
				replay_playback_begin( Path_Input_Replay )
				break
			}
		}}

		if replay.mode == ReplayMode.Record {
			record_input( replay.active_file, input )
		}
		else if replay.mode == ReplayMode.Playback {
			play_input( replay.active_file, input )
		}
	}

	if debug_actions.show_mouse_pos {
		debug.mouse_vis = !debug.mouse_vis
	}

	debug.mouse_pos.basis = { input.mouse.X, input.mouse.Y }

	should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}

@export
render :: proc()
{
	state  := get_state(); using state
	replay := & memory.replay

	rl.BeginDrawing()
	rl.ClearBackground( Color_BG )
	defer {
		rl.DrawFPS( 0, 0 )
		rl.EndDrawing()
		// Note(Ed) : Polls input as well.
	}

	draw_text :: proc( format : string, args : ..any )
	{
		@static draw_text_scratch : [Kilobyte * 64]u8

		state := get_state(); using state
		if debug.draw_debug_text_y > 800 {
			debug.draw_debug_text_y = 50
		}

		content := fmt.bprintf( draw_text_scratch[:], format, ..args )
		debug_text( content, 25, debug.draw_debug_text_y )

		debug.draw_debug_text_y += 16
	}

	draw_text( "Screen Width : %v", rl.GetScreenWidth () )
	draw_text( "Screen Height: %v", rl.GetScreenHeight() )

	if replay.mode == ReplayMode.Record {
		draw_text( "Recording Input")
	}
	if replay.mode == ReplayMode.Playback {
		draw_text( "Replaying Input")
	}

	if debug.mouse_vis {
		width : f32 = 32
		pos   := debug.mouse_pos

		draw_text( "Position: %v", rl.GetMousePosition() )

		mouse_rect : rl.Rectangle
		mouse_rect.x      = pos.x - width/2
		mouse_rect.y      = pos.y - width/2
		mouse_rect.width  = width
		mouse_rect.height = width
		rl.DrawRectangleRec( mouse_rect, Color_White )
	}

	debug.draw_debug_text_y = 50
}

@export
clean_temp :: proc()
{
	mem.tracking_allocator_clear( & memory.temp.tracker )
}
