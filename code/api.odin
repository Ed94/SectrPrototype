package sectr

import    "core:dynlib"
import    "core:fmt"
import    "core:mem"
import    "core:mem/virtual"
import    "core:os"
import    "core:slice"
import    "core:strings"
import rl "vendor:raylib"

Path_Assets :: "../assets/"

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

memory_chunk_size      :: 2 * Gigabyte
memory_persistent_size :: 128 * Megabyte
memory_trans_temp_size :: (memory_chunk_size - memory_persistent_size ) / 2

Memory :: struct {
	live       : ^ virtual.Arena,
	snapshot   : ^ virtual.Arena,
	persistent : ^ TrackedAllocator,
	transient  : ^ TrackedAllocator,
	temp       : ^ TrackedAllocator
}

memory : Memory

@export
startup :: proc( live_mem, snapshot_mem : ^ virtual.Arena )
{
	// Setup memory for the first time
	{
		Arena              :: mem.Arena
		Tracking_Allocator :: mem.Tracking_Allocator
		arena_allocator    :: mem.arena_allocator
		arena_init         :: mem.arena_init
		slice_ptr          :: mem.slice_ptr

		arena_size     :: size_of( mem.Arena)
		internals_size :: 4 * Megabyte

		using memory;
		block := live_mem.curr_block

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

	// Rough setup of window with rl stuff
	screen_width  = 1280
	screen_height = 1000
	win_title     : cstring = "Sectr Prototype"
	rl.InitWindow( screen_width, screen_height, win_title )

	// Determining current monitor and setting the target frametime based on it..
	monitor_id         = rl.GetCurrentMonitor()
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
	rl.UnloadFont( state.font_rec_mono_semicasual_reg )
	rl.CloseWindow()
}

@export
reload :: proc( live_mem, snapshot_mem : ^ virtual.Arena )
{
	Arena              :: mem.Arena
	Tracking_Allocator :: mem.Tracking_Allocator
	arena_allocator    :: mem.arena_allocator
	slice_ptr          :: mem.slice_ptr

	using memory;
	block := live_mem.curr_block

	persistent_slice := slice_ptr( block.base, memory_persistent_size )
	transient_slice  := slice_ptr( memory_after( persistent_slice), memory_trans_temp_size )
	temp_slice       := slice_ptr( memory_after( transient_slice),  memory_trans_temp_size )

	persistent = cast( ^TrackedAllocator ) & persistent_slice[0]
	transient  = cast( ^TrackedAllocator ) & transient_slice[0]
	temp       = cast( ^TrackedAllocator ) & temp_slice[0]
}

@export
update :: proc() -> b32
{
	state := get_state(); using state

	should_shutdown : b32 = ! cast(b32) rl.WindowShouldClose()
	return should_shutdown
}

@export
render :: proc()
{
	state := get_state(); using state

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
		if ( draw_debug_text_y > 800 ) {
			draw_debug_text_y = 50
		}

		content := fmt.bprintf( draw_text_scratch[:], format, ..args )
		debug_text( content, 25, draw_debug_text_y )

		draw_debug_text_y += 16
	}

	draw_text( "Screen Width : %v", rl.GetScreenWidth() )
	draw_text( "Screen Height: %v", rl.GetScreenHeight() )

	draw_debug_text_y = 50
}

@export
clean_temp :: proc()
{
	mem.tracking_allocator_clear( & memory.temp.tracker )
}

get_state :: proc() -> (^ State)
{
	return cast(^ State) raw_data( memory.persistent.backing.data )
}
