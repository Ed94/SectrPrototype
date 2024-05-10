package sectr

import    "base:runtime"
import  c "core:c/libc"
import    "core:dynlib"
import    "core:mem"
import    "core:mem/virtual"
import    "core:os"
import    "core:slice"
import    "core:strings"
import    "core:time"
import    "core:prof/spall"
import rl "vendor:raylib"

Path_Assets       :: "../assets/"
Path_Input_Replay :: "scratch.sectr_replay"

Persistent_Slab_DBG_Name := "Peristent Slab"
Frame_Slab_DBG_Name      := "Frame Slab"
Transient_Slab_DBG_Name  := "Transient Slab"

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
startup :: proc( prof : ^SpallProfiler, persistent_mem, frame_mem, transient_mem, files_buffer_mem : ^VArena, host_logger : ^Logger )
{
	spall.SCOPED_EVENT( & prof.ctx, & prof.buffer, #procedure )
	Memory_App.profiler = prof

	startup_tick := time.tick_now()

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
		// TODO(Ed) : Put on the transient allocator a slab allocator (transient slab)
	}

	state := new( State, persistent_allocator() )
	Memory_App.state = state
	using state

	// Setup Persistent Slab
	{
		alignment := uint(mem.DEFAULT_ALIGNMENT)

		policy_ptr := & default_slab_policy
		if false
		{
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
		}
		else
		{
			push( policy_ptr, SlabSizeClass {  128 * Kilobyte,   1 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {  256 * Kilobyte,   2 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {  512 * Kilobyte,   4 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {    1 * Megabyte,  16 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {    1 * Megabyte,  32 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {    1 * Megabyte,  64 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {    2 * Megabyte, 128 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {    2 * Megabyte, 256 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {    2 * Megabyte, 512 * Kilobyte, alignment })
			push( policy_ptr, SlabSizeClass {    2 * Megabyte,   1 * Megabyte, alignment })
			push( policy_ptr, SlabSizeClass {    2 * Megabyte,   2 * Megabyte, alignment })
			push( policy_ptr, SlabSizeClass {    4 * Megabyte,   4 * Megabyte, alignment })
			push( policy_ptr, SlabSizeClass {    8 * Megabyte,   8 * Megabyte, alignment })
			push( policy_ptr, SlabSizeClass {   16 * Megabyte,  16 * Megabyte, alignment })
			push( policy_ptr, SlabSizeClass {   32 * Megabyte,  32 * Megabyte, alignment })
			push( policy_ptr, SlabSizeClass {   64 * Megabyte,  64 * Megabyte, alignment })
			// push( policy_ptr, SlabSizeClass { 128 * Megabyte, 128 * Megabyte, alignment })
			// push( policy_ptr, SlabSizeClass { 256 * Megabyte, 256 * Megabyte, alignment })
			// push( policy_ptr, SlabSizeClass { 512 * Megabyte, 512 * Megabyte, alignment })
		}

		alloc_error : AllocatorError
		persistent_slab, alloc_error = slab_init( policy_ptr, allocator = persistent_allocator(), dbg_name = Persistent_Slab_DBG_Name )
		verify( alloc_error == .None, "Failed to allocate the persistent slab" )

		transient_slab, alloc_error = slab_init( & default_slab_policy, allocator = transient_allocator(), dbg_name = Transient_Slab_DBG_Name )
		verify( alloc_error == .None, "Failed to allocate transient slab" )

		transient_clear_time = 120 // Seconds, 2 Minutes
	}

	string_cache = str_cache_init()

	input      = & input_data[1]
	input_prev = & input_data[0]

	// Configuration Load
	{
		using config
		resolution_width  = 1000
		resolution_height =  600
		refresh_rate      =    0

		cam_min_zoom                 = 0.25
		cam_max_zoom                 = 30.0
		cam_zoom_mode                = .Smooth
		cam_zoom_smooth_snappiness   = 4.0
		cam_zoom_sensitivity_digital = 0.2
		cam_zoom_sensitivity_smooth  = 4.0

		engine_refresh_hz = 30

		timing_fps_moving_avg_alpha = 0.9

		ui_resize_border_width = 5
	}

	Desired_OS_Scheduler_MS :: 1
	sleep_is_granular = set__scheduler_granularity( Desired_OS_Scheduler_MS )

	// Rough setup of window with rl stuff
	{
		// rl.Odin_SetMalloc( RL_MALLOC )

		rl.SetConfigFlags( {
			rl.ConfigFlag.WINDOW_RESIZABLE,
			// rl.ConfigFlag.WINDOW_TOPMOST,
		})

		window_width  : i32 = cast(i32) config.resolution_width
		window_height : i32 = cast(i32) config.resolution_height
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
		log( str_fmt_tmp( "Set target FPS to: %v", monitor_refresh_hz ) )
	}

	// Basic Font Setup
	{
		font_provider_startup()
		// path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		// font_rec_mono_semicasual_reg  = font_load( path_rec_mono_semicasual_reg, 24.0, "RecMonoSemiCasual_Regular" )

		// path_squidgy_slimes := strings.concatenate( { Path_Assets, "Squidgy Slimes.ttf" } )
		// font_squidgy_slimes = font_load( path_squidgy_slimes, 24.0, "Squidgy_Slime" )

		path_firacode := strings.concatenate( { Path_Assets, "FiraCode-Regular.ttf" }, transient_allocator() )
		font_firacode  = font_load( path_firacode, 24.0, "FiraCode" )
		default_font = font_firacode
		log( "Default font loaded" )
	}

	// Setup the app ui state
	ui_startup( & app_ui, cache_allocator = persistent_slab_allocator() )

	// Demo project setup
	{
		using project
		path           = str_intern("./")
		name           = str_intern( "First Project" )
		workspace.name = str_intern( "First Workspace" )
		{
			using project.workspace
			cam = {
				target   = { 0, 0 },
				offset   = transmute(Vec2) app_window.extent,
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
			ui_startup( & workspace.ui, cache_allocator =  persistent_slab_allocator() )
		}

		debug.path_lorem = str_fmt_alloc("C:/projects/SectrPrototype/examples/Lorem Ipsum.txt", allocator = persistent_slab_allocator())

		alloc_error : AllocatorError; success : bool
		debug.lorem_content, success = os.read_entire_file( debug.path_lorem, persistent_slab_allocator() )

		debug.lorem_parse, alloc_error = pws_parser_parse( transmute(string) 	debug.lorem_content, persistent_slab_allocator() )
		verify( alloc_error == .None, "Faield to parse due to allocation failure" )

		// Render texture test
		debug.viewport_rt = rl.LoadRenderTexture( 1280, 720 )
	}

	startup_ms := duration_ms( time.tick_lap_time( & startup_tick))
	log( str_fmt_tmp("Startup time: %v ms", startup_ms) )

	// Make sure to cleanup transient before continuing...
	// From here on, tarnsinet usage has to be done with care.
	// For most cases, the frame allocator should be more than enough.
}

// For some reason odin's symbols conflict with native foreign symbols...
@export
sectr_shutdown :: proc()
{
	context.logger = to_odin_logger( & Memory_App.logger )

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
reload :: proc( prof : ^SpallProfiler, persistent_mem, frame_mem, transient_mem, files_buffer_mem : ^VArena, host_logger : ^ Logger )
{
	spall.SCOPED_EVENT( & prof.ctx, & prof.buffer, #procedure )
	Memory_App.profiler = prof

	context.logger = to_odin_logger( & Memory_App.logger )
	using Memory_App;

	persistent   = persistent_mem
	frame        = frame_mem
	transient    = transient_mem
	files_buffer = files_buffer_mem

	context.allocator      = persistent_allocator()
	context.temp_allocator = transient_allocator()

	Memory_App.state = get_state()
	using state

	// Procedure Addresses are not preserved on hot-reload. They must be restored for persistent data.
	// The only way to alleviate this is to either do custom handles to allocators
	// Or as done below, correct containers using allocators on reload.
	// Thankfully persistent dynamic allocations are rare, and thus we know exactly which ones they are.

	slab_reload( persistent_slab, persistent_allocator() )

	font_provider_data.font_cache.hashes.backing  = persistent_slab_allocator()
	font_provider_data.font_cache.entries.backing = persistent_slab_allocator()

	slab_reload( string_cache.slab, persistent_allocator() )
	string_cache.table.hashes.backing  = persistent_slab_allocator()
	string_cache.table.entries.backing = persistent_slab_allocator()

	slab_reload( frame_slab, frame_allocator())
	slab_reload( transient_slab, transient_allocator())

	ui_reload( & get_state().project.workspace.ui, cache_allocator =  persistent_slab_allocator() )

	log("Module reloaded")
}

@export
tick :: proc( host_delta_time : f64, host_delta_ns : Duration ) -> b32
{
	profile( "Client Tick" )
	context.logger = to_odin_logger( & Memory_App.logger )
	state := get_state(); using state

	should_close : b32

	client_tick := time.tick_now()
	{
		profile("Work frame")

		// Setup Frame Slab
		{
			alloc_error : AllocatorError
			frame_slab, alloc_error = slab_init( & default_slab_policy, bucket_reserve_num = 0,
				allocator           = frame_allocator(),
				dbg_name            = Frame_Slab_DBG_Name,
				should_zero_buckets = true )
			verify( alloc_error == .None, "Failed to allocate frame slab" )
		}

		context.allocator      = frame_allocator()
		context.temp_allocator = transient_allocator()

		rl.PollInputEvents()

		should_close = update( host_delta_time )
		render()

		rl.SwapScreenBuffer()
	}

	// Timing
	{
		// profile("Client tick timing processing")
		config.engine_refresh_hz = uint(monitor_refresh_hz)
		// config.engine_refresh_hz = 10
		frametime_target_ms          = 1.0 / f64(config.engine_refresh_hz) * S_To_MS
		sub_ms_granularity_required := frametime_target_ms <= Frametime_High_Perf_Threshold_MS

		frametime_delta_ns      = time.tick_lap_time( & client_tick )
		frametime_delta_ms      = duration_ms( frametime_delta_ns )
		frametime_delta_seconds = duration_seconds( frametime_delta_ns )
		frametime_elapsed_ms    = frametime_delta_ms + host_delta_time

		if frametime_elapsed_ms < frametime_target_ms
		{
			sleep_ms       := frametime_target_ms - frametime_elapsed_ms
			pre_sleep_tick := time.tick_now()

			if sleep_ms > 0 {
				thread_sleep( cast(Duration) sleep_ms * MS_To_NS )
				// thread__highres_wait( sleep_ms )
			}

			sleep_delta_ns := time.tick_lap_time( & pre_sleep_tick)
			sleep_delta_ms := duration_ms( sleep_delta_ns )

			if sleep_delta_ms < sleep_ms {
				// log( str_fmt_tmp("frametime sleep was off by: %v ms", sleep_delta_ms - sleep_ms ))
			}

			frametime_elapsed_ms += sleep_delta_ms
			for ; frametime_elapsed_ms < frametime_target_ms; {
				sleep_delta_ns = time.tick_lap_time( & pre_sleep_tick)
				sleep_delta_ms = duration_ms( sleep_delta_ns )

				frametime_elapsed_ms += sleep_delta_ms
			}
		}

		config.timing_fps_moving_avg_alpha = 0.99
		frametime_avg_ms = mov_avg_exp( f64(config.timing_fps_moving_avg_alpha), frametime_elapsed_ms, frametime_avg_ms )
		fps_avg          = 1 / (frametime_avg_ms * MS_To_S)

		if frametime_elapsed_ms > 60.0 {
			log( str_fmt_tmp("Big tick! %v ms", frametime_elapsed_ms), LogLevel.Warning )
		}
	}
	return should_close
}

@export
clean_frame :: proc()
{
	// profile( #procedure)
	state := get_state(); using state
	context.logger = to_odin_logger( & Memory_App.logger )

	free_all( frame_allocator() )

	transient_clear_elapsed += frametime_delta32()
	if transient_clear_elapsed >= transient_clear_time && ! transinet_clear_lock
	{
		transient_clear_elapsed = 0
		free_all( transient_allocator() )

		alloc_error : AllocatorError
		transient_slab, alloc_error = slab_init( & default_slab_policy, allocator = transient_allocator(), dbg_name = Transient_Slab_DBG_Name )
		verify( alloc_error == .None, "Failed to allocate transient slab" )
	}
}
