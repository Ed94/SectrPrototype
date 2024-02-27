package sectr

import "core:os"

ReplayMode :: enum {
	Off,
	Record,
	Playback,
}

ReplayState :: struct {
	loop_active : b32,
	mode        : ReplayMode,
	active_file : os.Handle
}

replay_recording_begin :: proc( path : string )
{
	if file_exists( path ) {
		result := file_remove( path )
		verify( result != os.ERROR_NONE, "Failed to delete replay file before beginning a new one" )
	}

	replay_file, open_error := file_open( path, FileFlag_ReadWrite | FileFlag_Create )
	verify( open_error != os.ERROR_NONE, "Failed to create or open the replay file" )

	file_seek( replay_file, 0, 0 )

	replay := & Memory_App.replay
	replay.active_file = replay_file
	replay.mode        = ReplayMode.Record
}

replay_recording_end :: proc() {
	replay := & Memory_App.replay
	replay.mode = ReplayMode.Off

	file_seek( replay.active_file, 0, 0 )
	file_close( replay.active_file )
}

replay_playback_begin :: proc( path : string )
{
	verify( ! file_exists( path ), "Failed to find replay file" )

	replay_file, open_error := file_open( path, FileFlag_ReadWrite | FileFlag_Create )
	verify( open_error != os.ERROR_NONE, "Failed to create or open the replay file" )

	file_seek( replay_file, 0, 0 )

	replay := & Memory_App.replay
	replay.active_file = replay_file
	replay.mode        = ReplayMode.Playback
}

replay_playback_end :: proc() {
	input  := get_state().input
	replay := & Memory_App.replay
	replay.mode = ReplayMode.Off
	file_seek( replay.active_file, 0, 0 )
	file_close( replay.active_file )
}
