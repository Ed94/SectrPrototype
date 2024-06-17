package sectr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

Str_App_State := "App State"

#region("Memory")

Memory_App : Memory

Memory_Base_Address_Persistent   :: Terabyte * 1
Memory_Base_Address_Frame        :: Memory_Base_Address_Persistent + Memory_Reserve_Persistent * 2
Memory_Base_Address_Transient    :: Memory_Base_Address_Frame      + Memory_Reserve_Frame * 2
Memory_Base_Address_Files_Buffer :: Memory_Base_Address_Transient  + Memory_Reserve_Transient * 2

// This reserve goes beyond the typical amount of ram the user has,
// TODO(Ed): Setup warnings when the amount is heading toward half the ram size
Memory_Reserve_Persistent  :: 32 * Gigabyte
Memory_Reserve_Frame       :: 16 * Gigabyte
Memory_Reserve_Transient   :: 16 * Gigabyte
Memory_Reserve_FilesBuffer :: 64 * Gigabyte

Memory_Commit_Initial_Persistent :: 4 * Kilobyte
Memory_Commit_Initial_Frame      :: 4 * Kilobyte
Memory_Commit_Initial_Transient  :: 4 * Kilobyte
Memory_Commit_Initial_Filebuffer :: 4 * Kilobyte

MemorySnapshot :: struct {
	persistent   : []u8,
	frame        : []u8,
	transient    : []u8,
	// files_buffer cannot be restored from snapshot
}

Memory :: struct {
	persistent   : ^VArena,
	frame        : ^VArena,
	transient    : ^VArena,
	files_buffer : ^VArena,

	state   : ^State,

	// Should only be used for small memory allocation iterations
	// Not for large memory env states
	snapshot : MemorySnapshot,

	replay   : ReplayState,
	logger   : Logger,
	profiler : ^SpallProfiler
}

persistent_allocator :: proc() -> Allocator {
	result := varena_allocator( Memory_App.persistent )
	return result
}

frame_allocator :: proc() -> Allocator {
	result := varena_allocator( Memory_App.frame )
	return result
}

transient_allocator :: proc() -> Allocator {
	result := varena_allocator( Memory_App.transient )
	return result
}

files_buffer_allocator :: proc() -> Allocator {
	result := varena_allocator( Memory_App.files_buffer )
	return result
}

persistent_slab_allocator :: proc() -> Allocator {
	state := get_state()
	result := slab_allocator( state.persistent_slab )
	return result
}

frame_slab_allocator :: proc() -> Allocator {
	result := slab_allocator( get_state().frame_slab )
	return result
}

transient_slab_allocator :: proc() -> Allocator {
	result := slab_allocator( get_state().transient_slab )
	return result
}

// TODO(Ed) : Implment host memory mapping api
save_snapshot :: proc( snapshot : ^MemorySnapshot )
{
	// Make sure the snapshot size is able to hold the current size of the arenas
	// Grow the files & mapping otherwise
	{
		// TODO(Ed) : Implement eventually
	}

	persistent := Memory_App.persistent
	mem.copy_non_overlapping( & snapshot.persistent[0], persistent.reserve_start, int(persistent.commit_used) )

	frame := Memory_App.frame
	mem.copy_non_overlapping( & snapshot.frame[0], frame.reserve_start, int(frame.commit_used) )

	transient := Memory_App.transient
	mem.copy_non_overlapping( & snapshot.transient[0], transient.reserve_start, int(transient.commit_used) )
}

// TODO(Ed) : Implment host memory mapping api
load_snapshot :: proc( snapshot : ^MemorySnapshot ) {
	persistent := Memory_App.persistent
	mem.copy_non_overlapping( persistent.reserve_start, & snapshot.persistent[0], int(persistent.commit_used) )

	frame := Memory_App.frame
	mem.copy_non_overlapping( frame.reserve_start, & snapshot.frame[0], int(frame.commit_used) )

	transient := Memory_App.transient
	mem.copy_non_overlapping( transient.reserve_start, & snapshot.transient[0], int(transient.commit_used) )
}

// TODO(Ed) : Implement usage of this
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

