package sectr

UI_Widget :: struct {
	using box    : ^UI_Box,
	using signal : UI_Signal,
}

//@(optimization_mode="speed")
ui_widget :: proc( label : string, flags : UI_BoxFlags ) -> (widget : UI_Widget)
{
	// profile(#procedure)

	widget.box    = ui_box_make( flags, label )
	widget.signal = ui_signal_from_box( widget.box )
	return
}

//@(optimization_mode="speed")
ui_button :: proc( label : string, flags : UI_BoxFlags = {} ) -> (btn : UI_Widget)
{
	// profile(#procedure)

	btn_flags := UI_BoxFlags { .Mouse_Clickable, .Focusable, .Click_To_Focus }
	btn.box    = ui_box_make( btn_flags | flags, label )
	btn.signal = ui_signal_from_box( btn.box )
	return
}

//@(optimization_mode="speed")
ui_text :: proc( label : string, content : StringCached, flags : UI_BoxFlags = {} ) -> UI_Widget
{
	// profile(#procedure)
	state := get_state(); using state

	box    := ui_box_make( flags, label )
	signal := ui_signal_from_box( box )

	box.text = content
	return { box, signal }
}

//@(optimization_mode="speed")
ui_text_spaces :: proc( label : string, flags : UI_BoxFlags = {} ) -> UI_Widget
{
	// profile(#procedure)
	state := get_state(); using state

	// TODO(Ed) : Move this somwhere in state.
	space_str := str_intern( " " )

	box    := ui_box_make( flags, label )
	signal := ui_signal_from_box( box )

	box.text = space_str
	return { box, signal }
}

//@(optimization_mode="speed")
ui_text_tabs :: proc( label : string, flags : UI_BoxFlags = {} ) -> UI_Widget
{
	// profile(#procedure)
	state   := get_state(); using state

	// TODO(Ed) : Move this somwhere in state.
	tab_str := str_intern( "\t" )

	box    := ui_box_make( flags, label )
	signal := ui_signal_from_box( box )

	box.text = tab_str
	return { box, signal }
}
