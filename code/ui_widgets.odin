package sectr

UI_Widget :: struct {
	using box    : ^UI_Box,
	using signal : UI_Signal,
}

ui_widget :: proc( label : string, flags : UI_BoxFlags ) -> (widget : UI_Widget)
{
	widget.box    = ui_box_make( flags, label )
	widget.signal = ui_signal_from_box( widget.box )
	return
}

ui_button :: proc( label : string, flags : UI_BoxFlags = {} ) -> (btn : UI_Widget)
{
	btn_flags := UI_BoxFlags { .Mouse_Clickable, .Focusable, .Click_To_Focus }
	btn.box    = ui_box_make( btn_flags | flags, label )
	btn.signal = ui_signal_from_box( btn.box )
	return
}

ui_text :: proc( label : string, content : StringCached, flags : UI_BoxFlags = {} ) -> UI_Widget
{
	state := get_state(); using state

	box    := ui_box_make( flags, label )
	signal := ui_signal_from_box( box )

	text_size := measure_text_size( content.str, box.style.font, box.style.font_size, 0 )

	box.text              = content
	box.style.layout.size = text_size
	return { box, signal }
}

ui_space :: proc( label : string, flags : UI_BoxFlags = {} ) -> UI_Widget
{
	space_str := str_intern( " " )

	state := get_state(); using state

	box    := ui_box_make( flags, label )
	signal := ui_signal_from_box( box )

	text_size := measure_text_size( space_str.str, box.style.font, box.style.font_size, 0 )
	box.text              = space_str
	box.style.layout.size = text_size
	return { box, signal }
}

ui_tab :: proc( label : string, flags : UI_BoxFlags = {} ) -> UI_Widget
{
	tab_str := str_intern( "\t" )

	state := get_state(); using state

	box    := ui_box_make( flags, label )
	signal := ui_signal_from_box( box )

	text_size := measure_text_size( tab_str.str, box.style.font, box.style.font_size, 0 )
	box.text              = tab_str
	box.style.layout.size = text_size
	return { box, signal }
}
