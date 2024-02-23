package sectr

import    "base:runtime"
import  c "core:c/libc"
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
	shutdown   : type_of( sectr_shutdown ),
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

		when Use_TrackingAllocator {
			// We assign the beginning of the block to be the host's persistent memory's arena.
			// Then we offset past the arena and determine its slice to be the amount left after for the size of host's persistent.
			persistent = tracked_allocator_init_vmem( persistent_slice, internals_size )
			transient  = tracked_allocator_init_vmem( transient_slice,  internals_size )
			temp       = tracked_allocator_init_vmem( temp_slice ,      internals_size )
		}
		else {
			persistent = arena_allocator_init_vmem( persistent_slice )
			transient  = arena_allocator_init_vmem( transient_slice )
			temp       = arena_allocator_init_vmem( temp_slice )
		}

		context.allocator      = transient_allocator()
		context.temp_allocator = temp_allocator()
	}

	state := new( State, persistent_allocator() )
	using state

	context.user_ptr = state

	input      = & input_data[1]
	input_prev = & input_data[0]

	// rl.Odin_SetMalloc( RL_MALLOC )

	rl.SetConfigFlags( { rl.ConfigFlag.WINDOW_RESIZABLE /*, rl.ConfigFlag.WINDOW_TOPMOST*/ } )

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
	window.ppcm      = os_default_ppcm * window.dpi_scale

	// Determining current monitor and setting the target frametime based on it..
	monitor_id         = rl.GetCurrentMonitor()
	monitor_refresh_hz = rl.GetMonitorRefreshRate( monitor_id )
	rl.SetTargetFPS( monitor_refresh_hz )
	log( fmt.tprintf( "Set target FPS to: %v", monitor_refresh_hz ) )

	// Basic Font Setup
	{
		font_provider_startup()
		// path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		// font_rec_mono_semicasual_reg  = font_load( path_rec_mono_semicasual_reg, 24.0, "RecMonoSemiCasual_Regular" )

		// path_squidgy_slimes := strings.concatenate( { Path_Assets, "Squidgy Slimes.ttf" } )
		// font_squidgy_slimes = font_load( path_squidgy_slimes, 24.0, "Squidgy_Slime" )

		path_firacode := strings.concatenate( { Path_Assets, "FiraCode-Regular.ttf" } )
		font_firacode  = font_load( path_firacode, 24.0, "FiraCode" )

		// font_data, read_succeded : = os.read_entire_file( path_rec_mono_semicasual_reg  )
		// verify( read_succeded, fmt.tprintf("Failed to read font file for: %v", path_rec_mono_semicasual_reg) )

		// cstr                         := strings.clone_to_cstring( path_rec_mono_semicasual_reg )
		// font_rec_mono_semicasual_reg  = rl.LoadFontEx( cstr, cast(i32) points_to_pixels(24.0), nil, 0 )
		// delete( cstr)

		// rl.GuiSetFont( font_rec_mono_semicasual_reg ) // TODO(Ed) : Does this do anything?
		default_font = font_firacode
		log( "Default font loaded" )
	}

	// Demo project setup
	{
		using project
		path           = "./"
		name           = "First Project"
		workspace.name = "First Workspace"
		{
			using project.workspace
			cam = {
				target   = { 0, 0 },
				offset   = transmute(Vec2) window.extent,
				rotation = 0,
				zoom     = 1.0,
			}
			// cam = {
			// 	position   = { 0, 0, -100 },
			// 	target     = { 0, 0, 0 },
			// 	up         = { 0, 1, 0 },
			// 	fovy       = 90,
			// 	projection = rl.CameraProjection.ORTHOGRAPHIC,
			// }

			// Setup workspace UI state
			ui_startup( & workspace.ui, persistent_allocator() )
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

	font_provider_shutdown()

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

	when Use_TrackingAllocator {
		persistent = cast( ^ TrackedAllocator ) & persistent_slice[0]
		transient  = cast( ^ TrackedAllocator ) & transient_slice[0]
		temp       = cast( ^ TrackedAllocator ) & temp_slice[0]
	}
	else {
		persistent = cast( ^ Arena ) & persistent_slice[0]
		transient  = cast( ^ Arena ) & transient_slice[0]
		temp       = cast( ^ Arena ) & temp_slice[0]
	}

	context.allocator      = transient_allocator()
	context.temp_allocator = temp_allocator()

	// Procedure Addresses are not preserved on hot-reload. They must be restored for persistent data.
	// The only way to alleviate this is to either do custom handles to allocators
	// Or as done below, correct containers using allocators on reload.
	// Thankfully persistent dynamic allocations are rare, and thus we know exactly which ones they are.

	// font_provider_data := & get_state().font_provider_data
	// font_provider_data.font_cache.allocator = arena_allocator( & font_provider_data.font_arena )

	// Have to reload allocators for all dynamic allocating data-structures.
	ui_reload( & get_state().project.workspace.ui, persistent_allocator() )

	log("Module reloaded")
}

// TODO(Ed) : This lang really not have a fucking swap?
swap :: proc( a, b : ^ $Type ) -> ( ^ Type, ^ Type ) {
	return b, a
}

@export
tick :: proc( delta_time : f64 ) -> b32
{
	context.allocator      = transient_allocator()
	context.temp_allocator = temp_allocator()

	result := update( delta_time )
	render()
	return result
}

@export
clean_temp :: proc() {
	when Use_TrackingAllocator {
		mem.tracking_allocator_clear( & memory.temp.tracker )
	}
	else {
		free_all( temp_allocator() )
	}
}
