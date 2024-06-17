package sectr

InputEventType :: enum u32 {
	Key_Pressed,
	Key_Released,
	Mouse_Pressed,
	Mouse_Released,
	Mouse_Scroll,
	Mouse_Move,
	Mouse_Enter,
	Mouse_Leave,
	Unicode,
}

InputEvent :: struct
{
	frame_id    : u64,
	type        : InputEventType,
	key         : KeyCode,
	modifiers   : ModifierCodeFlags,
	mouse       : struct {
		btn    : MouseBtn,
		pos    : Vec2,
		delta  : Vec2,
		scroll : Vec2,
	},
	codepoint : rune,

	// num_touches : u32,
	// touches     : Touchpoint,

	_sokol_frame_id : u64,
}

InputKeyEvent :: struct {
	frame_id    : u64,
	type        : InputEventType,
	key         : KeyCode,
	modifiers   : ModifierCodeFlags,
}

InputMouseEvent :: struct {
	frame_id    : u64,
	type        : InputEventType,
	key         : KeyCode,
	modifiers   : ModifierCodeFlags,
}

// Note(Ed): There is a staged_input_events : Array(InputEvent), in the state.odin's State struct

append_staged_input_events :: #force_inline proc() {
	// TODO(Ed) : Add guards for multi-threading

	state := get_state()
	array_append( & state.staged_input_events, event )
}

pull_staged_input_events :: proc(  input : ^InputState, staged_events : ^Array(InputEvent) )
{
	// TODO(Ed) : Add guards for multi-threading

	
}
