package sectr

//region STATIC MEMORY
// This should be the only global on client module side.
@(private)               memory: ^ProcessMemory
@(private, thread_local) thread: ^ThreadMemory
//endregion STATIC MEMORy

MemoryConfig :: struct {
	reserve_persistent : uint,
	reserve_frame      : uint,
	reserve_transient  : uint,
	reserve_filebuffer : uint,

	commit_initial_persistent : uint,
	commit_initial_frame      : uint,
	commit_initial_transient  : uint,
	commit_initial_filebuffer : uint,
}

// All nobs available for this application
AppConfig :: struct {
	using memory : MemoryConfig,

	resolution_width  : uint,
	resolution_height : uint,
	refresh_rate      : uint,

	cam_min_zoom                 : f32,
	cam_max_zoom                 : f32,
	cam_zoom_mode                : CameraZoomMode,
	cam_zoom_smooth_snappiness   : f32,
	cam_zoom_sensitivity_smooth  : f32,
	cam_zoom_sensitivity_digital : f32,
	cam_zoom_scroll_delta_scale  : f32,

	engine_refresh_hz : uint,

	timing_fps_moving_avg_alpha : f32,

	ui_resize_border_width : f32,

	// color_theme : AppColorTheme,

	text_snap_glyph_shape_position : b32,
	text_snap_glyph_render_height  : b32,
	text_size_screen_scalar        : f32,
	text_size_canvas_scalar        : f32,
	text_alpha_sharpen             : f32,
}

AppWindow :: struct {
	extent:    Extents2_F4, // Window half-size
	dpi_scale: f32,         // Dots per inch scale (provided by raylib via glfw)
	ppcm:      f32,         // Dots per centimetre
	resized:   b32,         // Extent changed this frame
}

FrameTime :: struct {
	sleep_is_granular : b32,

	current_frame : u64,
	delta_seconds : f64,
	delta_ms      : f64,
	delta_ns      : Duration,
	target_ms     : f64,
	elapsed_ms    : f64,
	avg_ms        : f64,
	fps_avg       : f64,
}

State :: struct {
	sokol_frame_count: i64,
	sokol_context:     Context,

	config:     AppConfig,
	app_window: AppWindow,

	logger: Logger,

	// Overall frametime of the tick frame (currently main thread's)
	using frametime : FrameTime,


	input_data : [2]InputState,
	input_prev : ^InputState,
	input      : ^InputState, // TODO(Ed): Rename to indicate its the device's signal state for the frame?

	input_events:      InputEvents,
	input_binds_stack: Array(InputContext),

	// Note(Ed): Do not modify directly, use its interface in app/event.odin
	staged_input_events : Array(InputEvent),
	// TODO(Ed): Add a multi-threaded guard for accessing or mutating staged_input_events.
}

ThreadState :: struct {
	

	// Frametime
	delta_seconds: f64,
	delta_ms:      f64,
	delta_ns:      Duration,
	target_ms:     f64, // NOTE(Ed): This can only be used on job worker threads.
	elapsed_ms:    f64,
	avg_ms:        f64,
}

app_config    :: #force_inline proc "contextless" () -> AppConfig     { return memory.client_memory.config }
get_frametime :: #force_inline proc "contextless" () -> FrameTime     { return memory.client_memory.frametime }
// get_state     :: #force_inline proc "contextless" () -> ^State        { return memory.client_memory }

get_input_binds       :: #force_inline proc "contextless" () ->   InputContext { return array_back    (memory.client_memory.input_binds_stack) }
get_input_binds_stack :: #force_inline proc "contextless" () -> []InputContext { return array_to_slice(memory.client_memory.input_binds_stack) }
