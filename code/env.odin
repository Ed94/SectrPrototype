package sectr

import "base:runtime"
import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:os"

import rl "vendor:raylib"

memory : Memory

memory_chunk_size      :: 2 * Gigabyte
memory_persistent_size :: 128 * Megabyte
memory_trans_temp_size :: (memory_chunk_size - memory_persistent_size ) / 2

Memory :: struct {
	live       : virtual.Arena,
	snapshot   : []u8,
	persistent : ^ TrackedAllocator,
	transient  : ^ TrackedAllocator,
	temp       : ^ TrackedAllocator,

	replay : ReplayState,
	logger : Logger,
}

save_snapshot :: proc( snapshot : [^]u8 ) {
	state := get_state() 

	// state.font_rec_mono_semicasual_reg
	// state.default_font

	live_ptr := cast( ^ rawptr ) memory.live.curr_block.base
	mem.copy_non_overlapping( & snapshot[0], live_ptr, memory_chunk_size )
}

load_snapshot :: proc( snapshot : [^]u8 ) {
	live_ptr := cast( ^ rawptr ) memory.live.curr_block.base
	mem.copy_non_overlapping( live_ptr, snapshot, memory_chunk_size )
}

State :: struct {
	input_data : [2] InputState,
	input_prev : ^   InputState,
	input      : ^   InputState,

	debug  : DebugData,

	project : Project,

	screen_width       : i32,
	screen_height      : i32,
	screen_dpi_scale   : f32,
	screen_dpc         : f32,  // Pixels per cm

	monitor_id         : i32,
	monitor_refresh_hz : i32,

	engine_refresh_hz     : i32,
	engine_refresh_target : i32,

	font_rec_mono_semicasual_reg : Font,
	default_font                 : Font,
}

get_state :: proc() -> (^ State) {
	return cast( ^ State ) raw_data( memory.persistent.backing.data )
}

Project :: struct {
	path : string,
	name : string,

	// TODO(Ed) : Support multiple workspaces
	workspace : Workspace
}

Workspace :: struct {
	name : string,

	cam     : Camera,
	frame_1 : Frame
}

DebugData :: struct {
	square_size : i32,
	square_pos  : rl.Vector2,

	draw_debug_text_y : f32,

	mouse_vis : b32,
	mouse_pos : Vec2,
}
