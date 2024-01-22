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

RuntimeState :: struct {
	running   : b32,
	memory    : VMemChunk,
	sectr_api : sectr.ModuleAPI,
}

VMemChunk :: struct {
	sarena         : virtual.Arena,
	eng_persistent : mem.Arena,
	eng_transient  : mem.Arena,
	env_persistent : mem.Arena,
	env_transient  : mem.Arena,
	env_temp       : mem.Arena
}

setup_engine_memory :: proc () -> VMemChunk
{
	memory : VMemChunk; using memory

	arena_init :: mem.arena_init
	ptr_offset :: mem.ptr_offset
	slice_ptr  :: mem.slice_ptr

	// Setup the static arena for the entire application
	if  result := virtual.arena_init_static( & sarena, Gigabyte * 2, Gigabyte * 2 );
		result != runtime.Allocator_Error.None
	{
		// TODO(Ed) : Setup a proper logging interface
		fmt.    printf( "Failed to allocate memory for the engine" )
		runtime.debug_trap()
		os.     exit( -1 )
		// TODO(Ed) : Figure out the error code enums..
	}

	// For now I'm making persistent sections each 128 meg and transient sections w/e is left over / 2 (one for engine the other for the env)
	persistent_size     :: Megabyte * 128 * 2
	transient_size      :: (Gigabyte * 2 - persistent_size * 2) / 2
	eng_persistent_size :: persistent_size / 4
	eng_transient_size  :: transient_size  / 4
	env_persistent_size :: persistent_size - eng_persistent_size
	env_trans_temp_size :: (transient_size  - eng_transient_size) / 2

	block := memory.sarena.curr_block

	// Try to get a slice for each segment
	eng_persistent_slice := slice_ptr( block.base,                                       eng_persistent_size)
	eng_transient_slice  := slice_ptr( & eng_persistent_slice[ eng_persistent_size - 1], eng_transient_size)
	env_persistent_slice := slice_ptr( & eng_transient_slice [ eng_transient_size  - 1], env_persistent_size)
	env_transient_slice  := slice_ptr( & env_persistent_slice[ env_persistent_size - 1], env_trans_temp_size)
	env_temp_slice       := slice_ptr( & env_transient_slice [ env_trans_temp_size - 1], env_trans_temp_size)
	arena_init( & eng_persistent, eng_persistent_slice )
	arena_init( & eng_transient,  eng_transient_slice  )
	arena_init( & env_persistent, env_persistent_slice )
	arena_init( & env_transient,  env_transient_slice  )
	arena_init( & env_temp,       env_temp_slice       )
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
		render   = render
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
		context.allocator      = mem.arena_allocator( & memory.eng_persistent )
		context.temp_allocator = mem.arena_allocator( & memory.eng_transient )
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
	sectr_api.startup( & memory.env_persistent, & memory.env_transient, & memory.env_temp )

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
			time.sleep( time.Millisecond )

			sectr_api = load_sectr_api( version_id )
			if sectr_api.lib_version == 0 {
				fmt.println("Failed to hot-reload the sectr module")
				runtime.debug_trap()
				os.exit(-1)
			}
			sectr_api.reload( & memory.env_persistent, & memory.env_transient, & memory.env_temp )
		}

		running = sectr_api.update()
		sectr_api.render()

		free_all( mem.arena_allocator( & memory.env_temp ) )
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
