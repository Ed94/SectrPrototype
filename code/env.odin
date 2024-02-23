package sectr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import rl "vendor:raylib"

memory : Memory

memory_chunk_size      :: 2 * Gigabyte
memory_persistent_size :: 256 * Megabyte
memory_trans_temp_size :: (memory_chunk_size - memory_persistent_size ) / 2

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

persistent_allocator :: proc () -> Allocator {
	when Use_TrackingAllocator {
		return tracked_allocator( memory.persistent )
	}
	else {
		return arena_allocator( memory.persistent )
	}
}

transient_allocator :: proc () -> Allocator {
	when Use_TrackingAllocator {
		return tracked_allocator( memory.transient )
	}
	else {
		return arena_allocator( memory.transient )
	}
}

temp_allocator :: proc () -> Allocator {
	when Use_TrackingAllocator {
		return tracked_allocator( memory.temp )
	}
	else {
		return arena_allocator( memory.temp )
	}
}

save_snapshot :: proc( snapshot : [^]u8 ) {
	live_ptr := cast( ^ rawptr ) memory.live.curr_block.base
	mem.copy_non_overlapping( & snapshot[0], live_ptr, memory_chunk_size )
}

load_snapshot :: proc( snapshot : [^]u8 ) {
	live_ptr := cast( ^ rawptr ) memory.live.curr_block.base
	mem.copy_non_overlapping( live_ptr, snapshot, memory_chunk_size )
}

AppConfig :: struct {
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

	font_firacode                : FontID,
	font_squidgy_slimes          : FontID,
	font_rec_mono_semicasual_reg : FontID,
	default_font                 : FontID,

	// There are two potential UI contextes for this prototype so far,
	// the screen-space UI and the current workspace UI.
	// This is used so that the ui api doesn't need to have the user pass the context every single time.
	ui_context : UI_State,
}

get_state :: proc "contextless" () -> ^ State {
	when Use_TrackingAllocator {
		return cast( ^ State ) raw_data( memory.persistent.backing.data )
	}
	else {
		return cast( ^ State ) raw_data( memory.persistent. data )
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
	frame_1 : Box2,
	frame_2 : Box2,

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

	frame_1_on_top : b32,
	zoom_target : f32,
}
