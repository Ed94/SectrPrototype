package sectr

import    "base:runtime"
import  c "core:c/libc"
import    "core:dynlib"
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
	write_time  : FileTime,
	lib_version : i32,

	startup     : type_of( startup ),
	shutdown    : type_of( sectr_shutdown ),
	reload      : type_of( reload ),
	tick        : type_of( tick ),
	clean_frame : type_of( clean_frame ),
}

@export
startup :: proc( persistent_mem, frame_mem, transient_mem, files_buffer_mem : ^VArena, host_logger : ^ Logger )
{
	logger_init( & Memory_App.logger, "Sectr", host_logger.file_path, host_logger.file )
	context.logger = to_odin_logger( & Memory_App.logger )

	// Setup memory for the first time
	{
		using Memory_App;
		persistent   = persistent_mem
		frame        = frame_mem
		transient    = transient_mem
		files_buffer = files_buffer_mem

		context.allocator      = persistent_allocator()
		context.temp_allocator = transient_allocator()
	}

	state := new( State, persistent_allocator() )
	using state

	// Setup General Slab
	{
		alignment := uint(mem.DEFAULT_ALIGNMENT)

		policy     : SlabPolicy
		policy_ptr := & policy
		push( policy_ptr, SlabSizeClass {  16 * Megabyte,   4 * Kilobyte, alignment })
		push( policy_ptr, SlabSizeClass {  32 * Megabyte,  16 * Kilobyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,  32 * Kilobyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,  64 * Kilobyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte, 128 * Kilobyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte, 256 * Kilobyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte, 512 * Kilobyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,   1 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,   2 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,   4 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,   8 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,  16 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass {  64 * Megabyte,  32 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass { 256 * Megabyte,  64 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass { 256 * Megabyte, 128 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass { 512 * Megabyte, 256 * Megabyte, alignment })
		push( policy_ptr, SlabSizeClass { 512 * Megabyte, 512 * Megabyte, alignment })

		alloc_error : AllocatorError
		general_slab, alloc_error = slab_init( policy_ptr, allocator = persistent_allocator() )
		verify( alloc_error == .None, "Failed to allocate the general slab allocator" )
	}

	context.user_ptr = state

	input      = & input_data[1]
	input_prev = & input_data[0]

	// rl.Odin_SetMalloc( RL_MALLOC )

	rl.SetConfigFlags( {
		rl.ConfigFlag.WINDOW_RESIZABLE,
		// rl.ConfigFlag.WINDOW_TOPMOST,
	})

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
	log( str_fmt_tmp( "Set target FPS to: %v", monitor_refresh_hz ) )

	// Basic Font Setup
	{
		font_provider_startup()
		// path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		// font_rec_mono_semicasual_reg  = font_load( path_rec_mono_semicasual_reg, 24.0, "RecMonoSemiCasual_Regular" )

		// path_squidgy_slimes := strings.concatenate( { Path_Assets, "Squidgy Slimes.ttf" } )
		// font_squidgy_slimes = font_load( path_squidgy_slimes, 24.0, "Squidgy_Slime" )

		path_firacode := strings.concatenate( { Path_Assets, "FiraCode-Regular.ttf" }, frame_allocator() )
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
	if Memory_App.persistent == nil {
		return
	}
	state := get_state()

	// Replay
	{
		file_close( Memory_App.replay.active_file )
	}

	font_provider_shutdown()

	log("Module shutdown complete")
}

@export
reload :: proc( persistent_mem, frame_mem, transient_mem, files_buffer_mem : ^VArena, host_logger : ^ Logger )
{
	using Memory_App;

	persistent   = persistent_mem
	frame        = frame_mem
	transient    = transient_mem
	files_buffer = files_buffer_mem

	context.allocator      = persistent_allocator()
	context.temp_allocator = transient_allocator()

	// Procedure Addresses are not preserved on hot-reload. They must be restored for persistent data.
	// The only way to alleviate this is to either do custom handles to allocators
	// Or as done below, correct containers using allocators on reload.
	// Thankfully persistent dynamic allocations are rare, and thus we know exactly which ones they are.

	font_provider_data := & get_state().font_provider_data
	// font_provide_data.font_cache.hashes.allocator = slab_allocator()
	// font_provide_data.font_cache.entries.allocator = slab_allocator()

	ui_reload( & get_state().project.workspace.ui, persistent_allocator() )

	log("Module reloaded")
}

// TODO(Ed) : This lang really not have a fucking swap?
swap :: proc( a, b : ^ $Type ) -> ( ^ Type, ^ Type ) {
	return b, a
}

@export
tick :: proc( delta_time : f64, delta_ns : Duration ) -> b32
{
	context.allocator      = frame_allocator()
	context.temp_allocator = transient_allocator()

	get_state().frametime_delta_ns = delta_ns

	result := update( delta_time )
	render()
	return result
}

@export
clean_frame :: proc() {
	free_all( frame_allocator() )
}
