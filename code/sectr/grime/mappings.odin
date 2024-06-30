
package sectr

#region("base")

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
	debug_trap         :: runtime.debug_trap

#endregion("base")

#region("core")

import c "core:c/libc"

// import "core:container/queue"
	// Queue :: queue.Queue

// import "core:dynlib"

import "core:hash"
	crc32 :: hash.crc32

import "core:hash/xxhash"
	xxh32 :: xxhash.XXH32

import fmt_io "core:fmt"
	str_fmt_out      :: fmt_io.printf
	str_fmt_tmp      :: fmt_io.tprintf
	str_fmt          :: fmt_io.aprintf // Decided to make aprintf the default. (It will always be the default allocator)
	str_fmt_builder  :: fmt_io.sbprintf
	str_fmt_buffer   :: fmt_io.bprintf
	str_to_file_ln   :: fmt_io.fprintln
	str_tmp_from_any :: fmt_io.tprint

import "core:math"
	lerp :: math.lerp

import "core:math/bits"
	u64_max :: bits.U64_MAX 

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

import "core:strconv"
	parse_f32  :: strconv.parse_f32
	parse_u64  :: strconv.parse_u64
	parse_uint :: strconv.parse_uint

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

#endregion("core")

import "thirdparty:backtrace"
	StackTraceData   :: backtrace.Trace_Const
	stacktrace       :: backtrace.trace
	stacktrace_lines :: backtrace.lines

#region("codebase")

