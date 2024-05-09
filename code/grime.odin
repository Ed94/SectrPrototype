
package sectr

import "base:builtin"
	copy :: builtin.copy
import "base:intrinsics"
	mem_zero       :: intrinsics.mem_zero
	ptr_sub        :: intrinsics.ptr_sub
	type_has_field :: intrinsics.type_has_field
	type_elem_type :: intrinsics.type_elem_type
import "base:runtime"
	Byte               :: runtime.Byte
	Kilobyte           :: runtime.Kilobyte
	Megabyte           :: runtime.Megabyte
	Gigabyte           :: runtime.Gigabyte
	Terabyte           :: runtime.Terabyte
	Petabyte           :: runtime.Petabyte
	Exabyte            :: runtime.Exabyte
	resize_non_zeroed  :: runtime.non_zero_mem_resize
	SourceCodeLocation :: runtime.Source_Code_Location
import c "core:c/libc"
import "core:dynlib"
import "core:hash"
	crc32 :: hash.crc32
import "core:hash/xxhash"
	xxh32 :: xxhash.XXH32
import fmt_io "core:fmt"
	str_fmt          :: fmt_io.printf
	str_fmt_tmp      :: fmt_io.tprintf
	str_fmt_alloc    :: fmt_io.aprintf
	str_fmt_builder  :: fmt_io.sbprintf
	str_fmt_buffer   :: fmt_io.bprintf
	str_to_file_ln   :: fmt_io.fprintln
	str_tmp_from_any :: fmt_io.tprint
import "core:math"
import "core:mem"
	align_forward_int       :: mem.align_forward_int
	align_forward_uint      :: mem.align_forward_uint
	align_forward_uintptr   :: mem.align_forward_uintptr
	Allocator               :: mem.Allocator
	AllocatorError          :: mem.Allocator_Error
	AllocatorMode           :: mem.Allocator_Mode
	AllocatorModeSet        :: mem.Allocator_Mode_Set
	alloc                   :: mem.alloc
	alloc_bytes             :: mem.alloc_bytes
	alloc_bytes_non_zeroed  :: mem.alloc_bytes_non_zeroed
	Arena                   :: mem.Arena
	arena_allocator         :: mem.arena_allocator
	arena_init              :: mem.arena_init
	byte_slice              :: mem.byte_slice
	copy_non_overlapping    :: mem.copy_non_overlapping
	free                    :: mem.free
	is_power_of_two_uintptr :: mem.is_power_of_two
	ptr_offset              :: mem.ptr_offset
	resize                  :: mem.resize
	slice_ptr               :: mem.slice_ptr
	TrackingAllocator       :: mem.Tracking_Allocator
	tracking_allocator      :: mem.tracking_allocator
	tracking_allocator_init :: mem.tracking_allocator_init
import "core:mem/virtual"
	VirtualProtectFlags :: virtual.Protect_Flags
// import "core:odin"
import "core:os"
	FileFlag_Create    :: os.O_CREATE
	FileFlag_ReadWrite :: os.O_RDWR
	FileTime           :: os.File_Time
	file_close         :: os.close
	file_open          :: os.open
	file_read          :: os.read
	file_remove        :: os.remove
	file_seek          :: os.seek
	file_status        :: os.stat
	file_write         :: os.write
import "core:path/filepath"
	file_name_from_path :: filepath.short_stem
import str "core:strings"
	StringBuilder          :: str.Builder
	str_builder_from_bytes :: str.builder_from_bytes
	str_builder_init       :: str.builder_init
	str_builder_to_writer  :: str.to_writer
	str_builder_to_string  :: str.to_string
import "core:time"
	Duration         :: time.Duration
	duration_seconds :: time.duration_seconds
	duration_ms      :: time.duration_milliseconds
	thread_sleep     :: time.sleep
import "core:unicode"
	is_white_space  :: unicode.is_white_space
