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
		result := os.remove( path )
		verify( result != os.ERROR_NONE, "Failed to delete replay file before beginning a new one" )
	}

	replay_file, open_error := os.open( path, os.O_RDWR | os.O_CREATE )
	verify( open_error != os.ERROR_NONE, "Failed to create or open the replay file" )

	os.seek( replay_file, 0, 0 )

	replay := & memory.replay
	replay.active_file = replay_file
	replay.mode        = ReplayMode.Record
}

replay_recording_end :: proc() {
	replay := & memory.replay
	replay.mode = ReplayMode.Off

	os.seek( replay.active_file, 0, 0 )
	os.close( replay.active_file )
}

replay_playback_begin :: proc( path : string )
{
	verify( ! file_exists( path ), "Failed to find replay file" )

	replay_file, open_error := os.open( path, os.O_RDWR | os.O_CREATE )
	verify( open_error != os.ERROR_NONE, "Failed to create or open the replay file" )

	os.seek( replay_file, 0, 0 )

	replay := & memory.replay
	replay.active_file = replay_file
	replay.mode        = ReplayMode.Playback
}

replay_playback_end :: proc() {
	input  := get_state().input
	replay := & memory.replay
	replay.mode = ReplayMode.Off
	os.seek( replay.active_file, 0, 0 )
	os.close( replay.active_file )
}
