// TODO(Ed) : This if its gets larget can be moved to its own package
package sectr

import "base:runtime"

AnalogAxis  :: f32
AnalogStick :: struct {
	X, Y : f32
}

DigitalBtn :: struct {
	half_transitions : i32,
	ended_down       : b32
}

btn_pressed :: proc( btn : DigitalBtn ) -> b32 {
	return btn.ended_down && btn.half_transitions > 0
}

btn_released :: proc ( btn : DigitalBtn ) -> b32 {
	return btn.ended_down == false && btn.half_transitions > 0
}

MaxKeyboardKeys :: 256
KeyboardKey :: enum u32 {
	null = 0x00,

	enter         = 0x01,
	tab           = 0x02,
	space         = 0x03,
	bracket_open  = 0x04,
	bracket_close = 0x05,
	semicolon     = 0x06,
	apostrophe    = 0x07,
	comma         = 0x08,
	period        = 0x09,

	// 0x0A
	// 0x0B
	// 0x0C
	// 0x0D
	// 0x0E
	// 0x0F

	caps_lock     = 0x10,
	scroll_lock   = 0x11,
	num_lock      = 0x12,
	left_alt      = 0x13,
	left_shit     = 0x14,
	left_control  = 0x15,
	right_alt     = 0x16,
	right_shift   = 0x17,
	right_control = 0x18,

	// 0x19
	// 0x1A
	// 0x1B
	// 0x1C
	// 0x1D
	// 0x1C
	// 0x1D

	escape = 0x1F,
	F1     = 0x20,
	F2     = 0x21,
	F3     = 0x22,
	F4     = 0x23,
	F5     = 0x24,
	F6     = 0x25,
	F7     = 0x26,
	F8     = 0x27,
	F9     = 0x28,
	F10    = 0x29,
	F11    = 0x2A,
	F12    = 0x2B,

	print_screen = 0x2C,
	pause        = 0x2D,
	// = 0x2E,

	backtick      = 0x2F,
	nrow_0        = 0x30,
	nrow_1        = 0x31,
	nrow_2        = 0x32,
	nrow_3        = 0x33,
	nrow_4        = 0x34,
	nrow_5        = 0x35,
	nrow_6        = 0x36,
	nrow_7        = 0x37,
	nrow_8        = 0x38,
	nrow_9        = 0x39,
	hyphen        = 0x3A,
	equals        = 0x3B,
	backspace     = 0x3C,

	backslash = 0x3D,
	slash     = 0x3E,
  // = 0x3F,
	// = 0x40,

	A = 0x41,
	B = 0x42,
	C = 0x43,
	D = 0x44,
	E = 0x45,
	F = 0x46,
	G = 0x47,
	H = 0x48,
	I = 0x49,
	J = 0x4A,
	K = 0x4B,
	L = 0x4C,
	M = 0x4D,
	N = 0x4E,
	O = 0x4F,
	P = 0x50,
	Q = 0x51,
	R = 0x52,
	S = 0x53,
	T = 0x54,
	U = 0x55,
	V = 0x56,
	W = 0x57,
	X = 0x58,
	Y = 0x59,
	Z = 0x5A,

	insert    = 0x5B,
	delete    = 0x5C,
	home      = 0x5D,
	end       = 0x5E,
	page_up   = 0x5F,
	page_down = 0x60,

	npad_0        = 0x61,
	npad_1        = 0x62,
	npad_2        = 0x63,
	npad_3        = 0x64,
	npad_4        = 0x65,
	npad_5        = 0x66,
	npad_6        = 0x67,
	npad_7        = 0x68,
	npad_8        = 0x69,
	npad_9        = 0x6A,
	npad_decimal  = 0x6B,
	npad_equals   = 0x6C,
	npad_plus     = 0x6D,
	npad_minus    = 0x6E,
	npad_multiply = 0x6F,
	npad_divide   = 0x70,
	npad_enter    = 0x71,

	count = 0x72
}

KeyboardState :: struct #raw_union {
	keys : [MaxKeyboardKeys] DigitalBtn,
	using individual : struct {
		enter,
		tab,
		space,
		bracket_open,
		bracket_close,
		semicolon,
		apostrophe,
		comma,
		period : DigitalBtn,

		__0x0A_0x0F_Unassigned__ : [ 6 * size_of( DigitalBtn )] u8,

		caps_lock,
		scroll_lock,
		num_lock,
		left_alt,
		left_shift,
		left_control,
		right_alt,
		right_shift,
		right_control : DigitalBtn,

		__0x19_0x1D_Unassigned__ : [ 6 * size_of( DigitalBtn )] u8,

		escape,
		F1,
		F2,
		F3,
		F4,
		F5,
		F6,
		F7,
		F8,
		F9,
		F10,
		F11,
		F12 : DigitalBtn,

		print_screen,
		pause : DigitalBtn,

		__0x2E_Unassigned__ : [size_of(DigitalBtn)] u8,

		backtick,
		nrow_0,
		nrow_1,
		nrow_2,
		nrow_3,
		nrow_4,
		nrow_5,
		nrow_6,
		nrow_7,
		nrow_8,
		nrow_9,
		hyphen,
		equals,
		backspace : DigitalBtn,

		backslash,
		slash : DigitalBtn,

		__0x3F_0x40_Unassigned__ : [ 2 * size_of(DigitalBtn)] u8,

		A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z : DigitalBtn,

		insert,
		delete,
		home,
		end,
		page_up,
		page_down : DigitalBtn,

		npad_0,
		npad_1,
		npad_2,
		npad_3,
		npad_4,
		npad_5,
		npad_6,
		npad_7,
		npad_8,
		npad_9,
		npad_decimal,
		npad_equals,
		npad_plus,
		npad_minus,
		npad_multiply,
		npad_divide,
		npad_enter : DigitalBtn
	}
}

MaxMouseBtns :: 16
MouseBtn :: enum u32 {
	Left    = 0x0,
	Middle  = 0x1,
	Right   = 0x2,
	Side    = 0x3,
	Forward = 0x4,
	Back    = 0x5,
	Extra   = 0x6,

	count
}

MouseState :: struct {
	using _ : struct #raw_union {
		      btns       : [16] DigitalBtn,
		using individual : struct {
			left, middle, right        : DigitalBtn,
			side, forward, back, extra : DigitalBtn
		}
	},
	pos, delta                       : Vec2,
	vertical_wheel, horizontal_wheel : AnalogAxis
}

InputState :: struct {
	keyboard : KeyboardState,
	mouse    : MouseState
}

import    "core:os"
import c  "core:c/libc"
import rl "vendor:raylib"

poll_input :: proc( old, new : ^ InputState )
{
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
	}

	// Mouse
	{
		// Process Buttons
		for id : i32 = 0; id < i32(MouseBtn.count); id += 1
		{
			old_btn := & old.mouse.btns[id]
			new_btn := & new.mouse.btns[id]

			mouse_id := cast(MouseBtn) id

			is_down := cast(b32) rl.IsMouseButtonDown( to_raylib_mouse_btn(id) )
			input_process_digital_btn( old_btn, new_btn, is_down )
		}

		new.mouse.pos            = rl.GetMousePosition() - transmute(Vec2) get_state().app_window.extent
		new.mouse.delta          = rl.GetMouseDelta()
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
		load_snapshot( & Memory_App.snapshot[0] )
	}
}

to_raylib_key :: proc( key : i32 ) -> rl.KeyboardKey {
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
		rl.KeyboardKey.KP_ENTER }
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
		rl.MouseButton.EXTRA,
	}
	return raylib_mouse_btn_lookup_table[ btn ]
}
