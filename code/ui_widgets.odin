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
	theme             : ^UI_Theme,
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
	handle_width : f32  = 15,
	theme        : ^UI_Theme,
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

	resizable.handle_width   = handle_width
	resizable.theme          = theme
	resizable.left           = left
	resizable.right          = right
	resizable.top            = top
	resizable.bottom         = bottom
	resizable.corner_tr      = corner_tr
	resizable.corner_tl      = corner_tl
	resizable.corner_br      = corner_br
	resizable.corner_bl      = corner_bl
	resizable.compute_layout = compute_layout
	return
}

ui_resizable_end :: proc( resizable : ^UI_Resizable, pos, size : ^Vec2 ) {
	using resizable
	ui_resizable_handles( & widget, pos, size,
		handle_width,
		theme,
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
	handle_width : f32  = 15,
	theme        : ^UI_Theme = nil,
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

	@(deferred_none = ui_theme_pop)
	theme_handle :: proc( base : ^UI_Theme, margins, size : Vec2, flags : UI_LayoutFlags = {})
	{
		layout_combo : UI_LayoutCombo
		style_combo  : UI_StyleCombo
		if base != nil
		{
			layout_combo = base.layout
			style_combo  = base.style
			{
				layout_combo.default.margins  = {margins.x, margins.x, margins.y, margins.y}
				layout_combo.default.size.min = size
			}
			{
				layout_combo.hot.margins  = {margins.x, margins.x, margins.y, margins.y}
				layout_combo.hot.size.min = size
			}
			{
				layout_combo.active.margins  = {margins.x, margins.x, margins.y, margins.y}
				layout_combo.active.size.min = size
			}
		}
		else
		{
			layout := UI_Layout {
				flags          = flags,
				anchor         = range2({},{}),
				alignment      = {0, 0},
				text_alignment = {0.0, 0.0},
				font_size      = 16,
				margins        = to_ui_layout_side(margins),
				padding        = {0, 0, 0, 0},
				border_width   = 0,
				pos            = {0, 0},
				size           = range2(size,{})
			}
			style := UI_Style {
				bg_color     = Color_Transparent,
				border_color = Color_Transparent,
				corner_radii = {5, 0, 0, 0},
				blur_size    = 0,
				font         = get_state().default_font,
				text_color   = Color_ThmDark_Text_Default,
				cursor       = {},
			}
			layout_combo = to_ui_layout_combo(layout)
			style_combo  = to_ui_style_combo(style)
			{
				using layout_combo.hot
				using style_combo.hot
				bg_color = Color_ThmDark_ResizeHandle_Hot
			}
			{
				using layout_combo.active
				using style_combo.active
				bg_color = Color_ThmDark_ResizeHandle_Active
			}
		}
		theme := UI_Theme {
			layout_combo, style_combo
		}
		ui_layout_push(theme.layout)
		ui_style_push(theme.style)
	}

	flags := UI_BoxFlags { .Mouse_Clickable }

	name :: proc( label : string ) -> string {
		parent_label := (transmute(^string) context.user_ptr) ^
		return str_intern(str_fmt_alloc("%v: %v", parent_label, label )).str
	}
	context.user_ptr = & parent.label

	#region("Handle & Corner construction")
	theme_handle( theme, {handle_width, 0}, {handle_width,0})
	if left {
		handle_left = ui_widget(name("resize_handle_left"), flags )
		handle_left.layout.anchor.left  = 0
		handle_left.layout.anchor.right = 1
		handle_left.layout.alignment    = {1, 0}
	}
	if right {
		handle_right = ui_widget(name("resize_handle_right"), flags )
		handle_right.layout.anchor.left = 1
	}
	theme_handle( theme, {0, handle_width}, {0, handle_width})
	if top {
		handle_top = ui_widget(name("resize_handle_top"), flags )
		handle_top.layout.anchor.bottom = 1
		handle_top.layout.alignment     = {0, -1}
	}
	if bottom {
		handle_bottom = ui_widget("resize_handle_bottom", flags)
		handle_bottom.layout.anchor.top  = 1
		handle_bottom.layout.alignment   = { 0, 0 }
	}
	theme_handle( theme, {0,0}, {handle_width, handle_width}, {.Fixed_Width, .Fixed_Height} )
	if corner_tl {
		handle_corner_tl = ui_widget(name("corner_top_left"), flags)
		handle_corner_tl.layout.alignment = {1, -1}
	}
	if corner_tr {
		handle_corner_tr = ui_widget(name("corner_top_right"), flags)
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
	#endregion("Handle & Corner construction")

	process_handle_drag :: #force_inline proc ( handle : ^UI_Widget,
		direction                :  Vec2,
		size_delta               :  Vec2,
		target_alignment         :  Vec2,
		target_center_aligned    :  Vec2,
		pos                      : ^Vec2,
		size                     : ^Vec2,
		alignment                : ^Vec2, ) -> b32
	{
		@static active_context : ^UI_State
		@static was_dragging : b32 = false
		@static start_size   : Vec2

		ui := get_state().ui_context
		if ui.last_pressed_key != handle.key do return false
		using handle

		direction        := direction
		target_alignment := target_alignment

		size_delta := ui_drag_delta()
		pos_adjust := size^ * (alignment^ - target_alignment)

		if active
		{
			if pressed
			{
				active_context = ui
				start_size     = size^
				if .Origin_At_Anchor_Center in parent.layout.flags {
					pos_adjust = size^ * 0.5 * direction
				}
			}
			size^ = start_size + size_delta * direction
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
			// This needed to be added as for some reason, this was getting called in screen_ui even when we were resizing with a handle in a worksapce
			if active_context != ui do return false

			if .Origin_At_Anchor_Center in parent.layout.flags {
				pos_adjust = size^ * 0.5 * direction
			}
			pos^          += pos_adjust
			alignment^     = target_alignment
			was_dragging   = false
			start_size     = 0
			active_context = ui
		}
		return was_dragging
	}

	state := get_state()
	delta     := state.input.mouse.delta //state.ui_context == & state.screen_ui ? state.input.mouse.delta : ui_ws_drag_delta()
	alignment := & parent.layout.alignment

	if .Origin_At_Anchor_Center in parent.layout.flags
	{
		if right     do drag_signal |= process_handle_drag( & handle_right,     { 1,  0}, delta, { 0.5,    0}, {}, pos, size, alignment )
		if left      do drag_signal |= process_handle_drag( & handle_left,      {-1,  0}, delta, {-0.5,    0}, {}, pos, size, alignment )
		if top       do drag_signal |= process_handle_drag( & handle_top,       { 0,  1}, delta, {   0,  0.5}, {}, pos, size, alignment )
		if bottom    do drag_signal |= process_handle_drag( & handle_bottom,    { 0, -1}, delta, {   0, -0.5}, {}, pos, size, alignment )
		if corner_tr do drag_signal |= process_handle_drag( & handle_corner_tr, { 1,  1}, delta, { 0.5,  0.5}, {}, pos, size, alignment )
		if corner_tl do drag_signal |= process_handle_drag( & handle_corner_tl, {-1,  1}, delta, {-0.5,  0.5}, {}, pos, size, alignment )
		if corner_br do drag_signal |= process_handle_drag( & handle_corner_br, { 1, -1}, delta, { 0.5, -0.5}, {}, pos, size, alignment )
		if corner_bl do drag_signal |= process_handle_drag( & handle_corner_bl, {-1, -1}, delta, {-0.5, -0.5}, {}, pos, size, alignment )
	}
	else
	{
		if right     do drag_signal |= process_handle_drag( & handle_right,     {  1,  0 }, delta, {0,  0}, {}, pos, size, alignment )
		if left      do drag_signal |= process_handle_drag( & handle_left,      { -1,  0 }, delta, {1,  0}, {}, pos, size, alignment )
		if top       do drag_signal |= process_handle_drag( & handle_top,       {  0,  1 }, delta, {0, -1}, {}, pos, size, alignment )
		if bottom    do drag_signal |= process_handle_drag( & handle_bottom,    {  0, -1 }, delta, {0,  0}, {}, pos, size, alignment )
		if corner_tr do drag_signal |= process_handle_drag( & handle_corner_tr, {  1,  1 }, delta, {0, -1}, {}, pos, size, alignment )
		if corner_tl do drag_signal |= process_handle_drag( & handle_corner_tl, { -1,  1 }, delta, {1, -1}, {}, pos, size, alignment )
		if corner_br do drag_signal |= process_handle_drag( & handle_corner_br, {  1, -1 }, delta, {0,  0}, {}, pos, size, alignment )
		if corner_bl do drag_signal |= process_handle_drag( & handle_corner_bl, { -1, -1 }, delta, {1,  0}, {}, pos, size, alignment )
	}

	if drag_signal && compute_layout do ui_box_compute_layout(parent)
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
