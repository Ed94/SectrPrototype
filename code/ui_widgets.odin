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

// Adds resizable handles to a widget
ui_resizable_handles :: proc( parent : ^UI_Widget,
	pos, size                  : ^Vec2,
	handle_width               : f32  = 15,
	handle_color_non_default   : Color = Color_ResizeHandle,
	handle_color_default       : Color = Color_Transparent,
	left      := true,
	right     := true,
	top       := true,
	bottom    := true,
	corner_tr := true,
	corner_tl := true,
	corner_br := true,
	corner_bl := true, )
{
	profile(#procedure)
	handle_left      : UI_Widget
	handle_right     : UI_Widget
	handle_top       : UI_Widget
	handle_bottom    : UI_Widget
	handle_corner_tr : UI_Widget
	handle_corner_tl : UI_Widget
	handle_corner_br : UI_Widget
	handle_corner_bl : UI_Widget

	ui_parent(parent)
	flags := UI_BoxFlags { .Mouse_Clickable, .Focusable }

	style_bar := UI_Style {
		flags     = { .Fixed_Width },
		size      = range2({handle_width, 0}, {}),
		bg_color  = Color_ResizeHandle,
		alignment = {1, 1},
		margins   = { handle_width, handle_width, 0, 0 },
		corner_radii = { 5, 0, 0, 0 }
	}
	theme_bar := to_ui_styletheme(style_bar)
	theme_bar.default.bg_color = handle_color_default
	theme_bar.default.corner_radii[0] = 0
	ui_style_theme(theme_bar)
	style_resize_height          := style_bar
	style_resize_height.flags     = {.Fixed_Height}
	style_resize_height.size.min  = {0, handle_width}
	style_resize_height.margins   = { 0, 0, handle_width, handle_width }
	style_resize_height.alignment = {0, 0}

	context.user_ptr = & parent.label
	name :: proc(  ) -> StrRunesPair {
		parent_label := (transmute(^string) context.user_ptr) ^
		return str_intern(str_fmt_tmp("%v: %v", ))
	}

	if left do handle_left = ui_widget("Settings Menu: Resize Left Border", flags )
	if right {
		handle_right  = ui_widget("Settings Menu: Resize Right Border", flags)
		handle_right.style.anchor.left = 1
		handle_right.style.alignment   = { 0, 1 }
	}

	ui_theme_via_style(style_resize_height)
	ui_style_theme_ref().default.bg_color = handle_color_default
	if top do handle_top = ui_widget("Settings Menu: Resize Top Border", flags )
	if bottom {
		handle_bottom = ui_widget("Settings Menu: Resize Bottom Border", flags)
		handle_bottom.style.anchor.top  = 1
		handle_bottom.style.alignment   = { 0, 1 }
	}

	style_corner := UI_Style {
		flags        = { .Fixed_Width, .Fixed_Height },
		size         = range2({handle_width, handle_width}, {}),
		bg_color     = Color_ResizeHandle,
		alignment    = {1, 0},
		corner_radii = { 5, 0, 0, 0 },
	}
	ui_theme_via_style(style_corner)
	ui_style_theme_ref().default.bg_color = handle_color_default
	if corner_tl do handle_corner_tl = ui_widget("Settings Menu: Corner TL", flags)
	if corner_tr {
		handle_corner_tr = ui_widget("Settings Menu: Corner TR", flags)
		handle_corner_tr.style.anchor    = range2({1, 0}, {})
		handle_corner_tr.style.alignment = {0, 0}
	}

	if corner_bl {
		handle_corner_bl = ui_widget("Settings Menu: Corner BL", flags)
		handle_corner_bl.style.anchor    = range2({}, {0, 1})
		handle_corner_bl.style.alignment = { 1, 1 }
	}
	if corner_br {
		handle_corner_br = ui_widget("Settings Menu: Corner BR", flags)
		handle_corner_br.style.anchor    = range2({1, 0}, {0, 1})
		handle_corner_br.style.alignment = {0, 1}
	}

	process_handle_drag :: #force_inline proc ( handle : ^UI_Widget,
		direction                :  Vec2,
		size_delta               :  Vec2,
		target_alignment         :  Vec2,
		pos                      : ^Vec2,
		size                     : ^Vec2,
		alignment                : ^Vec2, )
	{
		ui := get_state().ui_context
		if ui.last_pressed_key != handle.key { return }

		size_delta := size_delta
		pos_adjust := size^ * (alignment^ - target_alignment)

		@static was_dragging := false

		using handle
		if active
		{
			size^ += size_delta * direction
			if pressed {
				pos^ -= pos_adjust
			}
			else {
				alignment^ = target_alignment
			}
			was_dragging = true
		}
		else if released && was_dragging
		{
			pos^        += pos_adjust
			alignment^   = target_alignment
			was_dragging = false
		}
	}

	delta     := get_state().input.mouse.delta
	alignment := & parent.style.alignment
	if right     do process_handle_drag( & handle_right,     {  1,  0 }, delta, {0, 0}, pos, size, alignment )
	if left      do process_handle_drag( & handle_left,      { -1,  0 }, delta, {1, 0}, pos, size, alignment )
	if top       do process_handle_drag( & handle_top,       {  0,  1 }, delta, {0, 0}, pos, size, alignment )
	if bottom    do process_handle_drag( & handle_bottom,    {  0, -1 }, delta, {0, 1}, pos, size, alignment )
	if corner_tr do process_handle_drag( & handle_corner_tr, {  1,  1 }, delta, {0, 0}, pos, size, alignment )
	if corner_tl do process_handle_drag( & handle_corner_tl, { -1,  1 }, delta, {1, 0}, pos, size, alignment )
	if corner_br do process_handle_drag( & handle_corner_br, {  1, -1 }, delta, {0, 1}, pos, size, alignment )
	if corner_bl do process_handle_drag( & handle_corner_bl, { -1, -1 }, delta, {1, 1}, pos, size, alignment )
}

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

//region Vertical Box
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
//endregion Vertical Box
