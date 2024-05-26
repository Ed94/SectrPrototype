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

import sokol_app          "thirdparty:sokol/app"
import sokol_gfx          "thirdparty:sokol/gfx"
import sokol_app_gfx_glue "thirdparty:sokol/glue"

Path_Assets       :: "../assets/"
Path_Shaders      :: "../shaders/"
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

		// The policy for startup & any other persistent scopes is that the default allocator is transient.
		// Any persistent allocations are explicitly specified.
		context.allocator      = transient_allocator()
		context.temp_allocator = transient_allocator()
	}

	state := new( State, persistent_allocator() )
	Memory_App.state = state
	using state

	// Setup Persistent Slabs & String Cache
	{
		alignment := uint(mem.DEFAULT_ALIGNMENT)

		policy_ptr := & default_slab_policy
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

		alloc_error : AllocatorError
		persistent_slab, alloc_error = slab_init( policy_ptr, allocator = persistent_allocator(), dbg_name = Persistent_Slab_DBG_Name )
		verify( alloc_error == .None, "Failed to allocate the persistent slab" )

		transient_slab, alloc_error = slab_init( & default_slab_policy, allocator = transient_allocator(), dbg_name = Transient_Slab_DBG_Name )
		verify( alloc_error == .None, "Failed to allocate transient slab" )

		transient_clear_time = 120 // Seconds, 2 Minutes

		string_cache = str_cache_init()
	}

	// Setup input frame poll references
	{
		input      = & input_data[1]
		input_prev = & input_data[0]
		for & input in input_data {
			using input
			error : AllocatorError
			keyboard_events.keys_pressed, error  = array_init_reserve(KeyCode, persistent_slab_allocator(), Kilo)
			ensure(error == AllocatorError.None, "Failed to allocate input.keyboard_events.keys_pressed array")
			keyboard_events.chars_pressed, error = array_init_reserve(rune, persistent_slab_allocator(), Kilo)
			ensure(error == AllocatorError.None, "Failed to allocate input.keyboard_events.chars_pressed array")
		}
	}

	// Configuration Load
	// TODO(Ed): Make this actually load from an ini
	{
		using config
		resolution_width  = 1000
		resolution_height =  600
		refresh_rate      =    0

		cam_min_zoom                 = 0.10
		cam_max_zoom                 = 30.0
		cam_zoom_mode                = .Smooth
		cam_zoom_smooth_snappiness   = 4.0
		cam_zoom_sensitivity_digital = 0.2
		cam_zoom_sensitivity_smooth  = 4.0

		engine_refresh_hz = 0

		timing_fps_moving_avg_alpha = 0.9

		ui_resize_border_width = 5

		color_theme = App_Thm_Dusk
	}

	Desired_OS_Scheduler_MS :: 1
	sleep_is_granular = set__scheduler_granularity( Desired_OS_Scheduler_MS )

	// Setup for sokol_app
	{
		sokol_context = context
		desc := sokol_app.Desc {
			init_cb    = sokol_app_init_callback,
			frame_cb   = sokol_app_frame_callback,
			cleanup_cb = sokol_app_cleanup_callback,
			event_cb   = sokol_app_event_callback,

			width  = cast(c.int) config.resolution_width,
			height = cast(c.int) config.resolution_height,

			sample_count     = 0,
			// swap_interval = config.monitor_refresh_hz,

			high_dpi     = false,
			fullscreen   = false,
			alpha        = false,

			window_title = "Sectr Prototype",
			// icon = { sokol_app.sokol_default },

			enable_clipboard = false, // TODO(Ed): Implmeent this
			enable_dragndrop = false, // TODO(Ed): Implmeent this

			logger    = { sokol_app_log_callback, nil },
			allocator = { sokol_app_alloc, sokol_app_free, nil },
		}

		sokol_app.pre_client_init(desc)
		sokol_app.client_init()

		window := & state.app_window
		window.extent.x = sokol_app.widthf()
		window.extent.y = sokol_app.heightf()

		// TODO(Ed): We don't need monitor tracking until we have multi-window support (which I don't think I'll do for this prototype)
		// Sokol doesn't provide it.
		// config.current_monitor    = sokol_app.monitor_id()
		monitor_refresh_hz = sokol_app.refresh_rate()

		// if config.engine_refresh_hz == 0 {
		// 	config.engine_refresh_hz = sokol_app.frame_duration()
		// }
		if config.engine_refresh_hz == 0 {
			config.engine_refresh_hz = uint(monitor_refresh_hz)
		}
	}

	// Setup sokol_gfx
	{
		glue_env := sokol_app_gfx_glue.environment()

		desc := sokol_gfx.Desc {
			buffer_pool_size      = 128,
			image_pool_size       = 128,
			sampler_pool_size     = 64,
			shader_pool_size      = 32,
			pipeline_pool_size    = 64,
			// pass_pool_size       = 16, // (No longer exists)
			attachments_pool_size = 16,
			uniform_buffer_size   = 4 * Megabyte,
			max_commit_listeners  = Kilo,
			allocator             = { sokol_gfx_alloc, sokol_gfx_free, nil },
			logger                = { sokol_gfx_log_callback, nil },
			environment           = glue_env,
		}
		sokol_gfx.setup(desc)

		backend := sokol_gfx.query_backend()
		switch backend
		{
        case .D3D11:          logf("sokol_gfx: using D3D11 backend")
        case .GLCORE, .GLES3: logf("sokol_gfx: using GL backend")

        case .METAL_MACOS, .METAL_IOS, .METAL_SIMULATOR:
        	logf("sokol_gfx: using Metal backend")

        case .WGPU:  logf("sokol_gfx: using WebGPU backend")
        case .DUMMY: logf("sokol_gfx: using dummy backend")
		}

		// Learning examples
		{

			debug.gfx_clear_demo_pass_action.colors[0] = {
				load_action = .CLEAR,
				clear_value = { 1, 0, 0, 1 }
			}
			vertices := [?]f32 {
	      // positions      // colors
	       0.0,  0.5, 0.5,  1.0, 0.0, 0.0, 1.0,
	       0.5, -0.5, 0.5,  0.0, 1.0, 0.0, 1.0,
	      -0.5, -0.5, 0.5,  0.0, 0.0, 1.0, 1.0,
	    }

    	tri_shader_attr_vs_position :: 0
			tri_shader_attr_vs_color0   :: 1

	    using debug.gfx_tri_demo_state
	    bindings.vertex_buffers[0] = sokol_gfx.make_buffer( sokol_gfx.Buffer_Desc {
	    	data = {
	    		ptr  = & vertices,
		    	size = size_of(vertices)
	    	}
	    })
	    pipeline = sokol_gfx.make_pipeline( sokol_gfx.Pipeline_Desc {
	    	shader = sokol_gfx.make_shader( triangle_shader_desc(backend)),
	    	layout = sokol_gfx.Vertex_Layout_State {
	    		attrs = {
	    			tri_shader_attr_vs_position = { format = .FLOAT3 },
	    			tri_shader_attr_vs_color0   = { format = .FLOAT4 },
	    		}
	    	}
	    })
	    pass_action.colors[0] = {
    		load_action = .CLEAR,
    		clear_value = { 0, 0, 0, 1 }
	    }
		}
	}

	// Basic Font Setup
	if false
	{
		font_provider_startup()
		// path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		// font_rec_mono_semicasual_reg  = font_load( path_rec_mono_semicasual_reg, 24.0, "RecMonoSemiCasual_Regular" )

		// path_squidgy_slimes := strings.concatenate( { Path_Assets, "Squidgy Slimes.ttf" } )
		// font_squidgy_slimes = font_load( path_squidgy_slimes, 24.0, "Squidgy_Slime" )

		path_firacode := strings.concatenate( { Path_Assets, "FiraCode-Regular.ttf" } )
		font_firacode  = font_load( path_firacode, 24.0, "FiraCode" )
		default_font = font_firacode
		log( "Default font loaded" )
	}

	// Setup the screen ui state
	if true
	{
		ui_startup( & screen_ui.base, cache_allocator = persistent_slab_allocator() )
		ui_floating_startup( & screen_ui.floating, persistent_slab_allocator(), 1 * Kilobyte, 1 * Kilobyte, "screen ui floating manager" )

		using screen_ui
		menu_bar.pos  = { -60, 0 }
		// menu_bar.pos  = Vec2(app_window.extent) * { -1, 1 }
		menu_bar.size = {140, 40}

		settings_menu.min_size = {250, 200}
	}

	// Demo project setup
	// TODO(Ed): This will eventually have to occur when the user either creates or loads a workspace. I don't know 
	if true
	{
		using project
		path           = str_intern("./")
		name           = str_intern( "First Project" )
		workspace.name = str_intern( "First Workspace" )
		{
			using project.workspace
			cam = {
				position = { 0, 0 },
				view     = transmute(Vec2) app_window.extent,
				// rotation = 0,
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

		debug.path_lorem = str_fmt("C:/projects/SectrPrototype/examples/Lorem Ipsum.txt", allocator = persistent_slab_allocator())

		alloc_error : AllocatorError; success : bool
		debug.lorem_content, success = os.read_entire_file( debug.path_lorem, persistent_slab_allocator() )

		debug.lorem_parse, alloc_error = pws_parser_parse( transmute(string) 	debug.lorem_content, persistent_slab_allocator() )
		verify( alloc_error == .None, "Faield to parse due to allocation failure" )

		// Render texture test
		// debug.viewport_rt = rl.LoadRenderTexture( 1280, 720 )

		// debug.proto_text_shader = rl.LoadShader( "C:/projects/SectrPrototype/code/shaders/text_shader.vs", "C:/projects/SectrPrototype/code/shaders/text_shader.fs" )
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

	// font_provider_shutdown()

	sokol_app.post_client_cleanup()

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

	// hmap_chained_reload( font_provider_data.font_cache, persistent_allocator())

	slab_reload( string_cache.slab, persistent_allocator() )
	zpl_hmap_reload( & string_cache.table, persistent_slab_allocator())

	slab_reload( frame_slab, frame_allocator())
	slab_reload( transient_slab, transient_allocator())

	ui_reload( & get_state().project.workspace.ui, cache_allocator =  persistent_slab_allocator() )

	log("Module reloaded")
}

@export
tick :: proc( host_delta_time_ms : f64, host_delta_ns : Duration ) -> b32
{
	should_close : b32

	profile_begin("sokol_app: pre_client_tick")
	should_close |= cast(b32) sokol_app.pre_client_frame()
	profile_end()

	profile( "Client Tick" )
	context.logger = to_odin_logger( & Memory_App.logger )
	state := get_state(); using state

	client_tick := time.tick_now()
	should_close |= tick_work_frame( host_delta_time_ms)
	tick_frametime( & client_tick, host_delta_time_ms, host_delta_ns )

	profile_begin("sokol_app: post_client_tick")
	sokol_app.post_client_frame()
	profile_end()
	return ! should_close
}


// Lifted out of tick so that sokol_app_frame_callback can do it as well.
tick_work_frame :: #force_inline proc( host_delta_time_ms : f64 ) -> b32
{
	context.logger = to_odin_logger( & Memory_App.logger )
	state := get_state(); using state
	profile("Work frame")

	should_close : b32

	// Setup Frame Slab
	{
		alloc_error : AllocatorError
		frame_slab, alloc_error = slab_init( & default_slab_policy, bucket_reserve_num = 0,
			allocator           = frame_allocator(),
			dbg_name            = Frame_Slab_DBG_Name,
			should_zero_buckets = true )
		verify( alloc_error == .None, "Failed to allocate frame slab" )
	}

	// The policy for the work tick is that the default allocator is the frame's slab.
	// Transient's is the temp allocator.
	context.allocator      = frame_slab_allocator()
	context.temp_allocator = transient_allocator()

	// rl.PollInputEvents()

	debug.draw_ui_box_bounds_points = false
	debug.draw_UI_padding_bounds = false
	debug.draw_ui_content_bounds = false

	// config.color_theme = App_Thm_Light
	// config.color_theme = App_Thm_Dusk
	config.color_theme = App_Thm_Dark

	should_close |= update( host_delta_time_ms )
	render()

	// rl.SwapScreenBuffer()
	return should_close
}

// Lifted out of tick so that sokol_app_frame_callback can do it as well.
tick_frametime :: #force_inline proc( client_tick : ^time.Tick, host_delta_time_ms : f64, host_delta_ns : Duration )
{
	state := get_state(); using state
	context.allocator      = frame_slab_allocator()
	context.temp_allocator = transient_allocator()

	// profile("Client tick timing processing")
	// config.engine_refresh_hz = uint(monitor_refresh_hz)
	// config.engine_refresh_hz = 6
	frametime_target_ms          = 1.0 / f64(config.engine_refresh_hz) * S_To_MS
	sub_ms_granularity_required := frametime_target_ms <= Frametime_High_Perf_Threshold_MS

	frametime_delta_ns      = time.tick_lap_time( client_tick )
	frametime_delta_ms      = duration_ms( frametime_delta_ns )
	frametime_delta_seconds = duration_seconds( host_delta_ns )
	frametime_elapsed_ms    = frametime_delta_ms + host_delta_time_ms

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
		log( str_fmt("Big tick! %v ms", frametime_elapsed_ms), LogLevel.Warning )
	}
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