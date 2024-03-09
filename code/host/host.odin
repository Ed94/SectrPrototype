/* Sectr Host Executable
Manages the client module (sectr) application & loads its required memory to operate.
Reserves the virtual memory spaces for the following:
* Persistent
* Frame
* Transient
* FilesBuffer

Currently the prototype has hot-reload always enabled, eventually there will be conditional compliation to omit if when desired.
*/
package host

//region Grime & Dependencies
import "base:runtime"
	Byte     :: runtime.Byte
	Kilobyte :: runtime.Kilobyte
	Megabyte :: runtime.Megabyte
	Gigabyte :: runtime.Gigabyte
	Terabyte :: runtime.Terabyte
	Petabyte :: runtime.Petabyte
	Exabyte  :: runtime.Exabyte
import "core:dynlib"
	os_lib_load     :: dynlib.load_library
	os_lib_unload   :: dynlib.unload_library
	os_lib_get_proc :: dynlib.symbol_address
import "core:io"
import fmt_io "core:fmt"
	str_fmt         :: fmt_io.printf
	str_fmt_alloc   :: fmt_io.aprintf
	str_fmt_tmp     :: fmt_io.tprintf
	str_fmt_builder :: fmt_io.sbprintf
import "core:log"
import "core:mem"
	Allocator         :: mem.Allocator
	AllocatorError    :: mem.Allocator_Error
	TrackingAllocator :: mem.Tracking_Allocator
import "core:mem/virtual"
	Arena        :: virtual.Arena
	MapFileError :: virtual.Map_File_Error
	MapFileFlag  :: virtual.Map_File_Flag
	MapFileFlags :: virtual.Map_File_Flags
import "core:os"
	FileFlag_Create        :: os.O_CREATE
	FileFlag_ReadWrite     :: os.O_RDWR
	file_open              :: os.open
	file_close             :: os.close
	file_rename            :: os.rename
	file_remove            :: os.remove
	file_resize            :: os.ftruncate
	file_status_via_handle :: os.fstat
	file_status_via_path   :: os.stat
import "core:strings"
	builder_to_string      :: strings.to_string
	str_clone              :: strings.clone
	str_builder_from_bytes :: strings.builder_from_bytes
import "core:time"
	Millisecond      :: time.Millisecond
	Second           :: time.Second
	Duration         :: time.Duration
	duration_seconds :: time.duration_seconds
	thread_sleep     :: time.sleep
import rl    "vendor:raylib"
import sectr "../."
	VArena                 :: sectr.VArena
	varena_init            :: sectr.varena_init
	fatal                  :: sectr.fatal
	file_is_locked         :: sectr.file_is_locked
	file_copy_sync         :: sectr.file_copy_sync
	Logger                 :: sectr.Logger
	logger_init            :: sectr.logger_init
	LogLevel               :: sectr.LogLevel
	log                    :: sectr.log
	to_odin_logger         :: sectr.to_odin_logger
	TrackedAllocator       :: sectr.TrackedAllocator
	tracked_allocator      :: sectr.tracked_allocator
	tracked_allocator_init :: sectr.tracked_allocator_init
	verify                 :: sectr.verify

file_status :: proc {
	file_status_via_handle,
	file_status_via_path,
}

to_str :: proc {
	builder_to_string,
}
//endregion Grime & Dependencies

Path_Snapshot :: "VMemChunk_1.snapshot"
Path_Logs     :: "../logs"
when ODIN_OS == runtime.Odin_OS_Type.Windows
{
	Path_Sectr_Module        :: "sectr.dll"
	Path_Sectr_Live_Module   :: "sectr_live.dll"
	Path_Sectr_Debug_Symbols :: "sectr.pdb"
}

RuntimeState :: struct {
	running       : b32,
	client_memory : ClientMemory,
	sectr_api     : sectr.ModuleAPI,
}

ClientMemory :: struct {
	persistent        : VArena,
	frame             : VArena,
	transient         : VArena,
	files_buffer      : VArena,
}

