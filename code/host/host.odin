package host

import       "base:runtime"
import      "core:dynlib"
import      "core:io"
import      "core:fmt"
import      "core:log"
import      "core:mem"
import      "core:mem/virtual"
	Byte     :: 1
	Kilobyte :: 1024 * Byte
	Megabyte :: 1024 * Kilobyte
	Gigabyte :: 1024 * Megabyte
	Terabyte :: 1024 * Gigabyte
	Petabyte :: 1024 * Terabyte
	Exabyte  :: 1024 * Petabyte
import       "core:os"
import       "core:strings"
import       "core:time"
import rl    "vendor:raylib"
import sectr "../."

TrackedAllocator       :: sectr.TrackedAllocator
tracked_allocator      :: sectr.tracked_allocator
tracked_allocator_init :: sectr.tracked_allocator_init

path_snapshot :: "VMemChunk_1.snapshot"
when ODIN_OS == runtime.Odin_OS_Type.Windows
{
	path_sectr_module        :: "sectr.dll"
	path_sectr_live_module   :: "sectr_live.dll"
	path_sectr_debug_symbols :: "sectr.pdb"
}

RuntimeState :: struct {
	running   : b32,
	memory    : VMemChunk,
	sectr_api : sectr.ModuleAPI,
}

VMemChunk :: struct {
	og_allocator            : mem.Allocator,
	og_temp_allocator       : mem.Allocator,
	host_persistent         : TrackedAllocator,
	host_transient          : TrackedAllocator,
	sectr_live              : virtual.Arena,
	sectr_snapshot          : []u8
}

setup_memory :: proc () -> VMemChunk
{
	Arena              :: mem.Arena
	Tracking_Allocator :: mem.Tracking_Allocator
	memory : VMemChunk; using memory

	host_persistent_size :: 32 * Megabyte
	host_transient_size  :: 96 * Megabyte
	internals_size       :: 4  * Megabyte

	host_persistent = tracked_allocator_init( host_persistent_size, internals_size )
	host_transient  = tracked_allocator_init( host_transient_size,  internals_size )

	// Setup the static arena for the entire application
	{
		base_address : rawptr = transmute( rawptr) u64(Terabyte * 2)

		result := arena_init_static( & sectr_live, base_address, sectr.memory_chunk_size, sectr.memory_chunk_size )
		if result != runtime.Allocator_Error.None
		{
			// TODO(Ed) : Setup a proper logging interface
			fmt.    printf( "Failed to allocate live memory for the sectr module" )
			runtime.debug_trap()
			os.     exit( -1 )
			// TODO(Ed) : Figure out the error code enums..
		}
	}

	// Setup memory mapped io for snapshots
	{
		file_resize :: os.ftruncate

		snapshot_file, open_error := os.open( path_snapshot, os.O_RDWR | os.O_CREATE )
		if ( open_error != os.ERROR_NONE )
		{
			// TODO(Ed) : Setup a proper logging interface
			fmt.    printf( "Failed to open snapshot file for the sectr module" )
			runtime.debug_trap()
			os.     exit( -1 )
			// TODO(Ed) : Figure out the error code enums..
		}
		file_info, stat_code := os.stat( path_snapshot )
		{
			if file_info.size != sectr.memory_chunk_size {
				file_resize( snapshot_file, sectr.memory_chunk_size )
			}
		}

		map_error : virtual.Map_File_Error
		sectr_snapshot, map_error = virtual.map_file_from_file_descriptor( uintptr(snapshot_file), { virtual.Map_File_Flag.Read, virtual.Map_File_Flag.Write } )
		if map_error != virtual.Map_File_Error.None
		{
			// TODO(Ed) : Setup a proper logging interface
			fmt.    printf( "Failed to allocate snapshot memory for the sectr module" )
			runtime.debug_trap()
			os.     exit( -1 )
			// TODO(Ed) : Figure out the error code enums..
		}

		os.close(snapshot_file)
	}

	// Reassign default allocators for host
	memory.og_allocator      = context.allocator
	memory.og_temp_allocator = context.temp_allocator
	context.allocator        = tracked_allocator( & memory.host_persistent )
	context.temp_allocator   = tracked_allocator( & memory.host_transient )
	return memory;
}

