package grime

import "base:builtin"
	Odin_OS_Type :: type_of(ODIN_OS)

import "base:intrinsics"
	atomic_thread_fence  :: intrinsics.atomic_thread_fence
	mem_zero             :: intrinsics.mem_zero
	mem_zero_volatile    :: intrinsics.mem_zero_volatile
	mem_copy             :: intrinsics.mem_copy_non_overlapping
	mem_copy_overlapping :: intrinsics.mem_copy

import "base:runtime"
	Assertion_Failure_Proc :: runtime.Assertion_Failure_Proc
	Logger                 :: runtime.Logger
	Random_Generator       :: runtime.Random_Generator
	slice_copy_overlapping :: runtime.copy_slice

import core_os "core:os"
	// ODIN_OS :: core_os.ODIN_OS

import "core:slice"
	slice_zero :: slice.zero
