package sectr

import    "base:runtime"
import    "core:os"
import c  "core:c/libc"
import rl "vendor:raylib"

poll_input :: proc( old, new : ^ InputState )
{
	profile(#procedure)
	input_process_digital_btn :: proc( old_state, new_state : ^ DigitalBtn, is_down : b32 )
	{
		new_state.ended_down = is_down
		had_transition := old_state.ended_down != new_state.ended_down
		if had_transition {
			new_state.half_transitions += 1
		}
		else {
			new_state.half_transitions = 0
		}
	}

	// Keyboard
	{
		// profile("Keyboard")
		check_range :: proc( old, new : ^ InputState, start, end : i32 )
		{
			for id := start; id < end; id += 1
			{
				// TODO(Ed) : LOOK OVER THIS...
				entry_old := & old.keyboard.keys[id - 1]
				entry_new := & new.keyboard.keys[id - 1]

				key_id := cast(KeyboardKey) id

				is_down := cast(b32) rl.IsKeyDown( to_raylib_key(id) )
				input_process_digital_btn( entry_old, entry_new, is_down )
			}
		}

		DeadBound_1 :: 0x0A
		DeadBound_2 :: 0x2E
		DeadBound_3 :: 0x19
		DeadBound_4 :: 0x3F
		check_range( old, new, cast(i32) KeyboardKey.enter,     DeadBound_1 )
		check_range( old, new, cast(i32) KeyboardKey.caps_lock, DeadBound_2 )
		check_range( old, new, cast(i32) KeyboardKey.escape,    DeadBound_3 )
		check_range( old, new, cast(i32) KeyboardKey.backtick,  DeadBound_4 )
		check_range( old, new, cast(i32) KeyboardKey.A,         cast(i32) KeyboardKey.count )

		swap( & old.keyboard_events.keys_pressed, & new.keyboard_events.keys_pressed )
		swap( & old.keyboard_events.chars_pressed, & new.keyboard_events.chars_pressed )

		array_clear( new.keyboard_events.keys_pressed )
		array_clear( new.keyboard_events.chars_pressed )

		for key_pressed := rl.GetKeyPressed(); key_pressed != rl.KeyboardKey.KEY_NULL; key_pressed = rl.GetKeyPressed() {
			array_append( & new.keyboard_events.keys_pressed, to_key_from_raylib(key_pressed))
		}
		for char_pressed := rl.GetCharPressed(); char_pressed != cast(rune)0; char_pressed = rl.GetCharPressed() {
			array_append( & new.keyboard_events.chars_pressed, char_pressed)
		}
	}

	// Mouse
	{
		// profile("Mouse")
		// Process Buttons
		for id : i32 = 0; id < i32(MouseBtn.count); id += 1
		{
			old_btn := & old.mouse.btns[id]
			new_btn := & new.mouse.btns[id]

			mouse_id := cast(MouseBtn) id

			is_down := cast(b32) rl.IsMouseButtonDown( to_raylib_mouse_btn(id) )
			input_process_digital_btn( old_btn, new_btn, is_down )
		}

		new.mouse.raw_pos        = rl.GetMousePosition()
		new.mouse.pos            = render_to_screen_pos(new.mouse.raw_pos)
		new.mouse.delta          = rl.GetMouseDelta() * {1, -1}
		new.mouse.vertical_wheel = rl.GetMouseWheelMove()
	}
}

record_input :: proc( replay_file : os.Handle, input : ^ InputState ) {
	raw_data := slice_ptr( transmute(^ byte) input, size_of(InputState) )
	file_write( replay_file, raw_data )
}

play_input :: proc( replay_file : os.Handle, input : ^ InputState ) {
	raw_data := slice_ptr( transmute(^ byte) input, size_of(InputState) )
	total_read, result_code := file_read( replay_file, raw_data )
	if result_code == os.ERROR_HANDLE_EOF {
		file_rewind( replay_file )
		load_snapshot( & Memory_App.snapshot )
	}
}

to_key_from_raylib :: proc( key : rl.KeyboardKey ) -> KeyboardKey {
	@static lookup_table := [?] KeyboardKey {
		KeyboardKey.null,
		KeyboardKey.enter,
		KeyboardKey.tab,
		KeyboardKey.space,
		KeyboardKey.bracket_open,
		KeyboardKey.bracket_close,
		KeyboardKey.semicolon,
		KeyboardKey.apostrophe,
		KeyboardKey.comma,
		KeyboardKey.period,
		cast(KeyboardKey) 0, // 0x0A
		cast(KeyboardKey) 0, // 0x0B
		cast(KeyboardKey) 0, // 0x0C
		cast(KeyboardKey) 0, // 0x0D
		cast(KeyboardKey) 0, // 0x0E
		cast(KeyboardKey) 0, // 0x0F
		KeyboardKey.caps_lock,
		KeyboardKey.scroll_lock,
		KeyboardKey.num_lock,
		KeyboardKey.left_alt,
		KeyboardKey.left_shit,
		KeyboardKey.left_control,
		KeyboardKey.right_alt,
		KeyboardKey.right_shift,
		KeyboardKey.right_control,
		cast(KeyboardKey) 0, // 0x0F
		cast(KeyboardKey) 0, // 0x0F
		cast(KeyboardKey) 0, // 0x0F
		cast(KeyboardKey) 0, // 0x0F
		cast(KeyboardKey) 0, // 0x0F
		cast(KeyboardKey) 0, // 0x0F
		cast(KeyboardKey) 0, // 0x0F
		KeyboardKey.escape,
		KeyboardKey.F1,
		KeyboardKey.F2,
		KeyboardKey.F3,
		KeyboardKey.F4,
		KeyboardKey.F5,
		KeyboardKey.F7,
		KeyboardKey.F8,
		KeyboardKey.F9,
		KeyboardKey.F10,
		KeyboardKey.F11,
		KeyboardKey.F12,
		KeyboardKey.print_screen,
		KeyboardKey.pause,
		cast(KeyboardKey) 0, // 0x2E
		KeyboardKey.backtick,
		KeyboardKey.nrow_0,
		KeyboardKey.nrow_1,
		KeyboardKey.nrow_2,
		KeyboardKey.nrow_3,
		KeyboardKey.nrow_4,
		KeyboardKey.nrow_5,
		KeyboardKey.nrow_6,
		KeyboardKey.nrow_7,
		KeyboardKey.nrow_8,
		KeyboardKey.nrow_9,
		KeyboardKey.hyphen,
		KeyboardKey.equals,
		KeyboardKey.backspace,
		KeyboardKey.backslash,
		KeyboardKey.slash,
		cast(KeyboardKey) 0, // 0x3F
		cast(KeyboardKey) 0, // 0x40
		KeyboardKey.A,
		KeyboardKey.B,
		KeyboardKey.C,
		KeyboardKey.D,
		KeyboardKey.E,
		KeyboardKey.F,
		KeyboardKey.G,
		KeyboardKey.H,
		KeyboardKey.I,
		KeyboardKey.J,
		KeyboardKey.K,
		KeyboardKey.L,
		KeyboardKey.M,
		KeyboardKey.N,
		KeyboardKey.O,
		KeyboardKey.P,
		KeyboardKey.Q,
		KeyboardKey.R,
		KeyboardKey.S,
		KeyboardKey.T,
		KeyboardKey.U,
		KeyboardKey.V,
		KeyboardKey.W,
		KeyboardKey.X,
		KeyboardKey.Y,
		KeyboardKey.Z,
		KeyboardKey.insert,
		KeyboardKey.delete,
		KeyboardKey.home,
		KeyboardKey.end,
		KeyboardKey.page_up,
		KeyboardKey.page_down,
		KeyboardKey.npad_0,
		KeyboardKey.npad_1,
		KeyboardKey.npad_2,
		KeyboardKey.npad_3,
		KeyboardKey.npad_4,
		KeyboardKey.npad_5,
		KeyboardKey.npad_6,
		KeyboardKey.npad_7,
		KeyboardKey.npad_8,
		KeyboardKey.npad_9,
		KeyboardKey.npad_decimal,
		KeyboardKey.npad_equals,
		KeyboardKey.npad_plus,
		KeyboardKey.npad_minus,
		KeyboardKey.npad_multiply,
		KeyboardKey.npad_divide,
		KeyboardKey.npad_enter, }
		return lookup_table[key]
}

to_raylib_key :: proc( key : i32 ) -> rl.KeyboardKey
{
	@static raylib_key_lookup_table := [?] rl.KeyboardKey {
		rl.KeyboardKey.KEY_NULL,
		rl.KeyboardKey.ENTER,
		rl.KeyboardKey.TAB,
		rl.KeyboardKey.SPACE,
		rl.KeyboardKey.LEFT_BRACKET,
		rl.KeyboardKey.RIGHT_BRACKET,
		rl.KeyboardKey.SEMICOLON,
		rl.KeyboardKey.APOSTROPHE,
		rl.KeyboardKey.COMMA,
		rl.KeyboardKey.PERIOD,
		cast(rl.KeyboardKey) 0, // 0x0A
		cast(rl.KeyboardKey) 0, // 0x0B
		cast(rl.KeyboardKey) 0, // 0x0C
		cast(rl.KeyboardKey) 0, // 0x0D
		cast(rl.KeyboardKey) 0, // 0x0E
		cast(rl.KeyboardKey) 0, // 0x0F
		rl.KeyboardKey.CAPS_LOCK,
		rl.KeyboardKey.SCROLL_LOCK,
		rl.KeyboardKey.NUM_LOCK,
		rl.KeyboardKey.LEFT_ALT,
		rl.KeyboardKey.LEFT_SHIFT,
		rl.KeyboardKey.LEFT_CONTROL,
		rl.KeyboardKey.RIGHT_ALT,
		rl.KeyboardKey.RIGHT_SHIFT,
		rl.KeyboardKey.RIGHT_CONTROL,
		cast(rl.KeyboardKey) 0, // 0x0F
		cast(rl.KeyboardKey) 0, // 0x0F
		cast(rl.KeyboardKey) 0, // 0x0F
		cast(rl.KeyboardKey) 0, // 0x0F
		cast(rl.KeyboardKey) 0, // 0x0F
		cast(rl.KeyboardKey) 0, // 0x0F
		cast(rl.KeyboardKey) 0, // 0x0F
		rl.KeyboardKey.ESCAPE,
		rl.KeyboardKey.F1,
		rl.KeyboardKey.F2,
		rl.KeyboardKey.F3,
		rl.KeyboardKey.F4,
		rl.KeyboardKey.F5,
		rl.KeyboardKey.F7,
		rl.KeyboardKey.F8,
		rl.KeyboardKey.F9,
		rl.KeyboardKey.F10,
		rl.KeyboardKey.F11,
		rl.KeyboardKey.F12,
		rl.KeyboardKey.PRINT_SCREEN,
		rl.KeyboardKey.PAUSE,
		cast(rl.KeyboardKey) 0, // 0x2E
		rl.KeyboardKey.GRAVE,
		cast(rl.KeyboardKey) '0',
		cast(rl.KeyboardKey) '1',
		cast(rl.KeyboardKey) '2',
		cast(rl.KeyboardKey) '3',
		cast(rl.KeyboardKey) '4',
		cast(rl.KeyboardKey) '5',
		cast(rl.KeyboardKey) '6',
		cast(rl.KeyboardKey) '7',
		cast(rl.KeyboardKey) '8',
		cast(rl.KeyboardKey) '9',
		rl.KeyboardKey.MINUS,
		rl.KeyboardKey.EQUAL,
		rl.KeyboardKey.BACKSPACE,
		rl.KeyboardKey.BACKSLASH,
		rl.KeyboardKey.SLASH,
		cast(rl.KeyboardKey) 0, // 0x3F
		cast(rl.KeyboardKey) 0, // 0x40
		rl.KeyboardKey.A,
		rl.KeyboardKey.B,
		rl.KeyboardKey.C,
		rl.KeyboardKey.D,
		rl.KeyboardKey.E,
		rl.KeyboardKey.F,
		rl.KeyboardKey.G,
		rl.KeyboardKey.H,
		rl.KeyboardKey.I,
		rl.KeyboardKey.J,
		rl.KeyboardKey.K,
		rl.KeyboardKey.L,
		rl.KeyboardKey.M,
		rl.KeyboardKey.N,
		rl.KeyboardKey.O,
		rl.KeyboardKey.P,
		rl.KeyboardKey.Q,
		rl.KeyboardKey.R,
		rl.KeyboardKey.S,
		rl.KeyboardKey.T,
		rl.KeyboardKey.U,
		rl.KeyboardKey.V,
		rl.KeyboardKey.W,
		rl.KeyboardKey.X,
		rl.KeyboardKey.Y,
		rl.KeyboardKey.Z,
		rl.KeyboardKey.INSERT,
		rl.KeyboardKey.DELETE,
		rl.KeyboardKey.HOME,
		rl.KeyboardKey.END,
		rl.KeyboardKey.PAGE_UP,
		rl.KeyboardKey.PAGE_DOWN,
		rl.KeyboardKey.KP_0,
		rl.KeyboardKey.KP_1,
		rl.KeyboardKey.KP_2,
		rl.KeyboardKey.KP_3,
		rl.KeyboardKey.KP_4,
		rl.KeyboardKey.KP_5,
		rl.KeyboardKey.KP_6,
		rl.KeyboardKey.KP_7,
		rl.KeyboardKey.KP_8,
		rl.KeyboardKey.KP_9,
		rl.KeyboardKey.KP_DECIMAL,
		rl.KeyboardKey.KP_EQUAL,
		rl.KeyboardKey.KP_ADD,
		rl.KeyboardKey.KP_SUBTRACT,
		rl.KeyboardKey.KP_MULTIPLY,
		rl.KeyboardKey.KP_DIVIDE,
		rl.KeyboardKey.KP_ENTER, }
	return raylib_key_lookup_table[ key ]
}

to_raylib_mouse_btn :: proc( btn : i32 ) -> rl.MouseButton {
	@static raylib_mouse_btn_lookup_table := [?] rl.MouseButton {
		rl.MouseButton.LEFT,
		rl.MouseButton.MIDDLE,
		rl.MouseButton.RIGHT,
		rl.MouseButton.SIDE,
		rl.MouseButton.FORWARD,
		rl.MouseButton.BACK,
		rl.MouseButton.EXTRA, }
	return raylib_mouse_btn_lookup_table[ btn ]
}
