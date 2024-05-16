package sectr

import "base:runtime"

UI_Signal :: struct {
	cursor_pos : Vec2,
	drag_delta : Vec2,
	scroll     : Vec2,

	left_clicked     : b8,
	right_clicked    : b8,
	double_clicked   : b8,
	keyboard_clicked : b8,
	left_shift_held  : b8,
	left_ctrl_held   : b8,

	active     : b8,
	hot        : b8,
	disabled   : b8,

	was_active   : b8,
	was_hot      : b8,
	was_disabled : b8,

	pressed     : b8,
	released    : b8,
	cursor_over : b8,
	commit      : b8,
}

ui_signal_from_box :: proc ( box : ^ UI_Box, update_style := true, update_deltas := true ) -> UI_Signal
{
	// profile(#procedure)
	ui    := get_state().ui_context
	input := get_state().input

	frame_delta := frametime_delta32()

	signal := UI_Signal {}

	// Cursor Collision
	// profile_begin( "Cursor collision")
		signal.cursor_pos  = ui_cursor_pos()
		signal.cursor_over = cast(b8) pos_within_range2( signal.cursor_pos, box.computed.bounds )

		UnderCheck:
		{
			if ! signal.cursor_over do break UnderCheck

			last_root := ui_box_from_key( ui.prev_cache, ui.root.key )
			if last_root == nil do break UnderCheck

			top_ancestor := ui_top_ancestor(box)
			if top_ancestor.parent_index < last_root.parent_index
			{
				for curr := last_root.last; curr != nil && curr.key != box.key; curr = curr.prev {
					if pos_within_range2( signal.cursor_pos, curr.computed.bounds ) {
						signal.cursor_over = false
					}
				}
			}
		}
	// profile_end()

	// profile_begin("misc")
	left_pressed  := pressed( input.mouse.left )
	left_released := released( input.mouse.left )

	signal.left_shift_held = b8(input.keyboard.left_shift.ended_down)

	mouse_clickable    := UI_BoxFlag.Mouse_Clickable    in box.flags
	keyboard_clickable := UI_BoxFlag.Keyboard_Clickable in box.flags

	was_hot      := (box.hot_delta    > 0)
	was_active   := (ui.active == box.key) && (box.active_delta > 0)
	was_disabled := box.disabled_delta > 0
	// if was_hot {
		// runtime.debug_trap()
	// }

	// Check to see if this box is active
	if mouse_clickable && signal.cursor_over && left_pressed && was_hot
	{
		// ui.hot                         = box.key
		ui.active                      = box.key
		ui.active_mouse[MouseBtn.Left] = box.key

		ui.last_pressed_key   = box.key
		ui.active_start_style = box.style

		signal.pressed      = true
		signal.left_clicked = b8(left_pressed)
		// TODO(Ed) : Support double-click detection
	}

	if mouse_clickable && ! signal.cursor_over && left_released
	{
		box.active_delta = 0

		ui.active = UI_Key(0)
		ui.active_mouse[MouseBtn.Left] = UI_Key(0)

		signal.released     = true
	}

	if keyboard_clickable
	{
		// TODO(Ed) : Add keyboard interaction support
	}

	// TODO(Ed): Should panning and scrolling get supported here? (problably not...)
	// TODO(Ed) : Add scrolling support
	// if UI_BoxFlag.Scroll_X in box.flags {

	// }
	// if UI_BoxFlag.Scroll_Y in box.flags {

	// }
	// TODO(Ed) : Add panning support
	// if UI_BoxFlag.Pan_X in box.flags {

	// }
	// if UI_BoxFlag.Pan_Y in box.flags {
	// }

	is_disabled := UI_BoxFlag.Disabled in box.flags
	is_hot      := ui.hot    == box.key
	is_active   := ui.active == box.key

	// TODO(Ed): It should be able to enter hot without mouse_clickable
	if mouse_clickable && signal.cursor_over && ! is_disabled
	{
		hot_vacant    := ui.hot    == UI_Key(0)
		active_vacant := ui.active == UI_Key(0)
			//  (active_vacant  is_active)
		if signal.cursor_over && active_vacant
		{
			if ! hot_vacant {
				prev := ui_box_from_key( ui.curr_cache, ui.hot )
				prev.hot_delta = 0
			}
			// prev_hot := zpl_hmap_get( ui.prev_cache, u64(ui.hot) )
			// prev_hot_label := prev_hot != nil ? prev_hot.label.str : ""
			// log( str_fmt_tmp("Detected HOT via CURSOR OVER: %v is_hot: %v is_active: %v prev_hot: %v", box.label.str, is_hot, is_active, prev_hot_label ))
			ui.hot = box.key
			is_hot = true

			ui.hot_start_style = box.style
		}
	}
	else if ! signal.cursor_over && was_hot
	{
		ui.hot        = UI_Key(0)
		is_hot        = false
		box.hot_delta = 0
	}

	if mouse_clickable && signal.cursor_over && left_released
	{
		box.active_delta = 0

		ui.active                      = UI_Key(0)
		ui.active_mouse[MouseBtn.Left] = UI_Key(0)

		signal.released = true

		if was_active {
			signal.left_clicked = true
			ui.last_clicked     = box.key
		}
	}
	// profile_end()

	// State Deltas update
	// profile_begin( "state deltas upate")
	if is_hot
	{
		box.hot_delta += frame_delta
		if was_hot {
			box.style_delta += frame_delta
		}
	}
	if is_active
	{
		box.active_delta += frame_delta
		if was_active {
			box.style_delta += frame_delta
		}
	}
	else {
		box.active_delta = 0
	}
	if is_disabled
	{
		box.disabled_delta += frame_delta
		if was_hot {
			box.style_delta += frame_delta
		}
	}
	else {
		box.disabled_delta = 0
	}
	// profile_end()

	signal.active     = cast(b8) is_active
	signal.was_active = cast(b8) was_active
	// logf("was_active: %v", was_active)

	// Update style if not in default state
	if update_style
	{
		// profile("Update style")

		if is_hot
		{
			if ! was_hot  {
				box.style_delta = 0
			}
			box.layout = ui_layout_peek().hot
			box.style  = ui_style_peek().hot
		}
		if is_active
		{
			if ! was_active {
				box.style_delta = 0
			}
			box.layout = ui_layout_peek().active
			box.style  = ui_style_peek().active
		}
		if is_disabled
		{
			if ! was_disabled {
				box.style_delta = 0
			}
			box.layout = ui_layout_peek().disabled
			box.style  = ui_style_peek().disabled
		}

		if ! is_disabled && ! is_active && ! is_hot {
			if  was_disabled || was_active || was_hot {
				box.style_delta = 0
			}
			else {
				box.style_delta += frame_delta
			}
			box.layout = ui_layout_peek().default
			box.style  = ui_style_peek().default
		}
	}

	if is_active && ! was_active {
		ui.active_start_signal = signal
	}

	return signal
}
