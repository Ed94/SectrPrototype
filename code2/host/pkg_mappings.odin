package host

import "base:builtin"
	// Odin_OS_Type :: type_of(ODIN_OS)

import "base:intrinsics"
	// atomic_thread_fence  :: intrinsics.atomic_thread_fence
	// mem_zero             :: intrinsics.mem_zero
	// mem_zero_volatile    :: intrinsics.mem_zero_volatile
	// mem_copy             :: intrinsics.mem_copy_non_overlapping
	// mem_copy_overlapping :: intrinsics.mem_copy

import "base:runtime"
	// Assertion_Failure_Proc :: runtime.Assertion_Failure_Proc
	// Logger                 :: runtime.Logger

import "core:dynlib"
	os_lib_load     :: dynlib.load_library
	os_lib_unload   :: dynlib.unload_library
	os_lib_get_proc :: dynlib.symbol_address

import core_os "core:os"
	file_last_write_time_by_name :: core_os.last_write_time_by_name
	OS_ERROR_NONE                :: core_os.ERROR_NONE

import "core:sync"
	thread_current_id :: sync.current_thread_id

import "core:time"
	Millisecond       :: time.Millisecond
	Second            :: time.Second
	Duration          :: time.Duration
	duration_seconds  :: time.duration_seconds
	thread_sleep      :: time.sleep

import "core:thread"
	SysThread :: thread.Thread

import grime "codebase:grime"
	file_copy_sync :: grime.file_copy_sync

import "codebase:sectr"
	Client_API   :: sectr.ModuleAPI
	HostMemory   :: sectr.HostMemory
	ThreadMemory :: sectr.ThreadMemory

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024
