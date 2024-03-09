package sectr

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