import "codebase:grime"
	// asserts
	ensure :: grime.ensure
	fatal  :: grime.fatal
	verify :: grime.verify

	// chrono
	NS_To_MS :: grime.NS_To_MS
	NS_To_US :: grime.NS_To_US
	NS_To_S  :: grime.NS_To_S

	US_To_NS :: grime.US_To_NS
	US_To_MS :: grime.US_To_MS
	US_To_S  :: grime.US_To_S

	MS_To_NS :: grime.MS_To_NS
	MS_To_US :: grime.MS_To_US
	MS_To_S  :: grime.MS_To_S

	S_To_NS :: grime.S_To_NS
	S_To_US :: grime.S_To_US
	S_To_MS :: grime.S_To_MS

	// container
	Array :: grime.Array

	array_to_slice     :: grime.array_to_slice
	array_init         :: grime.array_init
	array_append       :: grime.array_append
	array_append_value :: grime.array_append_value
	array_append_array :: grime.array_append_array
	array_append_at    :: grime.array_append_at
	array_clear        :: grime.array_clear
	array_free         :: grime.array_free
	array_grow_formula :: grime.array_grow_formula
	array_remove_at    :: grime.array_remove_at
	array_resize       :: grime.array_resize

	HMapChained :: grime.HMapChained

	hmap_closest_prime :: grime.hmap_closest_prime

	hmap_chained_get    :: grime.hmap_chained_get
	hmap_chained_init   :: grime.hmap_chained_init
	hmap_chained_set    :: grime.hmap_chained_set
	hmap_chained_reload :: grime.hmap_chained_reload

	HMapZPL :: grime.HMapZPL

	hmap_zpl_init   :: grime.hmap_zpl_init
	hmap_zpl_get    :: grime.hmap_zpl_get
	hmap_zpl_reload :: grime.hmap_zpl_reload
	hmap_zpl_set    :: grime.hmap_zpl_set

	// make_queue :: grime.make_queue

	// next_queue_iterator :: grime.next_queue_iterator

	Pool :: grime.Pool

	RingBufferFixed         :: grime.RingBufferFixed
	RingBufferFixedIterator :: grime.RingBufferFixedIterator

	ringbuf_fixed_clear      :: grime.ringbuf_fixed_clear
	ringbuf_fixed_is_full    :: grime.ringbuf_fixed_is_full
	ringbuf_fixed_is_empty   :: grime.ringbuf_fixed_is_empty
	ringbuf_fixed_peak_back  :: grime.ringbuf_fixed_peak_back
	ringbuf_fixed_push       :: grime.ringbuf_fixed_push
	ringbuf_fixed_push_slice :: grime.ringbuf_fixed_push_slice
	ringbuf_fixed_pop        :: grime.ringbuf_fixed_pop

	iterator_ringbuf_fixed :: grime.iterator_ringbuf_fixed
	next_ringbuf_fixed_iterator :: grime.next_ringbuf_fixed_iterator

	Slab          :: grime.Slab
	SlabPolicy    :: grime.SlabPolicy
	SlabSizeClass :: grime.SlabSizeClass

	slab_allocator      :: grime.slab_allocator
	slab_alloc          :: grime.slab_alloc
	slab_init           :: grime.slab_init
	slab_reload         :: grime.slab_reload
	slab_validate_pools :: grime.slab_validate_pools

	StackFixed :: grime.StackFixed

	stack_clear            :: grime.stack_clear
	stack_push             :: grime.stack_push
	stack_pop              :: grime.stack_pop
	stack_peek_ref         :: grime.stack_peek_ref
	stack_peek             :: grime.stack_peek
	stack_push_contextless :: grime.stack_push_contextless

	// filesystem
	file_exists :: grime.file_exists
	file_rewind :: grime.file_rewind

	// linked lists
	LL_Node :: grime.LL_Node

	ll_push :: grime.ll_push
	ll_pop  :: grime.ll_pop

	DLL_Node     :: grime.DLL_Node
	DLL_NodeFull :: grime.DLL_NodeFull
	DLL_NodePN   :: grime.DLL_NodePN
	DLL_NodeFL   :: grime.DLL_NodeFL

	dll_full_push_back :: grime.dll_full_push_back
	dll_full_pop       :: grime.dll_full_pop
	dll_push_back      :: grime.dll_push_back
	dll_pop_back       :: grime.dll_pop_back

	// logger
	Logger   :: grime.Logger
	LogLevel :: grime.LogLevel

	to_odin_logger :: grime.to_odin_logger
	logger_init    :: grime.logger_init
	log            :: grime.log
	logf           :: grime.logf

	// memory
	MemoryTracker      :: grime.MemoryTracker
	MemoryTrackerEntry :: grime.MemoryTrackerEntry

	memtracker_clear                    :: grime.memtracker_clear
	memtracker_init                     :: grime.memtracker_init
	memtracker_register_auto_name       :: grime.memtracker_register_auto_name
	memtracker_register_auto_name_slice :: grime.memtracker_register_auto_name_slice
	memtracker_unregister               :: grime.memtracker_unregister

	calc_padding_with_header :: grime.calc_padding_with_header
	memory_after_header      :: grime.memory_after_header
	memory_after             :: grime.memory_after
	swap                     :: grime.swap

	// strings
	StrRunesPair :: grime.StrRunesPair
	StringCache  :: grime.StringCache

	str_cache_init           :: grime.str_cache_init
	str_cache_reload         :: grime.str_cache_reload
	str_cache_set_module_ctx :: grime.str_cache_set_module_ctx
	// str_intern_key        :: grime.str_intern_key
	// str_intern_lookup     :: grime.str_intern_lookup
	str_intern               :: grime.str_intern
	str_intern_fmt           :: grime.str_intern_fmt

	to_str_runes_pair_via_string :: grime.to_str_runes_pair_via_string
	to_str_runes_pair_via_runes  :: grime.to_str_runes_pair_via_runes
	// profiler
	SpallProfiler :: grime.SpallProfiler

	set_profiler_module_context :: grime.set_profiler_module_context

	profile       :: grime.profile
	profile_begin :: grime.profile_begin
	profile_end   :: grime.profile_end

	// os
	OS_Type :: grime.OS_Type

	// timing
	when ODIN_OS == OS_Type.Windows {
		set__scheduler_granularity :: grime.set__scheduler_granularity
	}

	// unicode
	string_to_runes       :: grime.string_to_runes
	string_to_runes_array :: grime.string_to_runes_array

	// virutal memory
	VArena              :: grime.VArena
	VirtualMemoryRegion :: grime.VirtualMemoryRegion

	varena_allocator :: grime.varena_allocator

