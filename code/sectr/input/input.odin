// TODO(Ed) : This if its gets larget can be moved to its own package
package sectr

import "base:runtime"

AnalogAxis  :: f32
AnalogStick :: struct {
	X, Y : f32
}

DigitalBtn :: struct {
	half_transitions : i32,
	ended_down       : b32,
}

btn_pressed :: proc( btn : DigitalBtn ) -> b32 {
	return btn.ended_down && btn.half_transitions > 0
}

btn_released :: proc ( btn : DigitalBtn ) -> b32 {
	return btn.ended_down == false && btn.half_transitions > 0
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

	Invalid = 0x100,

	count
}

KeyboardState :: struct #raw_union {
	keys : [KeyCode.count] DigitalBtn,
	using individual : struct {
		null    : DigitalBtn, // 0x00
		ignored : DigitalBtn, // 0x01

		// GFLW / Sokol
		menu,
		world_1, world_2 : DigitalBtn,
		// 0x02 - 0x04

		__0x05_0x07_Unassigned__ : [ 3 * size_of( DigitalBtn)] u8,

		tab, backspace : DigitalBtn,
		// 0x08 - 0x09

		right, left, up, down : DigitalBtn,
		// 0x0A - 0x0D

		enter : DigitalBtn, // 0x0E

		__0x0F_Unassigned__ : [ 1 * size_of( DigitalBtn)] u8,

		caps_lock,
		scroll_lock,
		num_lock : DigitalBtn,
		// 0x10 - 0x12

		left_alt,
		left_shift,
		left_control,
		right_alt,
		right_shift,
		right_control : DigitalBtn,
		// 0x13 - 0x18

		print_screen,
		pause,
		escape,
		home,
		end,
		page_up,
		page_down,
		space : DigitalBtn,
		// 0x19 - 0x20

		exlamation,
		quote_dbl,
		hash,
		dollar,
		percent,
		ampersand,
		quote,
		paren_open,
		paren_close,
		asterisk,
		plus,
		comma,
		minus,
		period,
		slash	: DigitalBtn,
		// 0x21 - 0x2F

		nrow_0, // 0x30
		nrow_1, // 0x31
		nrow_2, // 0x32
		nrow_3, // 0x33
		nrow_4, // 0x34
		nrow_5, // 0x35
		nrow_6, // 0x36
		nrow_7, // 0x37
		nrow_8, // 0x38
		nrow_9, // 0x39

		__0x3A_Unassigned__ : [ 1 * size_of(DigitalBtn)] u8,

		semicolon,
		less,
		equals,
		greater,
		question,
		at : DigitalBtn,

		A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z : DigitalBtn,

		bracket_open,
		backslash,
		bracket_close,
		underscore,
		backtick : DigitalBtn,

		kpad_0,
		kpad_1,
		kpad_2,
		kpad_3,
		kpad_4,
		kpad_5,
		kpad_6,
		kpad_7,
		kpad_8,
		kpad_9,
		kpad_decimal,
		kpad_equals,
		kpad_plus,
		kpad_minus,
		kpad_multiply,
		kpad_divide,
		kpad_enter : DigitalBtn,

		F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12 : DigitalBtn,

		insert, delete : DigitalBtn,

		F13, F14, F15, F16, F17, F18, F19, F20, F21, F22, F23, F24, F25 : DigitalBtn,
	}
}

ModifierCode :: enum u32 {
	Shift,
	Control,
	Alt,
	Left_Mouse,
	Right_Mouse,
	Middle_Mouse,
	Left_Shift,
	Right_Shift,
	Left_Control,
	Right_Control,
	Left_Alt,
	Right_Alt,
}
ModifierCodeFlags :: bit_set[ModifierCode; u32]

MouseState :: struct {
	using _ : struct #raw_union {
		      btns       : [16] DigitalBtn,
		using individual : struct {
			left, middle, right        : DigitalBtn,
			side, forward, back, extra : DigitalBtn,
		}
	},
	raw_pos, pos, delta : Vec2,
	scroll              : [2]AnalogAxis,
}

mouse_world_delta :: #force_inline proc "contextless" () -> Vec2 {
	using state := get_state()
	cam := & state.project.workspace.cam
	return input.mouse.delta * ( 1 / cam.zoom )
}

InputState :: struct {
	keyboard : KeyboardState,
	mouse    : MouseState,
}
