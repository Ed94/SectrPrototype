package sectr

import lalg "core:math/linalg"

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

#region("Horizontal Box")
/*
Horizontal Boxes automatically manage a collection of widgets and
attempt to slot them adjacent to each other along the x-axis.

The user must provide the direction that the hbox will append entries.
How the widgets will be scaled will be based on the individual entires style flags.

All the usual behaviors that the style and box flags do apply when managed by the box widget.
Whether or not the horizontal box will scale the widget's width is if:
fixed size or "scale by ratio" flags are not used for the width.
The hbox will use the anchor's (range2) ratio.x value to determine the "stretch ratio".

Keep in mind the stretch ratio is only respected if no size.min.x value is violated for each of the widgets.
*/

// Horizontal Widget
UI_HBox :: struct {
	using widget : UI_Widget,
	direction    : UI_LayoutDirectionX,
}

// Boilerplate creation
ui_hbox_begin :: proc( direction : UI_LayoutDirectionX, label : string, flags : UI_BoxFlags = {} ) -> (hbox : UI_HBox) {
	// profile(#procedure)
	hbox.direction = direction
	hbox.box       = ui_box_make( flags, label )
	hbox.signal    = ui_signal_from_box(hbox.box)
	// ui_box_compute_layout(hbox)
	return
}

// Auto-layout children
ui_hbox_end :: proc( hbox : UI_HBox, width_ref : ^f32 = nil, compute_layout := true )
{
	// profile(#procedure)
	if compute_layout do ui_box_compute_layout(hbox.box)
	ui_layout_children_horizontally( hbox.box, hbox.direction, width_ref )
}

@(deferred_out = ui_hbox_end_auto)
ui_hbox :: #force_inline proc( direction : UI_LayoutDirectionX, label : string, flags : UI_BoxFlags = {} ) -> (hbox : UI_HBox) {
	hbox = ui_hbox_begin(direction, label, flags)
	ui_parent_push(hbox.box)
	return
}

// Auto-layout children and pop parent from parent stack
ui_hbox_end_auto :: proc( hbox : UI_HBox ) {
	ui_hbox_end(hbox)
	ui_parent_pop()
}
#endregion("Horizontal Box")

#region("Resizable")
// Parameterized widget def for ui_resizable_handles
UI_Resizable :: struct {
	using widget      : UI_Widget,
	handle_width      : f32,
	color_non_default : Color,
	color_default     : Color,
	left              : bool,
	right             : bool,
	top               : bool,
	bottom            : bool,
	corner_tr         : bool,
	corner_tl         : bool,
	corner_br         : bool,
	corner_bl         : bool,
	compute_layout    : bool
}

ui_resizable_begin :: proc( label : string, flags : UI_BoxFlags = {},
	handle_width             : f32  = 15,
	handle_color_non_default : Color = Color_ResizeHandle,
	handle_color_default     : Color = Color_Transparent,
	left      := true,
	right     := true,
	top       := true,
	bottom    := true,
	corner_tr := true,
	corner_tl := true,
	corner_br := true,
	corner_bl := true,
	compute_layout := true ) -> (resizable : UI_Resizable)
{
	resizable.box    = ui_box_make(flags, label)
	resizable.signal = ui_signal_from_box(resizable.box)

	resizable.handle_width             = handle_width
	resizable.color_non_default        = handle_color_non_default
	resizable.color_default            = handle_color_default
	resizable.left                     = left
	resizable.right                    = right
	resizable.top                      = top
	resizable.bottom                   = bottom
	resizable.corner_tr                = corner_tr
	resizable.corner_tl                = corner_tl
	resizable.corner_br                = corner_br
	resizable.corner_bl                = corner_bl
	resizable.compute_layout           = compute_layout
	return
}

ui_resizable_end :: proc( resizable : ^UI_Resizable, pos, size : ^Vec2 ) {
	using resizable
	ui_resizable_handles( & widget, pos, size,
		handle_width,
		color_non_default,
		color_default,
		left,
		right,
		top,
		bottom,
		corner_tr,
		corner_tl,
		corner_br,
		corner_bl,
		compute_layout)
}