setup_memory :: proc() -> ClientMemory
{
	memory : ClientMemory; using memory

	// Setup the static arena for the entire application
	{
		alloc_error : AllocatorError
		persistent, alloc_error = varena_init( sectr.Memory_Base_Address_Persistent, sectr.Memory_Reserve_Persistent, sectr.Memory_Commit_Initial_Persistent, nil )
		verify( alloc_error == .None, "Failed to allocate persistent virtual arena for the sectr module")

		frame, alloc_error = varena_init( sectr.Memory_Base_Address_Frame, sectr.Memory_Reserve_Frame, sectr.Memory_Commit_Initial_Frame, nil )
		verify( alloc_error == .None, "Failed to allocate frame virtual arena for the sectr module")

		transient, alloc_error = varena_init( sectr.Memory_Base_Address_Transient, sectr.Memory_Reserve_Transient, sectr.Memory_Commit_Initial_Transient, nil )
		verify( alloc_error == .None, "Failed to allocate transient virtual arena for the sectr module")

		files_buffer, alloc_error = varena_init( sectr.Memory_Base_Address_Files_Buffer, sectr.Memory_Reserve_FilesBuffer, sectr.Memory_Commit_Initial_Filebuffer, nil )
		verify( alloc_error == .None, "Failed to allocate files buffer virtual arena for the sectr module")
	}

	// Setup memory mapped io for snapshots
	// TODO(Ed) : We cannot do this with our growing arenas. Instead we need to map on demand for saving and loading
	when false
	{
		snapshot_file, open_error := file_open( Path_Snapshot, FileFlag_ReadWrite | FileFlag_Create )
		verify( open_error == os.ERROR_NONE, "Failed to open snapshot file for the sectr module" )

		file_info, stat_code := file_status( snapshot_file )
		{
			if file_info.size != sectr.Memory_Chunk_Size {
				file_resize( snapshot_file, sectr.Memory_Chunk_Size )
			}
		}
		map_error                : MapFileError
		map_flags                : MapFileFlags = { MapFileFlag.Read, MapFileFlag.Write }
		sectr_snapshot, map_error = virtual.map_file_from_file_descriptor( uintptr(snapshot_file), map_flags )
		verify( map_error == MapFileError.None, "Failed to allocate snapshot memory for the sectr module" )
		file_close(snapshot_file)
	}

	log("Memory setup")
	return memory;
}

load_sectr_api :: proc( version_id : i32 ) -> (loaded_module : sectr.ModuleAPI)
{
	write_time, result := os.last_write_time_by_name("sectr.dll")
	if result != os.ERROR_NONE {
		log( "Could not resolve the last write time for sectr.dll", LogLevel.Warning )
		runtime.debug_trap()
		return
	}

	live_file := Path_Sectr_Live_Module
	file_copy_sync( Path_Sectr_Module, live_file )

	lib, load_result := os_lib_load( live_file )
	if ! load_result {
		log( "Failed to load the sectr module.", LogLevel.Warning )
		runtime.debug_trap()
		return
	}

	startup     := cast( type_of( sectr.startup        )) os_lib_get_proc( lib, "startup" )
	shutdown    := cast( type_of( sectr.sectr_shutdown )) os_lib_get_proc( lib, "sectr_shutdown" )
	reload      := cast( type_of( sectr.reload         )) os_lib_get_proc( lib, "reload" )
	tick        := cast( type_of( sectr.tick           )) os_lib_get_proc( lib, "tick" )
	clean_frame := cast( type_of( sectr.clean_frame    )) os_lib_get_proc( lib, "clean_frame" )

	missing_symbol : b32 = false
	if startup     == nil do log("Failed to load sectr.startup symbol",      LogLevel.Warning )
	if shutdown    == nil do log("Failed to load sectr.shutdown symbol",     LogLevel.Warning )
	if reload      == nil do log("Failed to load sectr.reload symbol",       LogLevel.Warning )
	if tick        == nil do log("Failed to load sectr.tick symbol",         LogLevel.Warning )
	if clean_frame == nil do log("Failed to load sector.clean_frame symbol", LogLevel.Warning )
	if missing_symbol {
		runtime.debug_trap()
		return
	}

	log("Loaded sectr API")
	loaded_module = {
		lib         = lib,
		write_time  = write_time,
		lib_version = version_id,

		startup     = startup,
		shutdown    = shutdown,
		reload      = reload,
		tick        = tick,
		clean_frame = clean_frame,
	}
	return
}

