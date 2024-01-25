package host

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
import       "core:runtime"
import       "core:strings"
import       "core:time"
import rl    "vendor:raylib"
import sectr "../."

path_snapshot :: "VMemChunk_1.snapshot"

RuntimeState :: struct {
	running   : b32,
	memory    : VMemChunk,
	sectr_api : sectr.ModuleAPI,
}

VMemChunk :: struct {
	sarena            : virtual.Arena,
	host_persistent   : ^ mem.Arena,
	host_transient    : ^ mem.Arena,
	sectr_persistent  : ^ mem.Arena,
	sectr_transient   : ^ mem.Arena,
	sectr_temp        : ^ mem.Arena,

	// snapshot : 
}

setup_engine_memory :: proc () -> VMemChunk
{
	memory : VMemChunk; using memory

	Arena      :: mem.Arena
	arena_init :: mem.arena_init
	ptr_offset :: mem.ptr_offset
	slice_ptr  :: mem.slice_ptr

	chunk_size :: 2 * Gigabyte

	// Setup the static arena for the entire application
	if  result := virtual.arena_init_static( & sarena, chunk_size, chunk_size );
		result != runtime.Allocator_Error.None
	{
		// TODO(Ed) : Setup a proper logging interface
		fmt.    printf( "Failed to allocate memory for the engine" )
		runtime.debug_trap()
		os.     exit( -1 )
		// TODO(Ed) : Figure out the error code enums..
	}

	arena_size :: size_of( Arena)

	persistent_size       :: Megabyte * 128 * 2
	transient_size        :: (chunk_size - persistent_size * 2) / 2
	host_persistent_size  :: persistent_size / 4 - arena_size
	host_transient_size   :: transient_size  / 4 - arena_size
	sectr_persistent_size :: persistent_size - host_persistent_size - arena_size
	sectr_trans_temp_size :: (transient_size - host_transient_size) / 2 - arena_size

	block := memory.sarena.curr_block

	// We assign the beginning of the block to be the host's persistent memory's arena.
	// Then we offset past the arena and determine its slice to be the amount left after for the size of host's persistent.
	host_persistent        = cast( ^ Arena ) block.base
	host_persistent_slice := slice_ptr( ptr_offset( block.base, arena_size), host_persistent_size)
	arena_init( host_persistent, host_persistent_slice )

	// Initialize a sub-section of our virtual memory as a sub-arena
	sub_arena_init :: proc( address : ^ byte, size : int ) -> ( ^ Arena) {
		sub_arena := cast( ^ Arena ) address
		mem_slice := slice_ptr( ptr_offset( address, arena_size), size )
		arena_init( sub_arena, mem_slice )
		return sub_arena
	}

	// Helper to get the the beginning of memory after a slice
	next :: proc( slice : []byte ) -> ( ^ byte) {
		return ptr_offset( & slice[0], len(slice) )
	}

	host_transient   = sub_arena_init( next( host_persistent.data),  host_transient_size)
	sectr_persistent = sub_arena_init( next( host_transient.data),   sectr_persistent_size)
	sectr_transient  = sub_arena_init( next( sectr_persistent.data), sectr_trans_temp_size)
	sectr_temp       = sub_arena_init( next( sectr_transient.data),  sectr_trans_temp_size)
	return memory;
}

setup_snapshot_memory :: proc ()

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

	lock_file := fmt.tprintf( "sectr_{0}_locked.dll", version_id )
	sectr.copy_file_sync( "sectr.dll", lock_file )

	lib, load_result := dynlib.load_library( lock_file )
	if ! load_result {
		fmt.    println( "Failed to load the sectr module." )
		runtime.debug_trap()
		return {}
	}

	startup  := cast( type_of( sectr.startup        )) dynlib.symbol_address( lib, "startup" )
	shutdown := cast( type_of( sectr.sectr_shutdown )) dynlib.symbol_address( lib, "sectr_shutdown" )
	reload   := cast( type_of( sectr.reload         )) dynlib.symbol_address( lib, "reload" )
	update   := cast( type_of( sectr.update         )) dynlib.symbol_address( lib, "update" )
	render   := cast( type_of( sectr.render         )) dynlib.symbol_address( lib, "render" )

	missing_symbol : b32 = false
	if startup  == nil do fmt.println("Failed to load sectr.startup symbol")
	if shutdown == nil do fmt.println("Failed to load sectr.shutdown symbol")
	if reload   == nil do fmt.println("Failed to load sectr.reload symbol")
	if update   == nil do fmt.println("Failed to load sectr.update symbol")
	if render   == nil do fmt.println("Failed to load sectr.render symbol")
	if missing_symbol {
		runtime.debug_trap()
		return {}
	}

	loaded_module = {
		lib         = lib,
		write_time  = write_time,
		lib_version = version_id,

		startup  = startup,
		shutdown = shutdown,
		reload   = reload,
		update   = update,
		render   = render,
	}
	return loaded_module
}

unload_sectr_api :: proc ( module : ^ sectr.ModuleAPI )
{
	lock_file := fmt.tprintf( "sectr_{0}_locked.dll", module.lib_version )
	dynlib.unload_library( module.lib )
	// os.remove( lock_file )
	module^ = {}
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
		memory                 = setup_engine_memory()
		context.allocator      = mem.arena_allocator( memory.host_persistent )
		context.temp_allocator = mem.arena_allocator( memory.host_transient )
	}

	// Load the Enviornment API for the first-time
	{
		   sectr_api = load_sectr_api( 1 )
		if sectr_api.lib_version == 0 {
			fmt.    println( "Failed to initially load the sectr module" )
			runtime.debug_trap()
			os.     exit( -1 )
		}
	}

	running            = true;
	memory             = memory
	sectr_api          = sectr_api
	sectr_api.startup( memory.sectr_persistent, memory.sectr_transient, memory.sectr_temp )

	// TODO(Ed) : This should have an end status so that we know the reason the engine stopped.
	for ; running ;
	{
		// Hot-Reload
		if write_time, result := os.last_write_time_by_name("sectr.dll");
			result == os.ERROR_NONE && sectr_api.write_time != write_time
		{
			version_id := sectr_api.lib_version + 1
			unload_sectr_api( & sectr_api )

			// Wait for pdb to unlock (linker may still be writting)
			for ; sectr.is_file_locked( "sectr.pdb" ); {
			}
			time.sleep( time.Second * 10 )

			sectr_api = load_sectr_api( version_id )
			if sectr_api.lib_version == 0 {
				fmt.println("Failed to hot-reload the sectr module")
				runtime.debug_trap()
				os.exit(-1)
			}
			sectr_api.reload( memory.sectr_persistent, memory.sectr_transient, memory.sectr_temp )
		}

		running = sectr_api.update()
		sectr_api.render()

		free_all( mem.arena_allocator( memory.sectr_temp ) )
		// free_all( mem.arena_allocator( & memory.env_transient ) )
	}

	// Determine how the run_cyle completed, if it failed due to an error,
	// fallback the env to a failsafe state and reload the run_cycle.
	{
		// TODO(Ed): Implement this.
	}

	sectr_api.shutdown()
	unload_sectr_api( & sectr_api )
}
