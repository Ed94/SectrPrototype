package sectr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import rl "vendor:raylib"

memory : Memory

memory_chunk_size      :: 2 * Gigabyte
memory_persistent_size :: 128 * Megabyte
memory_trans_temp_size :: (memory_chunk_size - memory_persistent_size ) / 2

Memory :: struct {
	live       : virtual.Arena,
	snapshot   : []u8,
	persistent : ^ TrackedAllocator,
	transient  : ^ TrackedAllocator,
	temp       : ^ TrackedAllocator
}

State :: struct {
	input_data : [2] InputState,

	input_prev : ^ InputState,
	input      : ^ InputState,

	replay : ReplayState,
	debug  : DebugData,

	project : Project,

	screen_width  : i32,
	screen_height : i32,

	monitor_id         : i32,
	monitor_refresh_hz : i32,

	engine_refresh_hz     : i32,
	engine_refresh_target : i32,

	font_rec_mono_semicasual_reg : Font,
	default_font                 : Font,
}

Project :: struct {
	// TODO(Ed) : Support multiple workspaces
	workspace : Workspace
}

Workspace :: struct {

}

get_state :: proc() -> (^ State) {
	return cast( ^ State ) raw_data( memory.persistent.backing.data )
}

DebugData :: struct {
	square_size : i32,
	square_pos  : rl.Vector2,

	draw_debug_text_y : f32,

	mouse_vis : b32,
	mouse_pos : vec3,
}

DebugActions :: struct {
	pause_renderer : b32,

	load_auto_snapshot : b32,
	record_replay      : b32,
	play_replay        : b32,

	show_mouse_pos : b32,
}

poll_debug_actions :: proc( actions : ^ DebugActions, input : ^ InputState )
{
	using actions
	using input

	base_replay_bind := pressed(keyboard.right_alt) && pressed( keyboard.L)
	record_replay     = base_replay_bind && pressed(keyboard.right_shift)
	play_replay       = base_replay_bind

	show_mouse_pos = pressed(keyboard.right_alt) && pressed(keyboard.M)
}

save_snapshot :: proc( snapshot : [^]u8 ) {
	live_ptr := cast( ^ rawptr ) memory.live.curr_block.base
	mem.copy_non_overlapping( & snapshot[0], live_ptr, memory_chunk_size )
}

load_snapshot :: proc( snapshot : [^]u8 ) {
	live_ptr := cast( ^ rawptr ) memory.live.curr_block.base
	mem.copy_non_overlapping( live_ptr, snapshot, memory_chunk_size )
}

ReplayMode :: enum {
	Off,
	Record,
	Playback,
}

ReplayState :: struct {
	loop_active : b32,
	mode        : ReplayMode,
	active_file : os.Handle
}

replay_recording_begin :: proc( path : string )
{
	result := os.remove( path )
	if ( result != os.ERROR_NONE )
	{
			// TODO(Ed) : Setup a proper logging interface
			fmt.    printf( "Failed to delete replay file before beginning a new one" )
			runtime.debug_trap()
			os.     exit( -1 )
			// TODO(Ed) : Figure out the error code enums..
	}

	replay_file, open_error := os.open( path, os.O_RDWR | os.O_CREATE )
	if ( open_error != os.ERROR_NONE )
	{
		// TODO(Ed) : Setup a proper logging interface
		fmt.    printf( "Failed to create or open the replay file" )
		runtime.debug_trap()
		os.     exit( -1 )
		// TODO(Ed) : Figure out the error code enums..
	}

	state := get_state(); using state
	replay.active_file = replay_file
	replay.mode        = ReplayMode.Record
}

replay_recording_end :: proc() {
	state := get_state(); using state
	replay.mode = ReplayMode.Off
	os.close( replay.active_file )
}

replay_playback_begin :: proc( path : string )
{
	if ! file_exists( path )
	{
				// TODO(Ed) : Setup a proper logging interface
				fmt.    printf( "Failed to create or open the replay file" )
				runtime.debug_trap()
				os.     exit( -1 )
				// TODO(Ed) : Figure out the error code enums..
	}

	replay_file, open_error := os.open( path, os.O_RDWR | os.O_CREATE )
	if ( open_error != os.ERROR_NONE )
	{
		// TODO(Ed) : Setup a proper logging interface
		fmt.    printf( "Failed to create or open the replay file" )
		runtime.debug_trap()
		os.     exit( -1 )
		// TODO(Ed) : Figure out the error code enums..
	}
	// TODO(Ed): WE need to wrap any actions that can throw a fatal like this. Files need a grime wrap.

	state := get_state(); using state
	replay.active_file = replay_file
	replay.mode = ReplayMode.Playback
}

replay_playback_end :: proc() {
	state := get_state(); using state
	replay.mode = ReplayMode.Off
	os.close( replay.active_file )
}
