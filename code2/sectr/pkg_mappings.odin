package sectr

/*
All direct non-codebase package symbols should do zero allocations.
Any symbol that does must be mapped from the Grime package to properly tirage its allocator to odin's ideomatic interface.
*/

import "base:intrinsics"
	debug_trap :: intrinsics.debug_trap

import "base:runtime"
	Context :: runtime.Context

import "core:dynlib"
	// Only referenced in ModuleAPI
	DynLibrary :: dynlib.Library

import "core:log"
	LoggerLevel :: log.Level

import "core:mem"
	AllocatorError       :: mem.Allocator_Error
	// Used strickly for the logger
	Odin_Arena           :: mem.Arena
	odin_arena_allocator :: mem.arena_allocator

import "core:os"
	FileTime     :: os.File_Time
	process_exit :: os.exit

import "core:prof/spall"
	SPALL_BUFFER_DEFAULT_SIZE :: spall.BUFFER_DEFAULT_SIZE
	Spall_Context             :: spall.Context
	Spall_Buffer              :: spall.Buffer

import "core:sync"
	AtomicMutex         :: sync.Atomic_Mutex
	barrier_wait        :: sync.barrier_wait
	sync_store          :: sync.atomic_store_explicit
	sync_load           :: sync.atomic_load_explicit
	sync_add            :: sync.atomic_add_explicit
	sync_sub            :: sync.atomic_sub_explicit
	sync_mutex_lock     :: sync.atomic_mutex_lock
	sync_mutex_unlock   :: sync.atomic_mutex_unlock
	sync_mutex_try_lock :: sync.atomic_mutex_try_lock

import threading "core:thread"
	SysThread     :: threading.Thread
	ThreadProc    :: threading.Thread_Proc
	thread_create :: threading.create
	thread_start  :: threading.start

import "core:time"
	Millisecond      :: time.Millisecond
	Duration         :: time.Duration
	Tick             :: time.Tick
	duration_ms      :: time.duration_milliseconds
	duration_seconds :: time.duration_seconds
	thread_sleep     :: time.sleep 
	tick_lap_time    :: time.tick_lap_time
	tick_now         :: time.tick_now

import "codebase:grime"
	ensure :: grime.ensure
	fatal  :: grime.fatal
	verify :: grime.verify

	Array                       :: grime.Array
	array_to_slice              :: grime.array_to_slice
	array_append_array          :: grime.array_append_array
	array_append_slice          :: grime.array_append_slice
	array_append_value          :: grime.array_append_value
	array_back                  :: grime.array_back
	array_clear                 :: grime.array_clear
	// Logging
	Logger                      :: grime.Logger
	logger_init                 :: grime.logger_init
	// Memory
	mem_alloc                   :: grime.mem_alloc
	mem_copy_overlapping        :: grime.mem_copy_overlapping
	mem_copy                    :: grime.mem_copy
	mem_zero                    :: grime.mem_zero
	slice_zero                  :: grime.slice_zero
	// Ring Buffer
	FRingBuffer                 :: grime.FRingBuffer
	FRingBufferIterator         :: grime.FRingBufferIterator
	ringbuf_fixed_peak_back     :: grime.ringbuf_fixed_peak_back
	ringbuf_fixed_push          :: grime.ringbuf_fixed_push
	ringbuf_fixed_push_slice    :: grime.ringbuf_fixed_push_slice
	iterator_ringbuf_fixed      :: grime.iterator_ringbuf_fixed
	next_ringbuf_fixed_iterator :: grime.next_ringbuf_fixed_iterator
	// Strings
	cstr_to_str_capped          :: grime.cstr_to_str_capped
	to_odin_logger              :: grime.to_odin_logger
	// Operating System
	set__scheduler_granularity :: grime.set__scheduler_granularity

	// grime_set_profiler_module_context :: grime.set_profiler_module_context
	// grime_set_profiler_thread_buffer  :: grime.set_profiler_thread_buffer

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024

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


// ensure :: #force_inline proc( condition : b32, msg : string, location := #caller_location ) {
// 	if condition do return
// 	log_print( msg, LoggerLevel.Warning, location )
// 	debug_trap()
// }
// // TODO(Ed) : Setup exit codes!
// fatal :: #force_inline proc( msg : string, exit_code : int = -1, location := #caller_location ) {
// 	log_print( msg, LoggerLevel.Fatal, location )
// 	debug_trap()
// 	process_exit( exit_code )
// }
// // TODO(Ed) : Setup exit codes!
// verify :: #force_inline proc( condition : b32, msg : string, exit_code : int = -1, location := #caller_location ) {
// 	if condition do return
// 	log_print( msg, LoggerLevel.Fatal, location )
// 	debug_trap()
// 	process_exit( exit_code )
// }

