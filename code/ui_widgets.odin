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

ui_text :: proc( label : string, content : StringCached, font_size : f32 = 24, font := Font_Default, flags : UI_BoxFlags ) -> UI_Widget
{
	state := get_state(); using state

	font := font
	if font == Font_Default {
		font = default_font
	}
	text_size := measure_text_size( content.str, font, font_size, 0 )

	box    := ui_box_make( flags, "TEXT BOX!" )
	signal := ui_signal_from_box( box )

	box.text              = content
	box.style.layout.size = text_size
	return { box, signal }
}