#endregion("Memory")

#region("State")

// ALl nobs available for this application
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

	engine_refresh_hz : uint,

	timing_fps_moving_avg_alpha : f32,

	ui_resize_border_width : f32,

	color_theme : AppColorTheme,
}

AppWindow :: struct {
	extent    : Extents2, // Window half-size
	dpi_scale : f32,      // Dots per inch scale (provided by raylib via glfw)
	ppcm      : f32,      // Dots per centimetre
	resized   : b32,      // Extent changed this frame
}

FontData :: struct {
	provider : FontProviderData,

	// TODO(Ed): We can have font constants here I guess but eventually
	// I rather have fonts configurable for a 'theme' combo
	// So that way which IDs are picked depends on runtime
	firacode                : FontID,
	squidgy_slimes          : FontID,
	rec_mono_semicasual_reg : FontID,

	default_font            : FontID,
}

FrameTime :: struct {
	sleep_is_granular : b32,

	delta_seconds : f64,
	delta_ms      : f64,
	delta_ns      : Duration,
	target_ms     : f64,
	elapsed_ms    : f64,
	avg_ms        : f64,
	fps_avg       : f64,
}

// Global Singleton stored in the persistent virtual arena, the first allocated data.
// Use get_state() to conviently retrieve at any point for the program's lifetime
State :: struct {
	default_slab_policy     : SlabPolicy,
	persistent_slab         : Slab,
	frame_slab              : Slab,
	transient_slab          : Slab, // TODO(Ed): This needs to be recreated per transient wipe
	transinet_clear_lock    : b32,  // Pravents auto-free of transient at designated intervals
	transient_clear_time    : f32,  // Time in seconds for the usual period to clear transient
	transient_clear_elapsed : f32,  // Time since last clear

	string_cache : StringCache,

	input_data : [2]InputState,
	input_prev : ^InputState,
	input      : ^InputState,

	// Note(Ed): Do not modify directly, use its interface in app/event.odin
	staged_input_events : Array(InputEvent),
	// TODO(Ed): Add a multi-threaded guard for accessing or mutating staged_input_events.

	debug  : DebugData,

	project : Project,

	config     : AppConfig,
	app_window : AppWindow,
	screen_ui  : UI_ScreenState,

	render_data : RenderState,

	monitor_id         : i32,
	monitor_refresh_hz : i32,

	// using frametime : FrameTime,
	sleep_is_granular : b32,

	frame                   : u64,
	frametime_delta_seconds : f64,
	frametime_delta_ms      : f64,
	frametime_delta_ns      : Duration,
	frametime_target_ms     : f64,
	frametime_elapsed_ms    : f64,
	frametime_avg_ms        : f64,
	fps_avg                 : f64,

	// fonts : FontData,
	font_provider_data : FontProviderData,

	font_arial_unicode_ms        : FontID,
	font_firacode                : FontID,
	font_noto_sans               : FontID,
	font_open_sans               : FontID,
	font_squidgy_slimes          : FontID,
	font_rec_mono_semicasual_reg : FontID,
	default_font                 : FontID,


	// Context tracking
	// These are used as implicit contextual states when doing immediate mode interfaces
	// or for event callbacks that need their context assigned

	// There are two potential UI contextes for this prototype so far,
	// the screen-space UI and the current workspace UI.
	// This is used so that the ui api doesn't need to have the user pass the context through every proc.
	ui_context          : ^UI_State,
	ui_floating_context : ^UI_FloatingManager,

	// The camera is considered the "context" for coodrinate space operations in rendering
	cam_context : Camera,

	sokol_frame_count : i64,
	sokol_context     : runtime.Context,
}

get_state :: #force_inline proc "contextless" () -> ^ State {
	return cast( ^ State ) Memory_App.persistent.reserve_start
}

// get_frametime :: #force_inline proc "contextless" () -> FrameTime {
// 	return get_state().frametime
// }

app_config      :: #force_inline proc "contextless" () -> AppConfig     { return get_state().config }
app_color_theme :: #force_inline proc "contextless" () -> AppColorTheme { return get_state().config.color_theme }

#endregion("State")
