package sectr

ui_signal_from_box :: proc ( box : ^ UI_Box ) -> UI_Signal
{
	ui    := get_state().ui_context
	input := get_state().input

	frame_delta := frametime_delta32()

	signal := UI_Signal { box = box }

	// Cursor Collision
		signal.cursor_pos  = ui_cursor_pos()
		signal.cursor_over = cast(b8) pos_within_range2( signal.cursor_pos, box.computed.bounds )

		resize_border_width     := cast(f32) get_state().config.ui_resize_border_width
		resize_border_non_range := add(box.computed.bounds, range2(
				{  resize_border_width, -resize_border_width },
				{ -resize_border_width,  resize_border_width }))

		within_resize_range := cast(b8) ! pos_within_range2( signal.cursor_pos, resize_border_non_range )
		within_resize_range &= signal.cursor_over

	left_pressed  := pressed( input.mouse.left )
	left_released := released( input.mouse.left )

	mouse_clickable    := UI_BoxFlag.Mouse_Clickable    in box.flags
	keyboard_clickable := UI_BoxFlag.Keyboard_Clickable in box.flags

	was_hot      := ui.hot    == box.key && box.hot_delta    > 0
	was_active   := ui.active == box.key && box.active_delta > 0
	was_disabled := box.disabled_delta > 0

	if mouse_clickable && signal.cursor_over && left_pressed
	{
		ui.hot                         = box.key
		ui.active                      = box.key
		ui.active_mouse[MouseBtn.Left] = box.key
		ui.last_pressed_key            = box.key

		ui.cursor_active_start = signal.cursor_pos

		signal.pressed = true
		// TODO(Ed) : Support double-click detection
	}

	if mouse_clickable && signal.cursor_over && left_released
	{
		box.active_delta = 0
		ui.active        = UI_Key(0)
		ui.active_mouse[MouseBtn.Left] = UI_Key(0)

		signal.released     = true
		signal.left_clicked = true

		ui.last_clicked = box.key
	}

	if mouse_clickable && ! signal.cursor_over && left_released
	{
		box.hot_delta = 0

		ui.hot    = UI_Key(0)
		ui.active = UI_Key(0)
		ui.active_mouse[MouseBtn.Left] = UI_Key(0)

		signal.released     = true
		signal.left_clicked = false
	}

	if keyboard_clickable
	{
		// TODO(Ed) : Add keyboard interaction support
	}

	// TODO(Ed) : Add scrolling support
	if UI_BoxFlag.Scroll_X in box.flags {

	}
	if UI_BoxFlag.Scroll_Y in box.flags {

	}

	// TODO(Ed) : Add panning support
	if UI_BoxFlag.Pan_X in box.flags {

	}
	if UI_BoxFlag.Pan_Y in box.flags {

	}

	is_disabled := UI_BoxFlag.Disabled in box.flags
	is_hot      := ui.hot    == box.key
	is_active   := ui.active == box.key

	if signal.cursor_over &&
		ui.hot    == UI_Key(0) || is_hot &&
		ui.active == UI_Key(0) || is_active
	{
		ui.hot = box.key
		is_hot = true
	}

	if ! is_active {
		ui.hot_resizable = cast(b32) within_resize_range
	}
	signal.resizing = cast(b8) is_active && (within_resize_range || ui.active_resizing)

	// State Deltas update
	if is_hot
	{
		box.hot_delta += frame_delta
		if was_hot {
			box.style_delta += frame_delta
		}
	}
	else {
		box.hot_delta = 0
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

	ui.active_resizing = cast(b32) is_active && signal.resizing
	signal.dragging    = cast(b8) is_active && ( ! within_resize_range && ! ui.active_resizing)

	// Update style if not in default state
	{
		if is_hot
		{
			if ! was_hot  {
				box.prev_style  = box.style
				box.style_delta = 0
			}
			box.style = stack_peek( & ui.theme_stack ).hovered
		}
		if is_active
		{
			if ! was_active {
				box.prev_style  = box.style
				box.style_delta = 0
			}
			box.style = stack_peek( & ui.theme_stack ).focused
		}
		if is_disabled
		{
			if ! was_disabled {
				box.prev_style  = box.style
				box.style_delta = 0
			}
			box.style = stack_peek( & ui.theme_stack ).disabled
		}

		if ! is_disabled && ! is_active && ! is_hot {
			if  was_disabled || was_active || was_hot {
				box.prev_style  = box.style
				box.style_delta = 0
			}
			else {
				box.style_delta += frame_delta
			}
			box.style = stack_peek( & ui.theme_stack ).default
		}
	}

	return signal
}