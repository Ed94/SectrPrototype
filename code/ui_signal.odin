package sectr

ui_signal_from_box :: proc ( box : ^ UI_Box ) -> UI_Signal
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

		computed_size := box.computed.bounds.p1 - box.computed.bounds.p0

		resize_border_width  := cast(f32) get_state().config.ui_resize_border_width
		resize_percent_width := computed_size * (resize_border_width * 1.0/ 200.0)
		resize_border_non_range := add(box.computed.bounds, range2(
				{  resize_percent_width.x, -resize_percent_width.x },
				{ -resize_percent_width.x,  resize_percent_width.x }))

		within_resize_range := cast(b8) ! pos_within_range2( signal.cursor_pos, resize_border_non_range )
		within_resize_range &= signal.cursor_over
		within_resize_range &= .Mouse_Resizable in box.flags
	// profile_end()

	// profile_begin("misc")
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

		ui.last_pressed_key = box.key
		ui.active_start_style  = box.style

		signal.pressed = true
		// TODO(Ed) : Support double-click detection
	}

	if mouse_clickable && signal.cursor_over && left_released
	{
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

	if signal.cursor_over
	{
		hot_vacant    := ui.hot    == UI_Key(0)
		active_vacant := ui.active == UI_Key(0)

		if (hot_vacant    || is_hot) &&
			 (active_vacant || is_active)
		{
			// prev_hot := zpl_hmap_get( ui.prev_cache, u64(ui.hot) )
			// prev_hot_label := prev_hot != nil ? prev_hot.label.str : ""
			// log( str_fmt_tmp("Detected HOT via CURSOR OVER: %v is_hot: %v is_active: %v prev_hot: %v", box.label.str, is_hot, is_active, prev_hot_label ))
			ui.hot = box.key
			is_hot = true

			ui.hot_start_style = box.style
		}
	}
	else
	{
		is_hot = false
		if ui.hot == box.key {
			ui.hot = UI_Key(0)
		}
	}
	// profile_end()

	signal.resizing  = cast(b8)  is_active && (within_resize_range || ui.active_start_signal.resizing)
	ui.hot_resizable = cast(b32) (is_hot && within_resize_range) || signal.resizing

	// State Deltas update
	// profile_begin( "state deltas upate")
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
	// profile_end()

	signal.dragging = cast(b8)  is_active && ( ! within_resize_range && ! ui.active_start_signal.resizing)

	// Update style if not in default state
	{
		// profile("Update style")

		if is_hot
		{
			if ! was_hot  {
				box.prev_style  = box.style
				box.style_delta = 0
			}
			box.style = stack_peek( & ui.theme_stack ).hot
		}
		if is_active
		{
			if ! was_active {
				box.prev_style  = box.style
				box.style_delta = 0
				log( str_fmt_tmp("NEW ACTIVE: %v", box.label.str))
			}
			box.style = stack_peek( & ui.theme_stack ).active
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

	if is_active && ! was_active {
		ui.active_start_signal = signal
	}
	return signal
}