unload_sectr_api :: proc( module : ^ sectr.ModuleAPI )
{
	os_lib_unload( module.lib )
	file_remove( Path_Sectr_Live_Module )
	module^ = {}
	log("Unloaded sectr API")
}

sync_sectr_api :: proc( sectr_api : ^sectr.ModuleAPI, memory : ^ClientMemory, logger : ^Logger )
{
	if write_time, result := os.last_write_time_by_name( Path_Sectr_Module );
	result == os.ERROR_NONE && sectr_api.write_time != write_time
	{
		version_id := sectr_api.lib_version + 1
		unload_sectr_api( sectr_api )

		// Wait for pdb to unlock (linker may still be writting)
		for ; file_is_locked( Path_Sectr_Debug_Symbols ) && file_is_locked( Path_Sectr_Live_Module ); {}
		thread_sleep( Millisecond * 100 )

		sectr_api ^ = load_sectr_api( version_id )
		verify( sectr_api.lib_version != 0, "Failed to hot-reload the sectr module" )

		sectr_api.reload(
			& memory.persistent,
			& memory.frame,
			& memory.transient,
			& memory.files_buffer,
			logger )
	}
}

main :: proc()
{
	state : RuntimeState
	using state

	// Generating the logger's name, it will be used when the app is shutting down.
	path_logger_finalized : string
	{
		startup_time     := time.now()
		year, month, day := time.date( startup_time)
		hour, min, sec   := time.clock_from_time( startup_time)

		if ! os.is_dir( Path_Logs ) {
			os.make_directory( Path_Logs )
		}

		timestamp            := str_fmt_tmp("%04d-%02d-%02d_%02d-%02d-%02d", year, month, day, hour, min, sec)
		path_logger_finalized = str_fmt_alloc( "%s/sectr_%v.log", Path_Logs, timestamp)
	}

	logger :  sectr.Logger
	logger_init( & logger, "Sectr Host", str_fmt_alloc( "%s/sectr.log", Path_Logs ) )
	context.logger = to_odin_logger( & logger )
	{
		// Log System Context
		backing_builder : [16 * Kilobyte] u8
		builder         := str_builder_from_bytes( backing_builder[:] )
		str_fmt_builder( & builder, "Core Count: %v, ", os.processor_core_count() )
		str_fmt_builder( & builder, "Page Size: %v",    os.get_page_size() )

		log( to_str(builder) )
	}

	memory := setup_memory()

	// TODO(Ed): Cannot use the manually created allocators for the host. Not sure why
	// Something is wrong with the tracked_allocator init
	// context.allocator        = tracked_allocator( & memory.host_persistent )
	// context.temp_allocator   = tracked_allocator( & memory.host_transient )

	// Load the Enviornment API for the first-time
	{
		sectr_api = load_sectr_api( 1 )
		verify( sectr_api.lib_version != 0, "Failed to initially load the sectr module" )
	}

	free_all( context.temp_allocator )

	running   = true;
	sectr_api = sectr_api
	sectr_api.startup(
		& memory.persistent,
		& memory.frame,
		& memory.transient,
		& memory.files_buffer,
		& logger )

	delta_ns : Duration

	host_tick := time.tick_now()

	// TODO(Ed) : This should have an end status so that we know the reason the engine stopped.
	for ; running ;
	{
		// Hot-Reload
		sync_sectr_api( & sectr_api, & memory, & logger )

		running = sectr_api.tick( duration_seconds( delta_ns ), delta_ns )
		sectr_api.clean_frame()

		delta_ns   = time.tick_lap_time( & host_tick )
		host_tick  = time.tick_now()
	}

	// Determine how the run_cyle completed, if it failed due to an error,
	// fallback the env to a failsafe state and reload the run_cycle.
	{
		// TODO(Ed): Implement this.
	}

	sectr_api.shutdown()
	unload_sectr_api( & sectr_api )

	log("Succesfuly closed")
	file_close( logger.file )
	// TODO(Ed) : Add string interning!!!!!!!!!
	// file_rename( logger.file_path, path_logger_finalized )
	file_rename( str_fmt_tmp( "%s/sectr.log",  Path_Logs), path_logger_finalized )
}
