package sectr

import "base:runtime"
import "core:os"
import "core:c/libc"
import sokol_app "thirdparty:sokol/app"

to_modifiers_code_from_sokol :: proc( sokol_modifiers : u32 ) -> ( modifiers : ModifierCodeFlags )
{
	if sokol_modifiers & sokol_app.MODIFIER_SHIFT  != 0 do modifiers |= { .Shift }
	if sokol_modifiers & sokol_app.MODIFIER_CTRL   != 0 do modifiers |= { .Control }
	if sokol_modifiers & sokol_app.MODIFIER_ALT    != 0 do modifiers |= { .Alt }
	if sokol_modifiers & sokol_app.MODIFIER_LMB    != 0 do modifiers |= { .Left_Mouse }
	if sokol_modifiers & sokol_app.MODIFIER_RMB    != 0 do modifiers |= { .Right_Mouse }
	if sokol_modifiers & sokol_app.MODIFIER_MMB    != 0 do modifiers |= { .Middle_Mouse }
	if sokol_modifiers & sokol_app.MODIFIER_LSHIFT != 0 do modifiers |= { .Left_Shift }
	if sokol_modifiers & sokol_app.MODIFIER_RSHIFT != 0 do modifiers |= { .Right_Shift }
	if sokol_modifiers & sokol_app.MODIFIER_LCTRL  != 0 do modifiers |= { .Left_Control }
	if sokol_modifiers & sokol_app.MODIFIER_RCTRL  != 0 do modifiers |= { .Right_Control }
	if sokol_modifiers & sokol_app.MODIFIER_LALT   != 0 do modifiers |= { .Left_Alt }
	if sokol_modifiers & sokol_app.MODIFIER_RALT   != 0 do modifiers |= { .Right_Alt }
	return
}

to_key_from_sokol :: proc( sokol_key : sokol_app.Keycode ) -> ( key : KeyCode )
{
	world_code_offset      :: i32(sokol_app.Keycode.WORLD_1) - i32(KeyCode.world_1)
	arrow_code_offset      :: i32(sokol_app.Keycode.RIGHT)   - i32(KeyCode.right)
	func_row_code_offset   :: i32(sokol_app.Keycode.F1)      - i32(KeyCode.F1)
	func_extra_code_offset :: i32(sokol_app.Keycode.F13)     - i32(KeyCode.F25)
	keypad_num_offset      :: i32(sokol_app.Keycode.KP_0)    - i32(KeyCode.kpad_0)

	switch sokol_key {
		case .INVALID ..= .GRAVE_ACCENT : key = transmute(KeyCode) sokol_key
		case .WORLD_1, .WORLD_2         : key = transmute(KeyCode) (i32(sokol_key) - world_code_offset)
		case .ESCAPE                    : key = .escape
		case .ENTER                     : key = .enter
		case .TAB                       : key = .tab
		case .BACKSPACE                 : key = .backspace
		case .INSERT                    : key = .insert
		case .DELETE                    : key = .delete
		case .RIGHT ..= .UP             : key = transmute(KeyCode) (i32(sokol_key) - arrow_code_offset)
		case .PAGE_UP                   : key = .page_up
		case .PAGE_DOWN                 : key = .page_down
		case .HOME                      : key = .home
		case .END                       : key = .end
		case .CAPS_LOCK                 : key = .caps_lock
		case .SCROLL_LOCK               : key = .scroll_lock
		case .NUM_LOCK                  : key = .num_lock
		case .PRINT_SCREEN              : key = .print_screen
		case .PAUSE                     : key = .pause
		case .F1   ..= .F12             : key = transmute(KeyCode) (i32(sokol_key) - func_row_code_offset)
		case .F13  ..= .F25             : key = transmute(KeyCode) (i32(sokol_key) - func_extra_code_offset)
		case .KP_0 ..= .KP_9            : key = transmute(KeyCode) (i32(sokol_key) - keypad_num_offset)
		case .KP_DECIMAL                : key = .kpad_decimal
		case .KP_DIVIDE                 : key = .kpad_divide
		case .KP_MULTIPLY               : key = .kpad_multiply
		case .KP_SUBTRACT               : key = .kpad_minus
		case .KP_ADD                    : key = .kpad_plus
		case .KP_ENTER                  : key = .kpad_enter
		case .KP_EQUAL                  : key = .kpad_equals
		case .LEFT_SHIFT                : key = .left_shift
		case .LEFT_CONTROL              : key = .left_control
		case .LEFT_ALT                  : key = .left_alt
		case .LEFT_SUPER                : key = .ignored
		case .RIGHT_SHIFT               : key = .right_shift
		case .RIGHT_CONTROL             : key = .right_control
		case .RIGHT_ALT                 : key = .right_alt
		case .RIGHT_SUPER               : key = .ignored
		case .MENU                      : key = .menu
	}
	return
}

to_mouse_btn_from_sokol :: proc( sokol_mouse : sokol_app.Mousebutton ) -> ( btn : MouseBtn )
{
	switch sokol_mouse {
		case .LEFT    : btn = .Left
		case .MIDDLE  : btn = .Middle
		case .RIGHT   : btn = .Right
		case .INVALID : btn = .Invalid
	}
	return
}