#endregion("codebase")

#region("Procedure overload mappings")

// This has to be done on a per-module basis.

add :: proc {
	add_range2,
}

append :: proc {
	grime.array_append_array,
	grime.array_append_slice,
	grime.array_append_value,
}

bivec3 :: proc {
	bivec3_via_f32s,
	vec3_to_bivec3,
}

clear :: proc{
	grime.array_clear,
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

// ws_view_draw_text :: proc {
// 	ws_view_draw_text_string,
// 	ws_view_draw_text_StrRunesPair,
// }

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

iterator :: proc {
	// grime.iterator_queue,
	grime.iterator_ringbuf_fixed,
}

make :: proc {
	array_init,
	hmap_chained_init,
	hmap_zpl_init,
	// make_queue,

	// Usual
	make_slice,
	make_dynamic_array,
	make_dynamic_array_len,
	make_dynamic_array_len_cap,
	make_map,
	make_multi_pointer,
}

// measure_text_size :: proc {
// 	measure_text_size_raylib,
// }

mov_avg_exp :: proc {
	mov_avg_exp_f32,
	mov_avg_exp_f64,
}

next :: proc {
	// next_queue_iterator,
	next_ringbuf_fixed_iterator,
}

peek_back :: proc {
	ringbuf_fixed_peak_back,
}

// peek_front :: proc {
// 	queue.peek_front,
// }

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
	ringbuf_fixed_push,
	ringbuf_fixed_push_slice,

	// queue.push_back,
	// grime.push_back_slice_queue,

	stack_push,
	stack_allocator_push,

	ui_layout_push_layout,
	ui_layout_push_combo,

	ui_style_push_style,
	ui_style_push_combo,

	ui_theme_push_via_proc,
	ui_theme_push_via_theme,
}

rotor3 :: proc {
	rotor3_via_comps,
	rotor3_via_bv_s,
	rotor3_via_from_to,
}

released :: proc {
	btn_released,
}

reload :: proc {
	grime.reload_array,
	grime.reload_queue,
	grime.reload_map,
}

scope :: proc {
	ui_layout_scope_via_layout,
	ui_layout_scope_via_combo,

	ui_style_scope_via_style,
	ui_style_scope_via_combo,

	ui_theme_scope_via_layout_style,
	ui_theme_scope_via_combos,
	ui_theme_scope_via_proc,
	ui_theme_scope_via_theme,
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

// to_rl_rect :: proc {
// 	range2_to_rl_rect,
// }

to_runes :: proc {
	string_to_runes,
}

to_string :: proc {
	runes_to_string,
	str_builder_to_string,
}

to_str_runes_pair :: proc {
	to_str_runes_pair_via_runes,
	to_str_runes_pair_via_string,
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

to_ui_layout_side :: proc {
	to_ui_layout_side_f32,
	to_ui_layout_side_vec2,
}

ui_compute_layout :: proc {
	ui_box_compute_layout,
}

ui_floating :: proc {
	ui_floating_just_builder,
	ui_floating_with_capture,
}

ui_layout_push :: proc {
	ui_layout_push_layout,
	ui_layout_push_combo,
}

ui_layout :: proc {
	ui_layout_scope_via_layout,
	ui_layout_scope_via_combo,
}

ui_style_push :: proc {
	ui_style_push_style,
	ui_style_push_combo,
}

ui_style_scope :: proc {
	ui_style_scope_via_style,
	ui_style_scope_via_combo,
}

ui_theme_push :: proc {
	ui_theme_push_via_proc,
	ui_theme_push_via_theme,
}

ui_theme_scope :: proc {
	ui_theme_scope_via_layout_style,
	ui_theme_scope_via_combos,
	ui_theme_scope_via_theme,
}

wedge :: proc {
	wedge_vec3,
	wedge_bivec3,
}

#endregion("Proc overload mappings")