import "core:unicode/utf8"
	str_rune_count  :: utf8.rune_count_in_string
	runes_to_string :: utf8.runes_to_string
	// string_to_runes :: utf8.string_to_runes
import "thirdparty:backtrace"
	StackTraceData   :: backtrace.Trace_Const
	stacktrace       :: backtrace.trace
	stacktrace_lines :: backtrace.lines

OS_Type :: type_of(ODIN_OS)

swap :: proc( a, b : ^ $Type ) -> ( ^ Type, ^ Type ) {
	return b, a
}

// Proc Name Overloads Alias table
// This has to be done on a per-module basis.

add :: proc {
	add_range2,
}

bivec3 :: proc {
	bivec3_via_f32s,
	vec3_to_bivec3,
}

cm_to_pixels :: proc {
	f32_cm_to_pixels,
	vec2_cm_to_pixels,
	range2_cm_to_pixels,
}

regress :: proc {
	regress_bivec3,
}

cross :: proc {
	cross_vec3,
}

dot :: proc {
	dot_vec2,
	dot_vec3,
	dot_v3_unitv3,
	dot_unitv3_vs,
}

ws_view_draw_text :: proc {
	ws_view_draw_text_string,
	ws_view_draw_text_StrRunesPair,
}

from_bytes :: proc {
	str_builder_from_bytes,
}

get_bounds :: proc {
	view_get_bounds,
}

inverse_mag :: proc {
	inverse_mag_vec3,
	// inverse_mag_rotor3,
}

is_power_of_two :: proc {
	is_power_of_two_u32,
	is_power_of_two_uintptr,
}

mov_avg_exp :: proc {
	mov_avg_exp_f32,
	mov_avg_exp_f64,
}

pixels_to_cm :: proc {
	f32_pixels_to_cm,
	vec2_pixels_to_cm,
	range2_pixels_to_cm,
}

points_to_pixels :: proc {
	f32_points_to_pixels,
	vec2_points_to_pixels,
}

pop :: proc {
	stack_pop,
	stack_allocator_pop,
}

pow :: proc{
	math.pow_f16,
	math.pow_f16le,
	math.pow_f16be,
	math.pow_f32,
	math.pow_f32le,
	math.pow_f32be,
	math.pow_f64,
	math.pow_f64le,
	math.pow_f64be,
}

pow2 :: proc {
	pow2_vec3,
}

pressed :: proc {
	btn_pressed,
}

push :: proc {
	stack_push,
	stack_allocator_push,
}

rotor3 :: proc {
	rotor3_via_comps,
	rotor3_via_bv_s,
	rotor3_via_from_to,
}

released :: proc {
	btn_released,
}

sqrt :: proc{
	math.sqrt_f16,
	math.sqrt_f16le,
	math.sqrt_f16be,
	math.sqrt_f32,
	math.sqrt_f32le,
	math.sqrt_f32be,
	math.sqrt_f64,
	math.sqrt_f64le,
	math.sqrt_f64be,
}

inverse_sqrt :: proc {
	inverse_sqrt_f32,
}

sub :: proc {
	sub_point3,
	sub_range2,
	sub_bivec3,
}

to_quat128 :: proc {
	rotor3_to_quat128,
}

to_rl_rect :: proc {
	range2_to_rl_rect,
}

to_runes :: proc {
	string_to_runes,
}

to_string :: proc {
	runes_to_string,
	str_builder_to_string,
}

vec3 :: proc {
	vec3_via_f32s,
	bivec3_to_vec3,
	point3_to_vec3,
	pointflat3_to_vec3,
	unitvec3_to_vec3,
}

vec4 :: proc {
	unitvec4_to_vec4,
}

to_writer :: proc {
	str_builder_to_writer,
}

ui_set_layout :: proc {
	ui_style_set_layout,
	ui_style_theme_set_layout,
}

wedge :: proc {
	wedge_vec3,
	wedge_bivec3,
}
