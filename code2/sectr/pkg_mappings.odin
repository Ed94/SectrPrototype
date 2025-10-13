package sectr

import "core:mem"
	Odin_Arena :: mem.Arena

import "core:os"
	FileTime :: os.File_Time

import "core:sync"
	AtomicMutex :: sync.Atomic_Mutex
	cache_coherent_store :: sync.atomic_store_explicit

import "core:thread"
	SysThread :: thread.Thread

import "core:time"
	Duration :: time.Duration

import "codebase:grime"
	Logger        :: grime.Logger
	SpallProfiler :: grime.SpallProfiler

Kilo :: 1024
Mega :: Kilo * 1024
Giga :: Mega * 1024
Tera :: Giga * 1024
