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
	file_resize :: os.ftruncate
import       "core:strings"
import       "core:time"
import rl    "vendor:raylib"
import sectr "../."

TrackedAllocator       :: sectr.TrackedAllocator
tracked_allocator      :: sectr.tracked_allocator
tracked_allocator_init :: sectr.tracked_allocator_init

LogLevel :: sectr.LogLevel
log      :: sectr.log
fatal    :: sectr.fatal
verify   :: sectr.verify

path_snapshot :: "VMemChunk_1.snapshot"
when ODIN_OS == runtime.Odin_OS_Type.Windows
{
	path_logs                :: "../logs"
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
		base_address : rawptr = transmute( rawptr) u64(Terabyte * 1)

		result := arena_init_static( & sectr_live, base_address, sectr.memory_chunk_size, sectr.memory_chunk_size )
		verify( result != runtime.Allocator_Error.None, "Failed to allocate live memory for the sectr module" )
	}

	// Setup memory mapped io for snapshots
	{
		snapshot_file, open_error := os.open( path_snapshot, os.O_RDWR | os.O_CREATE )
		verify( open_error != os.ERROR_NONE, "Failed to open snapshot file for the sectr module" )

		file_info, stat_code := os.stat( path_snapshot )
		{
			if file_info.size != sectr.memory_chunk_size {
				file_resize( snapshot_file, sectr.memory_chunk_size )
			}
		}

		map_error                : virtual.Map_File_Error
		map_flags                : virtual.Map_File_Flags = { virtual.Map_File_Flag.Read, virtual.Map_File_Flag.Write }
		sectr_snapshot, map_error = virtual.map_file_from_file_descriptor( uintptr(snapshot_file), map_flags )
		verify( map_error != virtual.Map_File_Error.None, "Failed to allocate snapshot memory for the sectr module" )

		os.close(snapshot_file)
	}

	// Reassign default allocators for host
	memory.og_allocator      = context.allocator
	memory.og_temp_allocator = context.temp_allocator
	log("Memory setup")
	return memory;
}

load_sectr_api :: proc ( version_id : i32 ) -> sectr.ModuleAPI
{
	loaded_module : sectr.ModuleAPI

	write_time, result := os.last_write_time_by_name("sectr.dll")
	if result != os.ERROR_NONE {
		log( "Could not resolve the last write time for sectr.dll", LogLevel.Warning )
		runtime.debug_trap()
		return {}
	}

	live_file := path_sectr_live_module
	sectr.copy_file_sync( path_sectr_module, live_file )

	lib, load_result := dynlib.load_library( live_file )
	if ! load_result {
		log( "Failed to load the sectr module.", LogLevel.Warning )
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

	log("Loaded sectr API")
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
	log("Unloaded sectr API")
}

sync_sectr_api :: proc ( sectr_api : ^ sectr.ModuleAPI, memory : ^ VMemChunk, logger : ^ sectr.Logger )
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
		verify( sectr_api.lib_version == 0, "Failed to hot-reload the sectr module" )

		sectr_api.reload( memory.sectr_live, memory.sectr_snapshot, logger )
	}
}

main :: proc()
{
	state : RuntimeState
	using state

	path_logger_finalized : string
	{
		startup_time     := time.now()
		year, month, day := time.date( startup_time)
		hour, min, sec   := time.clock_from_time( startup_time)

		if ! os.is_dir( path_logs ) {
			os.make_directory( path_logs )
		}

		timestamp            := fmt.tprintf("%04d-%02d-%02d_%02d-%02d-%02d", year, month, day, hour, min, sec)
		path_logger_finalized = strings.clone( fmt.tprintf( "%s/sectr_%v.log", path_logs, timestamp) )
	}
	logger :  sectr.Logger
	sectr.init( & logger, "Sectr Host", fmt.tprintf( "%s/sectr.log", path_logs ) )
	context.logger = sectr.to_odin_logger( & logger )
	{
		// Log System Context
		backing_builder : [16 * Kilobyte] u8
		builder         := strings.builder_from_bytes( backing_builder[:] )
		fmt.sbprintf( & builder, "Core Count: %v, ", os.processor_core_count() )
		fmt.sbprintf( & builder, "Page Size: %v", os.get_page_size() )

		sectr.log( strings.to_string(builder) )
	}

	// Basic Giant VMem Block
	{
		// By default odin uses a growing arena for the runtime context
		// We're going to make it static for the prototype and separate it from the 'project' memory.
		// Then shove the context allocator for the engine to it.
		// The project's context will use its own subsection arena allocator.
		memory = setup_memory()
	}

	// TODO(Ed): Cannot use the manually created allocators for the host. Not sure why
	// context.allocator        = tracked_allocator( & memory.host_persistent )
	// context.temp_allocator   = tracked_allocator( & memory.host_transient )

	// Load the Enviornment API for the first-time
	{
		sectr_api = load_sectr_api( 1 )
		verify( sectr_api.lib_version == 0, "Failed to initially load the sectr module" )
	}

	running            = true;
	memory             = memory
	sectr_api          = sectr_api
	sectr_api.startup( memory.sectr_live, memory.sectr_snapshot, & logger )

	// TODO(Ed) : This should have an end status so that we know the reason the engine stopped.
	for ; running ;
	{
		// Hot-Reload
		sync_sectr_api( & sectr_api, & memory, & logger )

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

	log("Succesfuly closed")
	os.close( logger.file )
	os.rename( logger.file_path, path_logger_finalized )
}