load_sectr_api :: proc ( version_id : i32 ) -> sectr.ModuleAPI
{
	loaded_module : sectr.ModuleAPI

	write_time,
	   result := os.last_write_time_by_name("sectr.dll")
	if result != os.ERROR_NONE {
		fmt.    println("Could not resolve the last write time for sectr.dll")
		runtime.debug_trap()
		return {}
	}

	live_file := path_sectr_live_module
	sectr.copy_file_sync( path_sectr_module, live_file )

	lib, load_result := dynlib.load_library( live_file )
	if ! load_result {
		// TODO(Ed) : Setup a proper logging interface
		fmt.    println( "Failed to load the sectr module." )
		runtime.debug_trap()
		return {}
	}

	startup    := cast( type_of( sectr.startup        )) dynlib.symbol_address( lib, "startup" )
	shutdown   := cast( type_of( sectr.sectr_shutdown )) dynlib.symbol_address( lib, "sectr_shutdown" )
	reload     := cast( type_of( sectr.reload         )) dynlib.symbol_address( lib, "reload" )
	update     := cast( type_of( sectr.update         )) dynlib.symbol_address( lib, "update" )
	render     := cast( type_of( sectr.render         )) dynlib.symbol_address( lib, "render" )
	clean_temp := cast( type_of( sectr.clean_temp     )) dynlib.symbol_address( lib, "clean_temp" )

	missing_symbol : b32 = false
	if startup    == nil do fmt.println("Failed to load sectr.startup symbol")
	if shutdown   == nil do fmt.println("Failed to load sectr.shutdown symbol")
	if reload     == nil do fmt.println("Failed to load sectr.reload symbol")
	if update     == nil do fmt.println("Failed to load sectr.update symbol")
	if render     == nil do fmt.println("Failed to load sectr.render symbol")
	if clean_temp == nil do fmt.println("Failed to load sector.clean_temp symbol")
	if missing_symbol {
		runtime.debug_trap()
		return {}
	}

	loaded_module = {
		lib         = lib,
		write_time  = write_time,
		lib_version = version_id,

		startup    = startup,
		shutdown   = shutdown,
		reload     = reload,
		update     = update,
		render     = render,
		clean_temp = clean_temp,
	}
	return loaded_module
}

unload_sectr_api :: proc ( module : ^ sectr.ModuleAPI )
{
	dynlib.unload_library( module.lib )
	os.remove( path_sectr_live_module )
	module^ = {}
}

sync_sectr_api :: proc ( sectr_api : ^ sectr.ModuleAPI, memory : ^ VMemChunk )
{
	if write_time, result := os.last_write_time_by_name( path_sectr_module );
	result == os.ERROR_NONE && sectr_api.write_time != write_time
	{
		version_id := sectr_api.lib_version + 1
		unload_sectr_api( sectr_api )

		// Wait for pdb to unlock (linker may still be writting)
		for ; sectr.is_file_locked( path_sectr_debug_symbols ) && sectr.is_file_locked( path_sectr_live_module ); {}
		time.sleep( time.Millisecond )

		sectr_api ^ = load_sectr_api( version_id )
		if sectr_api.lib_version == 0 {
			fmt.println("Failed to hot-reload the sectr module")
			runtime.debug_trap()
			os.exit(-1)
			// TODO(Ed) : Figure out the error code enums..
		}
		sectr_api.reload( memory.sectr_live, memory.sectr_snapshot )
	}
}

main :: proc()
{
	fmt.println("Hellope!")

	state : RuntimeState
	using state

	// Basic Giant VMem Block
	{
		// By default odin uses a growing arena for the runtime context
		// We're going to make it static for the prototype and separate it from the 'project' memory.
		// Then shove the context allocator for the engine to it.
		// The project's context will use its own subsection arena allocator.
		memory = setup_memory()
	}

	// Load the Enviornment API for the first-time
	{
		   sectr_api = load_sectr_api( 1 )
		if sectr_api.lib_version == 0 {
			// TODO(Ed) : Setup a proper logging interface
			fmt.    println( "Failed to initially load the sectr module" )
			runtime.debug_trap()
			os.     exit( -1 )
			// TODO(Ed) : Figure out the error code enums..
		}
	}

	running            = true;
	memory             = memory
	sectr_api          = sectr_api
	sectr_api.startup( memory.sectr_live, memory.sectr_snapshot )

	// TODO(Ed) : This should have an end status so that we know the reason the engine stopped.
	for ; running ;
	{
		// Hot-Reload
		sync_sectr_api( & sectr_api, & memory )

		running = sectr_api.update()
		          sectr_api.render()
		          sectr_api.clean_temp()
	}

	// Determine how the run_cyle completed, if it failed due to an error,
	// fallback the env to a failsafe state and reload the run_cycle.
	{
		// TODO(Ed): Implement this.
	}

	sectr_api.shutdown()
	unload_sectr_api( & sectr_api )
}
