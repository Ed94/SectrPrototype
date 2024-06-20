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

// TODO(Ed): May just use input event exclusively in the future and have pointers for key and mouse event filters
// I'm on the fence about this as I don't want to force 

InputKeyEvent :: struct {
	frame_id    : u64,
	type        : InputEventType,
	key         : KeyCode,
	modifiers   : ModifierCodeFlags,
}

InputMouseEvent :: struct {
	frame_id    : u64,
	type        : InputEventType,
	btn         : MouseBtn,
	pos         : Vec2,
	delta       : Vec2,
	scroll      : Vec2,
	modifiers   : ModifierCodeFlags,
}

InputEvents :: struct {
	events       : Queue(InputEvent),
	key_events   : Queue(InputKeyEvent),
	mouse_events : Queue(InputMouseEvent),

	codes_pressed : Array(rune),
}

// Note(Ed): There is a staged_input_events : Array(InputEvent), in the state.odin's State struct

append_staged_input_events :: #force_inline proc( event : InputEvent ) {
	// TODO(Ed) : Add guards for multi-threading

	state := get_state()
	append( & state.staged_input_events, event )
}

pull_staged_input_events :: proc(  input : ^InputState, input_events : ^InputEvents, staged_events : Array(InputEvent) )
{
	// TODO(Ed) : Add guards for multi-threading

	staged_events_slice := array_to_slice(staged_events)
	push( & input_events.events, staged_events_slice )

	using input_events

	for event in staged_events_slice
	{
		switch event.type {
			case .Key_Pressed:
				push( & key_events, InputKeyEvent {
					frame_id  = event.frame_id,
					type      = event.type,
					key       = event.key,
					modifiers = event.modifiers
				})
				// logf("Key pressed(event pushed): %v", event.key)
				// logf("last key event frame: %v", peek_back(& key_events).frame_id)
				// logf("last     event frame: %v", peek_back(& events).frame_id)

			case .Key_Released:
				push( & key_events, InputKeyEvent {
					frame_id  = event.frame_id,
					type      = event.type,
					key       = event.key,
					modifiers = event.modifiers
				})
				// logf("Key released(event rpushed): %v", event.key)
				// logf("last key event frame: %v", peek_back(& key_events).frame_id)
				// logf("last     event frame: %v", peek_back(& events).frame_id)

			case .Unicode:
				append( & codes_pressed, event.codepoint )

			case .Mouse_Pressed:
				push( & mouse_events, InputMouseEvent {
					frame_id    = event.frame_id,
					type        = event.type,
					btn         = event.mouse.btn,
					pos         = event.mouse.pos,
					delta       = event.mouse.delta,
					scroll      = event.mouse.scroll,
					modifiers   = event.modifiers,
				})

			case .Mouse_Released:
				push( & mouse_events, InputMouseEvent {
					frame_id    = event.frame_id,
					type        = event.type,
					btn         = event.mouse.btn,
					pos         = event.mouse.pos,
					delta       = event.mouse.delta,
					scroll      = event.mouse.scroll,
					modifiers   = event.modifiers,
				})

			case .Mouse_Scroll:
				push( & mouse_events, InputMouseEvent {
					frame_id    = event.frame_id,
					type        = event.type,
					btn         = event.mouse.btn,
					pos         = event.mouse.pos,
					delta       = event.mouse.delta,
					scroll      = event.mouse.scroll,
					modifiers   = event.modifiers,
				})
			case .Mouse_Move:
				push( & mouse_events, InputMouseEvent {
					frame_id    = event.frame_id,
					type        = event.type,
					btn         = event.mouse.btn,
					pos         = event.mouse.pos,
					delta       = event.mouse.delta,
					scroll      = event.mouse.scroll,
					modifiers   = event.modifiers,
				})

			case .Mouse_Enter:
				push( & mouse_events, InputMouseEvent {
					frame_id    = event.frame_id,
					type        = event.type,
					btn         = event.mouse.btn,
					pos         = event.mouse.pos,
					delta       = event.mouse.delta,
					scroll      = event.mouse.scroll,
					modifiers   = event.modifiers,
				})

			case .Mouse_Leave:
				push( & mouse_events, InputMouseEvent {
					frame_id    = event.frame_id,
					type        = event.type,
					btn         = event.mouse.btn,
					pos         = event.mouse.pos,
					delta       = event.mouse.delta,
					scroll      = event.mouse.scroll,
					modifiers   = event.modifiers,
				})
		}
	}

	clear( staged_events )
}

poll_input_events :: proc( input, prev_input : ^InputState, input_events : InputEvents )
{
	input.keyboard = {}
	input.mouse    = {}

	// logf("m's value is: %v (prev)", prev_input.keyboard.keys[KeyCode.M] )

	for prev_key, id in prev_input.keyboard.keys {
		input.keyboard.keys[id].ended_down = prev_key.ended_down
	}

	for prev_btn, id in prev_input.mouse.btns {
		input.mouse.btns[id].ended_down = prev_btn.ended_down
	}

	input.mouse.raw_pos = prev_input.mouse.raw_pos
	input.mouse.pos     = prev_input.mouse.pos

	input_events := input_events
	using input_events

	@static prev_frame : u64 = 0

	last_frame : u64 = 0
	if events.len > 0 {
		last_frame = peek_back( & events).frame_id
	}

	// No new events, don't update
	if last_frame == prev_frame do return

	Iterate_Key_Events:
	{
		iter_obj  := iterator( key_events ); iter := & iter_obj
		for event := next( iter ); event != nil; event = next( iter )
		{
			if last_frame > event.frame_id {
				break
			}
			// logf("last_frame (iter): %v", last_frame)
			// logf("frame      (iter): %v", event.frame_id )

			key      := & input.keyboard.keys[event.key]
			prev_key :=   prev_input.keyboard.keys[event.key]

			first_transition := key.half_transitions == 0

			#partial switch event.type {
				case .Key_Pressed:
					key.half_transitions += 1
					key.ended_down        = true

				case .Key_Released:
					key.half_transitions += 1
					key.ended_down        = false
			}
		}
	}

	Iterate_Mouse_Events:
	{
		iter_obj  := iterator( mouse_events ); iter := & iter_obj
		for event := next( iter ); event != nil; event = next( iter )
		{
			if last_frame > event.frame_id {
				break
			}

			process_digital_btn :: proc( btn : ^DigitalBtn, prev_btn : DigitalBtn, ended_down : b32 )
			{
				first_transition := btn.half_transitions == 0

				btn.half_transitions += 1
				btn.ended_down        = ended_down
			}

			#partial switch event.type {
				case .Mouse_Pressed:
					btn      := & input.mouse.btns[event.btn]
					prev_btn :=   prev_input.mouse.btns[event.btn]
					process_digital_btn( btn, prev_btn, true )

				case .Mouse_Released:
					btn      := & input.mouse.btns[event.btn]
					prev_btn :=   prev_input.mouse.btns[event.btn]
					process_digital_btn( btn, prev_btn, false )

				case .Mouse_Scroll:
					input.mouse.scroll += event.scroll.x

				case .Mouse_Move:
				case .Mouse_Enter:
				case .Mouse_Leave:
					// Handled below
			}

			input.mouse.raw_pos = event.pos
			input.mouse.pos     = render_to_screen_pos( event.pos )
			input.mouse.delta   = event.delta
		}
	}

	prev_frame = last_frame
}