ui_resizable_begin_auto :: proc() {

}

ui_resizable_end_auto :: proc() {

}

// Adds resizable handles to a widget
// TODO(Ed): Add centered resize support (use center alignment on shift-click)
ui_resizable_handles :: proc( parent : ^UI_Widget, pos : ^Vec2, size : ^Vec2,
	handle_width             : f32  = 15,
	handle_color_non_default : Color = Color_ResizeHandle,
	handle_color_default     : Color = Color_Transparent,
	left      := true,
	right     := true,
	top       := true,
	bottom    := true,
	corner_tr := true,
	corner_tl := true,
	corner_br := true,
	corner_bl := true,
	compute_layout := true) -> (drag_signal : b32)
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

	layout_bar_width := UI_Layout {
		flags     = { .Fixed_Width },
		alignment = {1, 0},
		margins   = { handle_width, handle_width, 0, 0 },
		size      = range2({handle_width, 0}, {}),
	}
	style_bar := UI_Style {
		bg_color  = Color_ResizeHandle,
		corner_radii = { 5, 0, 0, 0 }
	}
	theme_bar := to_ui_style_combo(style_bar)
	theme_bar.default.bg_color = handle_color_default
	theme_bar.default.corner_radii[0] = 0
	ui_layout(layout_bar_width)
	ui_style(theme_bar)
	layout_bar_height          := layout_bar_width
	layout_bar_height.flags     = {.Fixed_Height}
	layout_bar_height.size.min  = {0, handle_width}
	layout_bar_height.margins   = { 0, 0, handle_width, handle_width }
	layout_bar_height.alignment = {0, -1}

	context.user_ptr = & parent.label
	name :: proc(  ) -> StrRunesPair {
		parent_label := (transmute(^string) context.user_ptr) ^
		return str_intern(str_fmt_tmp("%v: %v", ))
	}

	if left do handle_left = ui_widget("Settings Menu: Resize Left Handle", flags )
	if right {
		handle_right  = ui_widget("Settings Menu: Resize Right Handle", flags)
		handle_right.layout.anchor.left = 1
		handle_right.layout.alignment   = { 0, 0 }
	}

	ui_layout(layout_bar_height)
	ui_style_ref().default.bg_color = handle_color_default
	if top do handle_top = ui_widget("Settings Menu: Resize Top Border", flags )
	if bottom {
		handle_bottom = ui_widget("Settings Menu: Resize Bottom Border", flags)
		using handle_bottom.layout
		anchor.top  = 1
		alignment   = { 0, 0 }
	}

	layout_corner := UI_Layout {
		flags        = { .Fixed_Width, .Fixed_Height },
		alignment    = {1, -1},
		size         = range2({handle_width, handle_width}, {}),
	}
	style_corner := UI_Style {
		bg_color     = Color_ResizeHandle,
		corner_radii = { 5, 0, 0, 0 },
	}
	ui_theme(layout_corner, style_corner)
	ui_style_ref().default.bg_color = handle_color_default
	if corner_tl do handle_corner_tl = ui_widget("Settings Menu: Corner TL", flags)
	if corner_tr {
		handle_corner_tr = ui_widget("Settings Menu: Corner TR", flags)
		handle_corner_tr.layout.anchor    = range2({1, 0}, {})
		handle_corner_tr.layout.alignment = {0, -1}
	}

	if corner_bl {
		handle_corner_bl = ui_widget("Settings Menu: Corner BL", flags)
		handle_corner_bl.layout.anchor    = range2({}, {0, 1})
		handle_corner_bl.layout.alignment = { 1, 0 }
	}
	if corner_br {
		handle_corner_br = ui_widget("Settings Menu: Corner BR", flags)
		handle_corner_br.layout.anchor    = range2({1, 0}, {0, 1})
		handle_corner_br.layout.alignment = {0, 0}
	}

	process_handle_drag :: #force_inline proc ( handle : ^UI_Widget,
		direction                :  Vec2,
		size_delta               :  Vec2,
		target_alignment         :  Vec2,
		pos                      : ^Vec2,
		size                     : ^Vec2,
		alignment                : ^Vec2, ) -> b32
	{
		ui := get_state().ui_context
		if ui.last_pressed_key != handle.key { return false }

		size_delta := size_delta
		pos_adjust := size^ * (alignment^ - target_alignment)

		@static was_dragging : b32 = false

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
		return was_dragging
	}

	delta     := get_state().input.mouse.delta
	alignment := & parent.layout.alignment

	if right     do drag_signal |= process_handle_drag( & handle_right,     {  1,  0 }, delta, {0, 0}, pos, size, alignment )
	if left      do drag_signal |= process_handle_drag( & handle_left,      { -1,  0 }, delta, {1, 0}, pos, size, alignment )
	if top       do drag_signal |= process_handle_drag( & handle_top,       {  0,  1 }, delta, {0, 0}, pos, size, alignment )
	if bottom    do drag_signal |= process_handle_drag( & handle_bottom,    {  0, -1 }, delta, {0, 1}, pos, size, alignment )
	if corner_tr do drag_signal |= process_handle_drag( & handle_corner_tr, {  1,  1 }, delta, {0, 0}, pos, size, alignment )
	if corner_tl do drag_signal |= process_handle_drag( & handle_corner_tl, { -1,  1 }, delta, {1, 0}, pos, size, alignment )
	if corner_br do drag_signal |= process_handle_drag( & handle_corner_br, {  1, -1 }, delta, {0, 1}, pos, size, alignment )
	if corner_bl do drag_signal |= process_handle_drag( & handle_corner_bl, { -1, -1 }, delta, {1, 1}, pos, size, alignment )

	ui_box_compute_layout(parent)
	return
}
#endregion("Resizable")

