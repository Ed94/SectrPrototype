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

				key_id := cast(KeyCode) id

				is_down := cast(b32) rl.IsKeyDown( to_raylib_key(id) )
				input_process_digital_btn( entry_old, entry_new, is_down )
			}
		}

		DeadBound_1 :: 0x02
		DeadBound_2 :: 0x0F
		DeadBound_3 :: 0x19
		DeadBound_4 :: 0x3A
		check_range( old, new, cast(i32) KeyCode.backspace, DeadBound_2 )
		check_range( old, new, cast(i32) KeyCode.caps_lock, DeadBound_3 )
		check_range( old, new, cast(i32) KeyCode.pause,     DeadBound_4 )
		check_range( old, new, cast(i32) KeyCode.semicolon, cast(i32) KeyCode.count )

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

to_raylib_key :: proc( key : i32 ) -> rl.KeyboardKey
{
	@static raylib_key_lookup_table := [KeyCode.count] rl.KeyboardKey {
		rl.KeyboardKey.KEY_NULL, // 0x00

		cast(rl.KeyboardKey) 0, // 0x01

		cast(rl.KeyboardKey) 0, // 0x02
		cast(rl.KeyboardKey) 0, // 0x03
		cast(rl.KeyboardKey) 0, // 0x04
		cast(rl.KeyboardKey) 0, // 0x05
		cast(rl.KeyboardKey) 0, // 0x06
		cast(rl.KeyboardKey) 0, // 0x07

		rl.KeyboardKey.BACKSPACE, // 0x08
		rl.KeyboardKey.TAB,       // 0x09

		rl.KeyboardKey.RIGHT,     // 0x0A
		rl.KeyboardKey.LEFT,      // 0x0B
		rl.KeyboardKey.DOWN,      // 0x0C
		rl.KeyboardKey.UP,        // 0x0D

		rl.KeyboardKey.ENTER,     // 0x0E

		cast(rl.KeyboardKey) 0,   // 0x0F

		rl.KeyboardKey.CAPS_LOCK,    // 0x10
		rl.KeyboardKey.SCROLL_LOCK,  // 0x11
		rl.KeyboardKey.NUM_LOCK,     // 0x12

		rl.KeyboardKey.LEFT_ALT,      // 0x13
		rl.KeyboardKey.LEFT_SHIFT,    // 0x14
		rl.KeyboardKey.LEFT_CONTROL,  // 0x15
		rl.KeyboardKey.RIGHT_ALT,     // 0x16
		rl.KeyboardKey.RIGHT_SHIFT,   // 0x17
		rl.KeyboardKey.RIGHT_CONTROL, // 0x18

		cast(rl.KeyboardKey) 0, // 0x19

		rl.KeyboardKey.PAUSE,      // 0x1A
		rl.KeyboardKey.ESCAPE,     // 0x1B
		rl.KeyboardKey.HOME,       // 0x1C
		rl.KeyboardKey.END,        // 0x1D
		rl.KeyboardKey.PAGE_UP,    // 0x1E
		rl.KeyboardKey.PAGE_DOWN,  // 0x1F
		rl.KeyboardKey.SPACE,      // 0x20

		cast(rl.KeyboardKey) '!',  // 0x21
		cast(rl.KeyboardKey) '"',  // 0x22
		cast(rl.KeyboardKey) '#',  // 0x23
		cast(rl.KeyboardKey) '$',  // 0x24
		cast(rl.KeyboardKey) '%',  // 0x25
		cast(rl.KeyboardKey) '&',  // 0x26
		cast(rl.KeyboardKey) '\'', // 0x27
		cast(rl.KeyboardKey) '(',  // 0x28
		cast(rl.KeyboardKey) ')',  // 0x29
		cast(rl.KeyboardKey) '*',  // 0x2A
		cast(rl.KeyboardKey) '+',  // 0x2B
		cast(rl.KeyboardKey) ',',  // 0x2C
		cast(rl.KeyboardKey) '-',  // 0x2D
		cast(rl.KeyboardKey) '.',  // 0x2E
		cast(rl.KeyboardKey) '/',  // 0x2F

		cast(rl.KeyboardKey) '0',  // 0x30
		cast(rl.KeyboardKey) '1',  // 0x31
		cast(rl.KeyboardKey) '2',  // 0x32
		cast(rl.KeyboardKey) '3',  // 0x33
		cast(rl.KeyboardKey) '4',  // 0x34
		cast(rl.KeyboardKey) '5',  // 0x35
		cast(rl.KeyboardKey) '6',  // 0x36
		cast(rl.KeyboardKey) '7',  // 0x37
		cast(rl.KeyboardKey) '8',  // 0x38
		cast(rl.KeyboardKey) '9',  // 0x39

		cast(rl.KeyboardKey) 0,   // 0x3A

		cast(rl.KeyboardKey) ';', // 0x3B
		cast(rl.KeyboardKey) '<', // 0x3C
		cast(rl.KeyboardKey) '=', // 0x3D
		cast(rl.KeyboardKey) '>', // 0x3E
		cast(rl.KeyboardKey) '?', // 0x3F
		cast(rl.KeyboardKey) '@', // 0x40

		rl.KeyboardKey.A, // 0x41
		rl.KeyboardKey.B, // 0x42
		rl.KeyboardKey.C, // 0x43
		rl.KeyboardKey.D, // 0x44
		rl.KeyboardKey.E, // 0x45
		rl.KeyboardKey.F, // 0x46
		rl.KeyboardKey.G, // 0x47
		rl.KeyboardKey.H, // 0x48
		rl.KeyboardKey.I, // 0x49
		rl.KeyboardKey.J, // 0x4A
		rl.KeyboardKey.K, // 0x4B
		rl.KeyboardKey.L, // 0x4C
		rl.KeyboardKey.M, // 0x4D
		rl.KeyboardKey.N, // 0x4E
		rl.KeyboardKey.O, // 0x4F
		rl.KeyboardKey.P, // 0x50
		rl.KeyboardKey.Q, // 0x51
		rl.KeyboardKey.R, // 0x52
		rl.KeyboardKey.S, // 0x53
		rl.KeyboardKey.T, // 0x54
		rl.KeyboardKey.U, // 0x55
		rl.KeyboardKey.V, // 0x56
		rl.KeyboardKey.W, // 0x57
		rl.KeyboardKey.X, // 0x58
		rl.KeyboardKey.Y, // 0x59
		rl.KeyboardKey.Z, // 0x5A

		rl.KeyboardKey.LEFT_BRACKET,   // 0x5B
		rl.KeyboardKey.BACKSLASH,      // 0x5C
		rl.KeyboardKey.RIGHT_BRACKET,  // 0x5D
		cast(rl.KeyboardKey) '^',      // 0x5E
		rl.KeyboardKey.GRAVE,          // 0x5F
		cast(rl.KeyboardKey) '`',      // 0x60

		rl.KeyboardKey.KP_0,        // 0x61
		rl.KeyboardKey.KP_1,        // 0x62
		rl.KeyboardKey.KP_2,        // 0x63
		rl.KeyboardKey.KP_3,        // 0x64
		rl.KeyboardKey.KP_4,        // 0x65
		rl.KeyboardKey.KP_5,        // 0x66
		rl.KeyboardKey.KP_6,        // 0x67
		rl.KeyboardKey.KP_7,        // 0x68
		rl.KeyboardKey.KP_8,        // 0x69
		rl.KeyboardKey.KP_9,        // 0x6A
		rl.KeyboardKey.KP_DECIMAL,  // 0x6B
		rl.KeyboardKey.KP_EQUAL,    // 0x6C
		rl.KeyboardKey.KP_ADD,      // 0x6D
		rl.KeyboardKey.KP_SUBTRACT, // 0x6E
		rl.KeyboardKey.KP_MULTIPLY, // 0x6F
		rl.KeyboardKey.KP_DIVIDE,   // 0x70
		rl.KeyboardKey.KP_ENTER,    // 0x71

		rl.KeyboardKey.F1,  // 0x72
		rl.KeyboardKey.F2,  // 0x73
		rl.KeyboardKey.F3,  // 0x74
		rl.KeyboardKey.F4,  // 0x75
		rl.KeyboardKey.F5,  // 0x76
		rl.KeyboardKey.F6,  // 0x77
		rl.KeyboardKey.F7,  // 0x78
		rl.KeyboardKey.F8,  // 0x79
		rl.KeyboardKey.F9,  // 0x7A
		rl.KeyboardKey.F10, // 0x7B
		rl.KeyboardKey.F11, // 0x7C
		rl.KeyboardKey.F12, // 0x7D

		rl.KeyboardKey.INSERT, // 0x7E
		rl.KeyboardKey.DELETE, // 0x7F
	}
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

to_key_from_raylib :: proc( ray_key : rl.KeyboardKey ) -> (key : KeyCode) {

	switch (ray_key) {
		case .KEY_NULL     : key = cast(KeyCode) ray_key

		case .SPACE,
				cast(rl.KeyboardKey) '!',
				cast(rl.KeyboardKey) '"',
				cast(rl.KeyboardKey) '#',
				cast(rl.KeyboardKey) '$',
				cast(rl.KeyboardKey) '%',
				cast(rl.KeyboardKey) '&',
				.APOSTROPHE,
				cast(rl.KeyboardKey) '(',
				cast(rl.KeyboardKey) ')',
				cast(rl.KeyboardKey) '*',
				cast(rl.KeyboardKey) '+',
				.COMMA, .MINUS, .PERIOD, .SLASH,
				.ZERO, .ONE, .TWO, .THREE, .FOUR, .FIVE, .SIX, .SEVEN, .EIGHT, .NINE,
				.SEMICOLON,.EQUAL,
				.A, .B, .C, .D, .E, .F, .G, .H, .I, .J, .K, .L, .M, .N, .O, .P, .Q, .R, .S, .T, .U, .V, .W, .X, .Y, .Z,
				.LEFT_BRACKET, .BACKSLASH, .RIGHT_BRACKET, cast(rl.KeyboardKey) '_', .GRAVE :
			key = cast(KeyCode) ray_key

		case .ESCAPE        : key = KeyCode.escape
		case .ENTER         : key = KeyCode.enter
		case .TAB           : key = KeyCode.tab
		case .BACKSPACE     : key = KeyCode.backspace

		case .INSERT        : key = KeyCode.insert
		case .DELETE        : key = KeyCode.delete

		case .RIGHT         : key = KeyCode.right
		case .LEFT          : key = KeyCode.left
		case .UP            : key = KeyCode.up
		case .DOWN          : key = KeyCode.down

		case .PAGE_UP       : key = KeyCode.page_up
		case .PAGE_DOWN     : key = KeyCode.page_down
		case .HOME          : key = KeyCode.home
		case .END           : key = KeyCode.end
		case .CAPS_LOCK     : key = KeyCode.caps_lock
		case .SCROLL_LOCK   : key = KeyCode.scroll_lock
		case .NUM_LOCK      : key = KeyCode.num_lock
		case .PRINT_SCREEN  : key = KeyCode.ignored
		case .PAUSE         : key = KeyCode.pause

		case .F1            : key = KeyCode.F1
		case .F2            : key = KeyCode.F2
		case .F3            : key = KeyCode.F3
		case .F4            : key = KeyCode.F4
		case .F5            : key = KeyCode.F5
		case .F6            : key = KeyCode.F6
		case .F7            : key = KeyCode.F7
		case .F8            : key = KeyCode.F8
		case .F9            : key = KeyCode.F9
		case .F10           : key = KeyCode.F10
		case .F11           : key = KeyCode.F11
		case .F12           : key = KeyCode.F12

		case .LEFT_SHIFT    : key = KeyCode.left_shift
		case .LEFT_CONTROL  : key = KeyCode.left_control
		case .LEFT_ALT      : key = KeyCode.left_alt
		case .LEFT_SUPER    : key = KeyCode.ignored
		case .RIGHT_SHIFT   : key = KeyCode.right_shift
		case .RIGHT_CONTROL : key = KeyCode.right_control
		case .RIGHT_ALT     : key = KeyCode.right_alt
		case .RIGHT_SUPER   : key = KeyCode.ignored
		case .KB_MENU       : key = KeyCode.ignored

		case .KP_0          : key = KeyCode.kpad_0
		case .KP_1          : key = KeyCode.kpad_1
		case .KP_2          : key = KeyCode.kpad_2
		case .KP_3          : key = KeyCode.kpad_3
		case .KP_4          : key = KeyCode.kpad_4
		case .KP_5          : key = KeyCode.kpad_5
		case .KP_6          : key = KeyCode.kpad_6
		case .KP_7          : key = KeyCode.kpad_7
		case .KP_8          : key = KeyCode.kpad_8
		case .KP_9          : key = KeyCode.kpad_9

		case .KP_DECIMAL    : key = KeyCode.kpad_decimal
		case .KP_DIVIDE     : key = KeyCode.kpad_divide
		case .KP_MULTIPLY   : key = KeyCode.kpad_multiply
		case .KP_SUBTRACT   : key = KeyCode.kpad_minus
		case .KP_ADD        : key = KeyCode.kpad_plus
		case .KP_ENTER      : key = KeyCode.kpad_enter
		case .KP_EQUAL      : key = KeyCode.kpad_equals

		case .BACK          : key = KeyCode.ignored
		case .VOLUME_UP     : key = KeyCode.ignored
		case .VOLUME_DOWN   : key = KeyCode.ignored
	}
	return
}
