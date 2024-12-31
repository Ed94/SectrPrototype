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

import sokol_app  "thirdparty:sokol/app"
import sokol_gfx  "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"
import sokol_gp   "thirdparty:sokol/gp"

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
	reload      : type_of( hot_reload ),
	tick        : type_of( tick ),
	clean_frame : type_of( clean_frame ),
}

@export
startup :: proc( prof : ^SpallProfiler, persistent_mem, frame_mem, transient_mem, files_buffer_mem : ^VArena, host_logger : ^Logger )
{
	spall.SCOPED_EVENT( & prof.ctx, & prof.buffer, #procedure )
	// Memory_App.profiler = prof
	set_profiler_module_context( prof )

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
		// alignment := uint(mem.DEFAULT_ALIGNMENT)
		alignment := uint(64)

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
		push( policy_ptr, SlabSizeClass { 128 * Megabyte,  128 * Megabyte, alignment })
		// Anything above 128 meg needs to have its own setup looked into.

		alloc_error : AllocatorError
		persistent_slab, alloc_error = slab_init( policy_ptr, allocator = persistent_allocator(), dbg_name = Persistent_Slab_DBG_Name, enable_mem_tracking = false )
		verify( alloc_error == .None, "Failed to allocate the persistent slab" )

		transient_slab, alloc_error = slab_init( & default_slab_policy, allocator = transient_allocator(), dbg_name = Transient_Slab_DBG_Name )
		verify( alloc_error == .None, "Failed to allocate transient slab" )

		transient_clear_time = 120 // Seconds, 2 Minutes

		string_cache = str_cache_init( persistent_allocator(), persistent_allocator() )
		str_cache_set_module_ctx( & string_cache )
	}

	// Setup input frame poll references
	{
		input      = & input_data[1]
		input_prev = & input_data[0]

		using input_events

		error : AllocatorError
		// events, error  = make( RingBuffer(InputEvent), 4 * Kilo, persistent_allocator(), fixed_cap = true )
		// ensure(error == AllocatorError.None, "Failed to allocate input.events array")

		// key_events, error = make( RingBuffer(InputKeyEvent), Kilo, persistent_allocator(), fixed_cap = true )
		// ensure(error == AllocatorError.None, "Failed to allocate key_events array")

		// mouse_events, error = make( RingBuffer(InputMouseEvent), 3 * Kilo, persistent_allocator(), fixed_cap = true )
		// ensure(error == AllocatorError.None, "Failed to allocate mouse_events array")

		codes_pressed, error = make( Array(rune), Kilo, persistent_slab_allocator() )
		ensure(error == AllocatorError.None, "Failed to allocate codes_pressed array")

		staged_input_events, error = make( Array(InputEvent), 8 * Kilo, persistent_slab_allocator() )
		ensure(error == AllocatorError.None, "Failed to allocate input_staged_events array")
	}

	// Configuration Load
	// TODO(Ed): Make this actually load from an ini
	{
		using config
		resolution_width  = 1000
		resolution_height =  600
		refresh_rate      =    0

		cam_min_zoom                 = 0.025
		cam_max_zoom                 = 5.0
		cam_zoom_mode                = .Digital
		cam_zoom_smooth_snappiness   = 4.0
		cam_zoom_sensitivity_digital = 0.25
		cam_zoom_scroll_delta_scale  = 0.25
		cam_zoom_sensitivity_smooth  = 2.0

		engine_refresh_hz = 0

		timing_fps_moving_avg_alpha = 0.9

		ui_resize_border_width = 5

		color_theme = App_Thm_Dusk

		font_size_screen_scalar = 2.0
		font_size_canvas_scalar = 2.0
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
		window.extent.x = cast(f32) i32(sokol_app.widthf() * 0.5)
		window.extent.y = cast(f32) i32(sokol_app.heightf() * 0.5)

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
		glue_env := sokol_glue.environment()

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

		render_data.pass_actions.bg_clear_black.colors[0] = sokol_gfx.Color_Attachment_Action {
			load_action = .CLEAR,
			clear_value = { 0, 0, 0, 1 }
		}
		render_data.pass_actions.empty_action.colors[0] = sokol_gfx.Color_Attachment_Action {
			load_action = .LOAD,
			clear_value = { 0, 0, 0, 1 }
		}
	}

	// Setup sokol_gp
	{
		desc := sokol_gp.Desc {
			max_vertices = 2 * Mega + 640 * Kilo,
			max_commands = 1 * Mega,
		}
		sokol_gp.setup(desc)
		verify( cast(b32) sokol_gp.is_valid(), "Failed to setup sokol gp (graphics painter)" )
	}

	// Basic Font Setup
	if true
	{
		font_provider_startup( & font_provider_ctx )
		// path_rec_mono_semicasual_reg := strings.concatenate( { Path_Assets, "RecMonoSemicasual-Regular-1.084.ttf" })
		// font_rec_mono_semicasual_reg  = font_load( path_rec_mono_semicasual_reg, 16.0, "RecMonoSemiCasual_Regular" )

		// path_squidgy_slimes := strings.concatenate( { Path_Assets, "Squidgy Slimes.ttf" } )
		// font_squidgy_slimes = font_load( path_squidgy_slimes, 32.0, "Squidgy_Slime" )

		path_firacode := strings.concatenate( { Path_Assets, "FiraCode-Regular.ttf" } )
		font_firacode  = font_load( path_firacode, 16.0, "FiraCode" )
		
		// path_fira_cousine := strings.concatenate( { Path_Assets, "FiraCousine-Regular.ttf" } )
		// font_fira_cousine  = font_load( path_fira_cousine, 16.0, "Fira Cousine" )

		// path_open_sans := strings.concatenate( { Path_Assets, "OpenSans-Regular.ttf" } )
		// font_open_sans  = font_load( path_open_sans, 16.0, "OpenSans" )

		// path_noto_sans := strings.concatenate( { Path_Assets, "NotoSans-Regular.ttf" } )
		// font_noto_sans  = font_load( path_noto_sans, 16.0, "NotoSans" )

		// path_neodgm_code := strings.concatenate( { Path_Assets, "neodgm_code.ttf"} )
		// font_neodgm_code  = font_load( path_neodgm_code, 32.0, "NeoDunggeunmo Code" )

		// path_rec_mono_linear := strings.concatenate( { Path_Assets, "RecMonoLinear-Regular-1.084.ttf" })
		// font_rec_mono_linear  = font_load( path_rec_mono_linear, 16.0, "RecMonoLinear Regular" )

		// path_roboto_regular := strings.concatenate( { Path_Assets, "Roboto-Regular.ttf"} )
		// font_roboto_regular  = font_load( path_roboto_regular, 32.0, "Roboto Regular" )

		// path_arial_unicode_ms := strings.concatenate( { Path_Assets, "Arial Unicode MS.ttf" } )
		// font_arial_unicode_ms  = font_load( path_arial_unicode_ms, 16.0, "Arial_Unicode_MS" )

		// path_arial_unicode_ms := strings.concatenate( { Path_Assets, "Arial Unicode MS.ttf" } )
		// font_arial_unicode_ms  = font_load( path_arial_unicode_ms, 16.0, "Arial_Unicode_MS" )

		default_font = font_firacode
		log( "Default font loaded" )
	}

	// Setup the screen ui state
	if true
	{
		profile("screen ui")

		ui_startup( & screen_ui.base, cache_allocator = persistent_slab_allocator() )
		ui_floating_startup( & screen_ui.floating, 1 * Kilobyte, 1 * Kilobyte, persistent_slab_allocator(), "screen ui floating manager" )

		using screen_ui
		menu_bar.pos  = { -260, -200 }
		// menu_bar.pos  = Vec2(app_window.extent) * { -1, 1 }
		menu_bar.size = {240, 40}

		logger_scope.min_size  = {360, 200}
		settings_menu.min_size = {360, 200}
	}

	// Demo project setup
	// TODO(Ed): This will eventually have to occur when the user either creates or loads a workspace.
	if true
	{
		profile("project setup")
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

		// debug.path_lorem = str_fmt("C:/projects/SectrPrototype/examples/Lorem Ipsum (197).txt", allocator = persistent_slab_allocator())
		// debug.path_lorem = str_fmt("C:/projects/SectrPrototype/examples/Lorem Ipsum (1022).txt", allocator = persistent_slab_allocator())
		debug.path_lorem = str_fmt("C:/projects/SectrPrototype/examples/sokol_gp.h", allocator = persistent_slab_allocator())
		// debug.path_lorem = str_fmt("C:/projects/SectrPrototype/examples/ve_fontcache.h", allocator = persistent_slab_allocator())

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

	font_provider_shutdown( & state.font_provider_ctx )

	sokol_gp.shutdown()
	sokol_gfx.shutdown()
	sokol_app.post_client_cleanup()

	log("Module shutdown complete")
}

@export
hot_reload :: proc( prof : ^SpallProfiler, persistent_mem, frame_mem, transient_mem, files_buffer_mem : ^VArena, host_logger : ^ Logger )
{
	spall.SCOPED_EVENT( & prof.ctx, & prof.buffer, #procedure )
	set_profiler_module_context( prof )

	context.logger = to_odin_logger( & Memory_App.logger )
	{
		using Memory_App;

		persistent   = persistent_mem
		frame        = frame_mem
		transient    = transient_mem
		files_buffer = files_buffer_mem
	}
	context.allocator      = transient_allocator()
	context.temp_allocator = transient_allocator()

	Memory_App.state = get_state()
	using Memory_App.state

	sokol_context = context

	Sokol:
	{
		desc_app := sokol_app.DescReload {
			init_cb    = sokol_app_init_callback,
			frame_cb   = sokol_app_frame_callback,
			cleanup_cb = sokol_app_cleanup_callback,
			event_cb   = sokol_app_event_callback,

			logger    = { sokol_app_log_callback, nil },
			allocator = { sokol_app_alloc, sokol_app_free, nil },
		}
		sokol_app.client_reload( desc_app )

		desc_gfx := sokol_gfx.DescReload {
			allocator = { sokol_gfx_alloc, sokol_gfx_free, nil },
			logger    = { sokol_gfx_log_callback, nil },
		}
		sokol_gfx.client_reload( desc_gfx )
	}

	// Procedure Addresses are not preserved on hot-reload. They must be restored for persistent data.
	// The only way to alleviate this is to either do custom handles to allocators
	// Or as done below, correct containers using allocators on reload.
	// Thankfully persistent dynamic allocations are rare, and thus we know exactly which ones they are.

	slab_reload( persistent_slab, persistent_allocator() )

	// input_reload()
	{
		using input_events
		// reload( & events, runtime.nil_allocator())
		// reload( & key_events, runtime.nil_allocator())
		// reload( & mouse_events, runtime.nil_allocator())
		codes_pressed.backing       = persistent_slab_allocator()
		staged_input_events.backing = persistent_slab_allocator()
	}

	font_provider_reload( & font_provider_ctx )

	str_cache_reload( & string_cache, persistent_allocator(), persistent_allocator() )
	str_cache_set_module_ctx( & string_cache )

	slab_reload( frame_slab, frame_allocator())
	slab_reload( transient_slab, transient_allocator())

	ui_reload( & get_state().project.workspace.ui, cache_allocator =  persistent_slab_allocator() )

	log("Module reloaded")
}

Frametime_High_Perf_Threshold_MS :: 1 / 240.0

@export
tick :: proc( host_delta_time_ms : f64, host_delta_ns : Duration ) -> b32
{
	should_close : b32

	profile_begin("sokol_app: pre_client_tick")
	should_close |= cast(b32) sokol_app.pre_client_frame()
	profile_end()

	profile_begin( "Client Tick" )
	context.logger = to_odin_logger( & Memory_App.logger )
	state := get_state(); using state
	client_tick := time.tick_now()
	should_close |= tick_work_frame( host_delta_time_ms)
	profile_end()

	profile_begin("sokol_app: post_client_tick")
	sokol_app.post_client_frame()
	profile_end()

	tick_frametime( & client_tick, host_delta_time_ms, host_delta_ns )
	return ! should_close
}

// Lifted out of tick so that sokol_app_frame_callback can do it as well.
tick_work_frame :: #force_inline proc( host_delta_time_ms : f64 ) -> b32
{
	profile("Work frame")
	context.logger = to_odin_logger( & Memory_App.logger )
	should_close : b32

	// Setup Frame Slab
	alloc_error : AllocatorError
	get_state().frame_slab, alloc_error = slab_init( & get_state().default_slab_policy, bucket_reserve_num = 0,
		allocator           = frame_allocator(),
		dbg_name            = Frame_Slab_DBG_Name,
		should_zero_buckets = true )
	verify( alloc_error == .None, "Failed to allocate frame slab" )

	// The policy for the work tick is that the default allocator is the frame's slab.
	// Transient's is the temp allocator.
	context.allocator      = frame_slab_allocator()
	context.temp_allocator = transient_allocator()

	// rl.PollInputEvents()

	config := & get_state().config
	debug  := & get_state().debug

	debug.draw_ui_box_bounds_points = false
	debug.draw_ui_padding_bounds    = false
	debug.draw_ui_content_bounds    = false

	// config.engine_refresh_hz = 165

	// config.color_theme = App_Thm_Light
	// config.color_theme = App_Thm_Dusk
	config.color_theme = App_Thm_Dark

	sokol_width  := sokol_app.widthf()
	sokol_height := sokol_app.heightf()

	window := & get_state().app_window
	// if	int(window.extent.x) != int(sokol_width) || int(window.extent.y) != int(sokol_height) {
		window.resized = true
		window.extent.x = sokol_width  * 0.5
		window.extent.y = sokol_height * 0.5
		// log("sokol_app: Event-based frame callback triggered (detected a resize")
	// }

	should_close |= update( host_delta_time_ms )
	render()

	// rl.SwapScreenBuffer()
	return should_close
}

// Lifted out of tick so that sokol_app_frame_callback can do it as well.
tick_frametime :: #force_inline proc( client_tick : ^time.Tick, host_delta_time_ms : f64, host_delta_ns : Duration, can_sleep := true )
{
	profile(#procedure)
	config    := app_config()
	frametime := & get_state().frametime
	context.allocator      = frame_slab_allocator()
	context.temp_allocator = transient_allocator()

	// profile("Client tick timing processing")

	frametime.target_ms          = 1.0 / f64(config.engine_refresh_hz) * S_To_MS
	sub_ms_granularity_required := frametime.target_ms <= Frametime_High_Perf_Threshold_MS

	frametime.delta_ns      = time.tick_lap_time( client_tick )
	frametime.delta_ms      = duration_ms( frametime.delta_ns )
	frametime.delta_seconds = duration_seconds( host_delta_ns )
	frametime.elapsed_ms    = frametime.delta_ms + host_delta_time_ms

	if frametime.elapsed_ms < frametime.target_ms
	{
		sleep_ms       := frametime.target_ms - frametime.elapsed_ms
		pre_sleep_tick := time.tick_now()

		if can_sleep && sleep_ms > 0 {
			// thread_sleep( cast(Duration) sleep_ms * MS_To_NS )
			// thread__highres_wait( sleep_ms )
		}

		sleep_delta_ns := time.tick_lap_time( & pre_sleep_tick)
		sleep_delta_ms := duration_ms( sleep_delta_ns )

		if sleep_delta_ms < sleep_ms {
			// log( str_fmt_tmp("frametime sleep was off by: %v ms", sleep_delta_ms - sleep_ms ))
		}

		frametime.elapsed_ms += sleep_delta_ms
		for ; frametime.elapsed_ms < frametime.target_ms; {
			sleep_delta_ns = time.tick_lap_time( & pre_sleep_tick)
			sleep_delta_ms = duration_ms( sleep_delta_ns )

			frametime.elapsed_ms += sleep_delta_ms
		}
	}

	config.timing_fps_moving_avg_alpha = 0.99
	frametime.avg_ms  = mov_avg_exp( f64(config.timing_fps_moving_avg_alpha), frametime.elapsed_ms, frametime.avg_ms )
	frametime.fps_avg = 1 / (frametime.avg_ms * MS_To_S)

	if frametime.elapsed_ms > 60.0 {
		log( str_fmt("Big tick! %v ms", frametime.elapsed_ms), LogLevel.Warning )
	}

	frametime.current_frame += 1
}

@export
clean_frame :: proc()
{
	profile( #procedure)
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