ui_spacer :: proc( label : string ) -> (widget : UI_Widget) {
	widget.box    = ui_box_make( {.Mouse_Clickable}, label )
	widget.signal = ui_signal_from_box( widget.box )

	widget.style.bg_color = Color_Transparent
	return
}

#region("Text")

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
#endregion("Text")

#region("Vertical Box")
/*
Vertical Boxes automatically manage a collection of widgets and
attempt to slot them adjacent to each other along the y-axis.

The user must provide the direction that the vbox will append entries.
How the widgets will be scaled will be based on the individual entires style flags.

All the usual behaviors that the style and box flags do apply when managed by the box widget.
Whether or not the horizontal box will scale the widget's width is if:
fixed size or "scale by ratio" flags are not used for the width.
The hbox will use the anchor's (range2) ratio.y value to determine the "stretch ratio".

Keep in mind the stretch ratio is only respected if no size.min.y value is violated for each of the widgets.
*/

UI_VBox :: struct {
	using widget : UI_Widget,
	direction    : UI_LayoutDirectionY,
}

// Boilerplate creation
ui_vbox_begin :: proc( direction : UI_LayoutDirectionY, label : string, flags : UI_BoxFlags = {}, compute_layout := false ) -> (vbox : UI_VBox) {
	// profile(#procedure)
	vbox.direction = direction
	vbox.box       = ui_box_make( flags, label )
	vbox.signal    = ui_signal_from_box( vbox.box )
	if compute_layout do ui_box_compute_layout(vbox)
	return
}

// Auto-layout children
ui_vbox_end :: proc( vbox : UI_VBox, height_ref : ^f32 = nil, compute_layout := true ) {
	// profile(#procedure)
	if compute_layout do ui_box_compute_layout(vbox)
	ui_layout_children_vertically( vbox.box, vbox.direction, height_ref )
}

// Auto-layout children and pop parent from parent stack
ui_vbox_end_pop_parent :: proc( vbox : UI_VBox ) {
	ui_parent_pop()
	ui_vbox_end(vbox)
}

@(deferred_out = ui_vbox_end_pop_parent)
ui_vbox :: #force_inline proc( direction : UI_LayoutDirectionY, label : string, flags : UI_BoxFlags = {} ) -> (vbox : UI_VBox) {
	vbox = ui_vbox_begin(direction, label, flags)
	ui_parent_push(vbox.widget)
	return
}
#endregion("Vertical Box")
