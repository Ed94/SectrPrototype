package sectr

UI_Widget :: struct {
	using box    : ^UI_Box,
	using signal : UI_Signal,
}

ui_widget :: proc( label : string, flags : UI_BoxFlags ) -> (widget : UI_Widget)
{
	// profile(#procedure)

	widget.box    = ui_box_make( flags, label )
	widget.signal = ui_signal_from_box( widget.box )
	return
}

ui_button :: proc( label : string, flags : UI_BoxFlags = {} ) -> (btn : UI_Widget)
{
	// profile(#procedure)

	btn_flags := UI_BoxFlags { .Mouse_Clickable, .Focusable, .Click_To_Focus }
	btn.box    = ui_box_make( btn_flags | flags, label )
	btn.signal = ui_signal_from_box( btn.box )
	return
}

//region Horizontal Box
/*
Horizontal Boxes automatically manage a collection of widgets and
attempt to slot them adjacent to each other along the x-axis.

The user must provide the direction that the hbox will append entries.
How the widgets will be scaled will be based on the individual entires style flags.

All the usual behaviors that the style and box flags do apply when manage by the box widget.
Whether or not the horizontal box will scale the widget's width is if:
fixed size or "scale by ratio" flags are not used for the width.
The hbox will use the anchor's (range2) ratio.x value to determine the "stretch ratio".

Keep in mind the stretch ratio is only respected if no size.min.x value is violated for each of the widgets.
*/

ui_hbox_begin :: proc( label : string, flags : UI_BoxFlags = {}
//, direction
) -> (widget : UI_Widget) {
	// profile(#procedure)

	widget.box    = ui_box_make( flags, label )
	widget.signal = ui_signal_from_box( widget.box )
	return
}
ui_hbox_end :: proc( hbox : UI_Widget ) -> UI_Widget {
	hbox_width := hbox.computed.content.max.y - hbox.computed.content.min.y

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := hbox.first; child != nil; child = child.next
	{
		using child
		using style.layout
		scaled_width_by_height : b32 = b32(.Scale_Width_By_Height_Ratio in style.flags)
		if .Fixed_Width in style.flags
		{
			if scaled_width_by_height {
				height := size.max.y != 0 ? size.max.y : hbox_width
				width  := height * size.min.x

				size_req_children += width
				continue
			}

			size_req_children += size.min.x
			continue
		}


	}
	availble_flexible_space := hbox_width - size_req_children
	return hbox
}
ui_hbox_auto_end :: proc( vbox : UI_Widget ) {
	ui_hbox_end(vbox)
	ui_parent_pop()
}

@(deferred_out = ui_hbox_end)
ui_hbox :: #force_inline proc( label : string, flags : UI_BoxFlags = {} ) -> (widget : UI_Widget) {
	widget        = ui_hbox_begin(label, flags)
	ui_parent(widget)
	return
}

//endregion Horizontal Box

ui_text :: proc( label : string, content : StrRunesPair, flags : UI_BoxFlags = {} ) -> UI_Widget
{
	// profile(#procedure)
	state := get_state(); using state

	box    := ui_box_make( flags, label )
	signal := ui_signal_from_box( box )

	box.text = content
	return { box, signal }
}

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

ui_vbox_begin :: proc( label : string, flags : UI_BoxFlags = {} ) -> (widget : UI_Widget) {
	// profile(#procedure)

	widget.box    = ui_box_make( flags, label )
	// widget.signal = ui_signal_from_box( widget.box )
	return
}
ui_vbox_end :: proc( hbox : UI_Widget ) -> UI_Widget {
	// do layout calculations for the children
	return hbox
}
ui_vbox_auto_end :: proc( hbox : UI_Widget ) {
	ui_vbox_end(hbox)
	ui_parent_pop()
}

// ui_vbox_append( widget : UI_Widget )

@(deferred_out = ui_vbox_auto_end)
ui_vbox :: #force_inline proc( label : string, flags : UI_BoxFlags = {} ) -> (widget : UI_Widget) {
	widget = ui_vbox_begin(label, flags)
	ui_parent_push(widget)
	return
}
