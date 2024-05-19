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
	raw_pos, pos, delta              : Vec2,
	vertical_wheel, horizontal_wheel : AnalogAxis
}

mouse_world_delta :: #force_inline proc "contextless" () -> Vec2 {
	using state := get_state()
	cam := & state.project.workspace.cam
	return input.mouse.delta * ( 1 / cam.zoom )
}

InputState :: struct {
	keyboard : KeyboardState,
	mouse    : MouseState,

	keyboard_events : KeyboardEvents,
}

// TODO(Ed): Whats the lifetime of these events? (So far we're picking per full-frame)
KeyboardEvents :: struct {
	keys_pressed  : Array(KeyboardKey),
	chars_pressed : Array(rune),
}
