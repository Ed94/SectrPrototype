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
	tick       : type_of( tick ),
	clean_temp : type_of( clean_temp ),
}

@export
startup :: proc( live_mem : virtual.Arena, snapshot_mem : []u8, host_logger : ^ Logger )
{
	init( & memory.logger, "Sectr", host_logger.file_path, host_logger.file )
	context.logger = to_odin_logger( & memory.logger )

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

	context.user_ptr = state

	input      = & input_data[1]
	input_prev = & input_data[0]

	rl.SetConfigFlags( { rl.ConfigFlag.WINDOW_RESIZABLE, rl.ConfigFlag.WINDOW_TOPMOST } )

	// Rough setup of window with rl stuff
	window_width  : i32 = 1000
	window_height : i32 = 600
	win_title     : cstring = "Sectr Prototype"
	rl.InitWindow( window_width, window_height, win_title )
	log( "Raylib initialized and window opened" )

	window := & state.app_window
	window.extent.x = f32(window_width)  * 0.5
	window.extent.y = f32(window_height) * 0.5

	// We do not support non-uniform DPI.
	window.dpi_scale = rl.GetWindowScaleDPI().x
	window.dpc       = os_default_dpc * window.dpi_scale

	// Determining current monitor and setting the target frametime based on it..
	monitor_id         = rl.GetCurrentMonitor()
	monitor_refresh_hz = rl.GetMonitorRefreshRate( monitor_id )
	rl.SetTargetFPS( monitor_refresh_hz )
	log( fmt.tprintf( "Set target FPS to: %v", monitor_refresh_hz ) )

	// Basic Font Setup
	{
		path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		cstr                         := strings.clone_to_cstring( path_rec_mono_semicasual_reg )
		font_rec_mono_semicasual_reg  = rl.LoadFontEx( cstr, 24, nil, 0 )
		delete( cstr)

		rl.GuiSetFont( font_rec_mono_semicasual_reg ) // TODO(Ed) : Does this do anything?
		default_font = font_rec_mono_semicasual_reg
		log( "Default font loaded" )
	}

	{
		using project
		path           = "./"
		name           = "First Project"
		workspace.name = "First Workspace"
		{
			using project.workspace
			cam = {
				target = { 0, 0 },
				offset = transmute(Vec2) window.extent,
				rotation = 0,
				zoom = 1.0,
			}
			// cam = {
			// 	position   = { 0, 0, -100 },
			// 	target     = { 0, 0, 0 },
			// 	up         = { 0, 1, 0 },
			// 	fovy       = 90,
			// 	projection = rl.CameraProjection.ORTHOGRAPHIC,
			// }

			frame_1.color  = Color_BG_TextBox
			// Frame is getting interpreted as points (It doesn't have to be, I'm just doing it...)
			box_set_size( & frame_1, { 400, 200 } )

			frame_2.color = Color_BG_TextBox_Green
			box_set_size( & frame_2, { 350, 500 } )
			// frame_1.position = { 1000, 1000 }
		}
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
	log("Module shutdown complete")
}

@export
reload :: proc( live_mem : virtual.Arena, snapshot_mem : []u8, host_logger : ^ Logger )
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

	log("Module reloaded")
}

// TODO(Ed) : This lang really not have a fucking swap?
swap :: proc( a, b : ^ $Type ) -> ( ^ Type, ^ Type ) {
	return b, a
}

@export
tick :: proc ( delta_time : f64 ) -> b32
{
	result := update( delta_time )
	render()
	return result
}

@export
clean_temp :: proc()
{
	mem.tracking_allocator_clear( & memory.temp.tracker )
}
