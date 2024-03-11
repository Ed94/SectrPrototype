package sectr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import rl "vendor:raylib"

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

	// Should only be used for small memory allocation iterations
	// Not for large memory env states
	snapshot : MemorySnapshot,

	replay : ReplayState,
	logger : Logger,
}

persistent_allocator :: proc() -> Allocator {
	return varena_allocator( Memory_App.persistent )
}

frame_allocator :: proc() -> Allocator {
	return varena_allocator( Memory_App.frame )
}

transient_allocator :: proc() -> Allocator {
	return varena_allocator( Memory_App.transient )
}

files_buffer_allocator :: proc() -> Allocator {
	return varena_allocator( Memory_App.files_buffer )
}

persistent_slab_allocator :: proc() -> Allocator {
	return slab_allocator( get_state().persistent_slab )
}

frame_slab_allocator :: proc() -> Allocator {
	return slab_allocator( get_state().frame_slab )
}

transient_slab_allocator :: proc() -> Allocator {
	return slab_allocator( get_state().transient_slab )
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

	ui_resize_border_width : f32,
}

State :: struct {
	default_slab_policy     : SlabPolicy,
	persistent_slab         : Slab,
	frame_slab              : Slab,
	transient_slab          : Slab, // TODO(Ed): This needs to be recreated per transient wipe
	transinet_clear_lock    : b32,  // Pravents auto-free of transient at designated intervals
	transient_clear_time    : f32,  // Time in seconds for the usual period to clear transient
	transient_clear_elapsed : f32,  // Time since last clear

	string_cache : StringCache,

	font_provider_data : FontProviderData,

	input_data : [2]InputState,
	input_prev : ^InputState,
	input      : ^InputState,

	debug  : DebugData,

	project : Project,

	config     : AppConfig,
	app_window : AppWindow,

	monitor_id         : i32,
	monitor_refresh_hz : i32,

	sleep_is_granular : b32,

	frametime_delta_seconds   : f64,
	frametime_delta_ms        : f64,
	frametime_delta_ns        : Duration,
	frametime_target_ms       : f64,

	frametime_elapsed_ms  : f64,

	font_firacode                : FontID,
	font_squidgy_slimes          : FontID,
	font_rec_mono_semicasual_reg : FontID,
	default_font                 : FontID,

	// There are two potential UI contextes for this prototype so far,
	// the screen-space UI and the current workspace UI.
	// This is used so that the ui api doesn't need to have the user pass the context every single time.
	ui_context : ^UI_State,
}

get_state :: proc "contextless" () -> ^ State {
	return cast( ^ State ) Memory_App.persistent.reserve_start
}

AppWindow :: struct {
	extent    : Extents2, // Window half-size
	dpi_scale : f32,      // Dots per inch scale (provided by raylib via glfw)
	ppcm      : f32,      // Dots per centimetre
}

// PMDB
CodeBase :: struct {
	placeholder : int,
}

ProjectConfig :: struct {
	placeholder : int,
}

Project :: struct {
	path : StringCached,
	name : StringCached,

	config   : ProjectConfig,
	codebase : CodeBase,

	// TODO(Ed) : Support multiple workspaces
	workspace : Workspace,
}

Frame :: struct
{
	pos  : Vec2,
	size : Vec2,

	ui : ^UI_Box,
}

Workspace :: struct {
	name : StringCached,

	cam         : Camera,
	zoom_target : f32,

	frames : Array(Frame),

	test_frame : Frame,

	// TODO(Ed) : The workspace is mainly a 'UI' conceptually...
	ui : UI_State,
}

DebugData :: struct {
	square_size : i32,
	square_pos  : rl.Vector2,

	draw_debug_text_y : f32,

	cursor_locked     : b32,
	cursor_unlock_pos : Vec2, // Raylib changes the mose position on lock, we want restore the position the user would be in on screen
	mouse_vis         : b32,
	last_mouse_pos    : Vec2,

	// Test First
	frame_2_created : b32,

	// Test Draggable
	draggable_box_pos  : Vec2,
	draggable_box_size : Vec2,
	box_original_size  : Vec2,

	// Test parsing
	path_lorem    : string,
	lorem_content : []byte,
	lorem_parse   : PWS_ParseResult,
}