log_print :: proc( msg : string, level := LoggerLevel.Info, loc := #caller_location ) {
	context.allocator      = odin_arena_allocator(& memory.host_scratch)
	context.temp_allocator = odin_arena_allocator(& memory.host_scratch)
	log.log( level, msg, location = loc )
}
log_print_fmt :: proc( fmt : string, args : ..any,  level := LoggerLevel.Info, loc := #caller_location  ) {
	context.allocator      = odin_arena_allocator(& memory.host_scratch)
	context.temp_allocator = odin_arena_allocator(& memory.host_scratch)
	log.logf( level, fmt, ..args, location = loc )
}

@(deferred_none = profile_end, disabled = DISABLE_CLIENT_PROFILING)
profile :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & memory.spall_context, & thread.spall_buffer, name, "", loc )
}
@(disabled = DISABLE_CLIENT_PROFILING)
profile_begin :: #force_inline proc "contextless" ( name : string, loc := #caller_location ) {
	spall._buffer_begin( & memory.spall_context, & thread.spall_buffer, name, "", loc )
}
@(disabled = DISABLE_CLIENT_PROFILING)
profile_end :: #force_inline proc "contextless" () {
	spall._buffer_end( & memory.spall_context, & thread.spall_buffer)
}

// Procedure Mappings

add :: proc {
	add_r2f4,
	add_biv3f4,
}
append :: proc {
	array_append_array,
	array_append_slice,
	array_append_value,
}
array_append :: proc {
	array_append_array,
	array_append_slice,
	array_append_value,
}
biv3f4 :: proc {
	biv3f4_via_f32s,
	v3f4_to_biv3f4,
}
bivec :: biv3f4
clear :: proc {
	array_clear,
}
cross :: proc {
	cross_s,
	cross_v2,
	cross_v3,

	cross_v3f4_uv3f4,
	cross_u3f4_v3f4,
}
div :: proc {
	div_biv3f4_f32,
}
dot :: proc {
	sdot,
	vdot,
	qdot_f2,
	qdot_f4,
	qdot_f8,

	dot_v3f4_uv3f4,
	dot_uv3f4_v3f4,
}
equal :: proc {
	equal_r2f4,
}
is_power_of_two :: proc {
	is_power_of_two_u32,
	// is_power_of_two_uintptr,
}
iterator :: proc {
	iterator_ringbuf_fixed,
}
mov_avg_exp :: proc {
	mov_avg_exp_f32,
	mov_avg_exp_f64,
}
mul :: proc {
	mul_biv3f4,
	mul_biv3f4_f32,
	mul_f32_biv3f4,
}
join :: proc {
	join_r2f4,
}
inverse_sqrt :: proc {
	inverse_sqrt_f32,
}
next :: proc {
	next_ringbuf_fixed_iterator,
}
point3 :: proc {
	v3f4_to_point3f4,
}
pow2 :: proc {
	pow2_v3f4,
}
peek_back :: proc {
	ringbuf_fixed_peak_back,
}
push :: proc {
	ringbuf_fixed_push,
	ringbuf_fixed_push_slice,
}
quatf4 :: proc {
	quatf4_from_rotor3f4,
}
regress :: proc {
	regress_biv3f4,
}
rotor3 :: proc {
	rotor3f4_via_comps_f4,
	rotor3f4_via_bv_s_f4,
	// rotor3f4_via_from_to_v3f4,
}
size :: proc {
	size_r2f4,
}
sub :: proc {
	sub_r2f4,
	sub_biv3f4,
	// join_point3_f4,
	// join_pointflat3_f4,
}
to_slice :: proc {
	array_to_slice,
}
v2f4 :: proc {
	v2f4_from_f32s,
	v2f4_from_scalar,
	v2f4_from_v2s4,
	v2s4_from_v2f4,
}
v3f4 :: proc {
	v3f4_via_f32s,
	biv3f4_to_v3f4,
	point3f4_to_v3f4,
	pointflat3f4_to_v3f4,
	uv3f4_to_v3f4,
}
v2 :: proc {
	v2f4_from_f32s,
	v2f4_from_scalar,
	v2f4_from_v2s4,
	v2s4_from_v2f4,
}
v3 :: proc {
	v3f4_via_f32s,
	biv3f4_to_v3f4,
	point3f4_to_v3f4,
	pointflat3f4_to_v3f4,
	uv3f4_to_v3f4,
}
v4 :: proc {
	uv4f4_to_v4f4,
}
wedge :: proc {
	wedge_v3f4,
	wedge_biv3f4,
}
zero :: proc {
	mem_zero,
	slice_zero,
}
