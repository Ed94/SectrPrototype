package sectr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import rl "vendor:raylib"

Memory_App : Memory

// TODO(Ed) : Make this obsolete
Memory_Base_Address    :: Terabyte * 1
Memory_Chunk_Size      :: 2 * Gigabyte
Memory_Persistent_Size :: 256 * Megabyte
Memory_Trans_Temp_Szie :: (Memory_Chunk_Size - Memory_Persistent_Size ) / 2

Memory_Base_Address_Persistent :: Terabyte * 1
Memory_Base_Address_Frame      :: Memory_Base_Address_Persistent + Memory_Reserve_Persistent

// TODO(Ed) : This is based off of using 32 gigs of my (Ed) as a maximum.
// Later on this has to be adjusted to be ratios based on user's system memory.
Memory_Reserve_Persistent  :: 8  * Gigabyte
Memory_Reserve_Frame       :: 4  * Gigabyte
Memory_Reserve_Transient   :: 4  * Gigabyte
Memory_Reserve_FilesBuffer :: 16 * Gigabyte

// TODO(Ed) : These are high for ease of use, they eventually need to be drastically minimized.
Memory_Commit_Initial_Persistent :: 256 * Megabyte
Memory_Commit_Initial_Frame      :: 1   * Gigabyte
Memory_Commit_Initial_Transient  :: 1   * Gigabyte
Memory_Commit_Initial_Filebuffer :: 2   * Gigabyte

// TODO(Ed): There is an issue with mutex locks on the tracking allocator..
Use_TrackingAllocator :: false

when Use_TrackingAllocator
{
	Memory :: struct {
		live       : virtual.Arena,
		snapshot   : []u8,

		persistent : ^ TrackedAllocator,
		transient  : ^ TrackedAllocator,
		temp       : ^ TrackedAllocator,

		replay : ReplayState,
		logger : Logger,
	}
}
else
{
	Memory :: struct {
		live       : virtual.Arena,
		snapshot   : []u8,

		persistent : ^ Arena,
		transient  : ^ Arena,
		temp       : ^ Arena,

		replay : ReplayState,
		logger : Logger,
	}
}

persistent_allocator :: proc() -> Allocator {
	when Use_TrackingAllocator {
		return tracked_allocator( Memory_App.persistent )
	}
	else {
		return arena_allocator( Memory_App.persistent )
	}
}

transient_allocator :: proc() -> Allocator {
	when Use_TrackingAllocator {
		return tracked_allocator( Memory_App.transient )
	}
	else {
		return arena_allocator( Memory_App.transient )
	}
}

temp_allocator :: proc() -> Allocator {
	when Use_TrackingAllocator {
		return tracked_allocator( Memory_App.temp )
	}
	else {
		return arena_allocator( Memory_App.temp )
	}
}

save_snapshot :: proc( snapshot : [^]u8 ) {
	live_ptr := cast( ^ rawptr ) Memory_App.live.curr_block.base
	mem.copy_non_overlapping( & snapshot[0], live_ptr, Memory_Chunk_Size )
}

load_snapshot :: proc( snapshot : [^]u8 ) {
	live_ptr := cast( ^ rawptr ) Memory_App.live.curr_block.base
	mem.copy_non_overlapping( live_ptr, snapshot, Memory_Chunk_Size )
}

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
	min_zoom          : uint,
	max_zoom          : uint,
}

State :: struct {
	font_provider_data : FontProviderData,

	input_data : [2] InputState,
	input_prev : ^   InputState,
	input      : ^   InputState,

	debug  : DebugData,

	project : Project,

	config     : AppConfig,
	app_window : AppWindow,

	monitor_id         : i32,
	monitor_refresh_hz : i32,

	engine_refresh_hz     : i32,
	engine_refresh_target : i32,

	frametime_delta_ns : Duration,

	font_firacode                : FontID,
	font_squidgy_slimes          : FontID,
	font_rec_mono_semicasual_reg : FontID,
	default_font                 : FontID,

	// There are two potential UI contextes for this prototype so far,
	// the screen-space UI and the current workspace UI.
	// This is used so that the ui api doesn't need to have the user pass the context every single time.
	ui_context : ^ UI_State,
}

get_state :: proc "contextless" () -> ^ State {
	when Use_TrackingAllocator {
		return cast( ^ State ) raw_data( Memory_App.persistent.backing.data )
	}
	else {
		return cast( ^ State ) raw_data( Memory_App.persistent. data )
	}
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
	path : string,
	name : string,

	config   : ProjectConfig,
	codebase : CodeBase,

	// TODO(Ed) : Support multiple workspaces
	workspace : Workspace,
}

Workspace :: struct {
	name : string,

	cam     : Camera,

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

	zoom_target : f32,

	frame_2_created : b32,
}
