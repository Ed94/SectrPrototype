/*
Workspace : A canvas for compositoning a view for the codebase along with notes.

Each workspace viewport supports both a canvas composition of code frames
or frame tiling towards the application's screenspace.
*/
package sectr

Workspace :: struct {
	name : StrCached,

	cam         : Camera,
	zoom_target : f32,

	frames : Array(Frame),

	test_frame : Frame,

	// TODO(Ed) : The workspace is mainly a 'UI' conceptually...
	ui : UI_State,
}

// Top level widgets for the workspace
Frame :: struct {
	pos  : Vec2,
	size : Vec2,

	ui : UI_Widget,
}

CodeFrame :: struct {
	readonly : b32, // Should this frame allow editing?

}

NoteFrame :: struct {

}
