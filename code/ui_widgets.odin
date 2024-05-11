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

//region Horizontal Box
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
	hbox.signal    = ui_signal_from_box( hbox.box )
	return
}

// Auto-layout children
ui_hbox_end :: proc( hbox : UI_HBox, width_ref : ^f32 = nil ) {
	// profile(#procedure)
	hbox_width : f32
	if width_ref != nil {
		hbox_width = width_ref ^
	}
	else {
		hbox_width = hbox.computed.content.max.x - hbox.computed.content.min.x
	}

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

		total_stretch_ratio += anchor.ratio.x
	}

	avail_flex_space := hbox_width - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space : f32 )
	{
		using child.style
		if ! (.Fixed_Width in child.style.flags) {
			size.min.x = anchor.ratio.x * (1 / total_stretch_ratio) * avail_flex_space
		}
		flags    |= {.Fixed_Width}
		alignment = {0, 1}
	}

	space_used : f32 = 0.0
	switch hbox.direction{
		case .Right_To_Left:
			for child := hbox.last; child != nil; child = child.prev {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.style
				anchor      = range2({0, 0}, {0, 0})
				pos.x       = space_used
				space_used += size.min.x
			}
		case .Left_To_Right:
			for child := hbox.first; child != nil; child = child.next {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.style
				anchor      = range2({0, 0}, {0, 0})
				pos.x       = space_used
				space_used += size.min.x
			}
	}
}

// Auto-layout children and pop parent from parent stack
ui_hbox_end_pop_parent :: proc( hbox : UI_HBox ) {
	// ui_box_compute_layout(hox.widget)
	ui_parent_pop()
	ui_hbox_end(hbox)
}

@(deferred_out = ui_hbox_end_pop_parent)
ui_hbox :: #force_inline proc( direction : UI_LayoutDirectionX, label : string, flags : UI_BoxFlags = {} ) -> (hbox : UI_HBox) {
	hbox = ui_hbox_begin(direction, label, flags)
	ui_parent_push(hbox.widget)
	return
}
//endregion Horizontal Box

// Adds resizable handles to a widget
// TODO(Ed): Add centered resize support (use center alignment on shift-click)
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

ui_spacer :: proc( label : string ) -> (widget : UI_Widget) {
	widget.box    = ui_box_make( {.Mouse_Clickable}, label )
	widget.signal = ui_signal_from_box( widget.box )

	widget.style.bg_color = Color_Transparent
	return
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
ui_vbox_begin :: proc( direction : UI_LayoutDirectionY, label : string, flags : UI_BoxFlags = {} ) -> (vbox : UI_VBox) {
	// profile(#procedure)
	vbox.direction = direction
	vbox.box       = ui_box_make( flags, label )
	vbox.signal    = ui_signal_from_box( vbox.box )
	return
}

// Auto-layout children
ui_vbox_end :: proc( vbox : UI_VBox, height_ref : ^f32 = nil ) {
	// profile(#procedure)

	vbox_height : f32
	if height_ref != nil {
		vbox_height = height_ref ^
	}
	else {
		vbox_height = vbox.computed.bounds.max.y - vbox.computed.bounds.min.y
	}

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := vbox.first; child != nil; child = child.next
	{
		using child
		using style.layout
		scaled_width_by_height : b32 = b32(.Scale_Width_By_Height_Ratio in style.flags)
		if .Fixed_Height in style.flags
		{
			if scaled_width_by_height {
				width  := size.max.x != 0 ? size.max.x : vbox_height
				height := width * size.min.y

				size_req_children += height
				continue
			}

			size_req_children += size.min.y
			continue
		}

		total_stretch_ratio += anchor.ratio.y
	}

	avail_flex_space := vbox_height - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space : f32 )
	{
		using child.style
		if ! (.Fixed_Height in child.style.flags) {
			size.min.y = anchor.ratio.y * (1 / total_stretch_ratio) * avail_flex_space
		}
		flags    |= {.Fixed_Height}
		alignment = {0, 0}
	}

	space_used : f32 = 0.0
	switch vbox.direction {
		case .Top_To_Bottom:
			for child := vbox.last; child != nil; child = child.prev {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.style
				anchor      = range2({0, 0}, {0, 1})
				pos.y       = space_used
				space_used += size.min.y
			}
		case .Bottom_To_Top:
			for child := vbox.first; child != nil; child = child.next {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.style
				anchor      = range2({0, 0}, {0, 1})
				pos.y       = space_used
				space_used += size.min.y
			}
	}
}

// Auto-layout children and pop parent from parent stack
ui_vbox_end_pop_parent :: proc( vbox : UI_VBox ) {
	// ui_box_compute_layout(vbox)
	ui_parent_pop()
	ui_vbox_end(vbox)
}

@(deferred_out = ui_vbox_end_pop_parent)
ui_vbox :: #force_inline proc( direction : UI_LayoutDirectionY, label : string, flags : UI_BoxFlags = {} ) -> (vbox : UI_VBox) {
	vbox = ui_vbox_begin(direction, label, flags)
	ui_parent_push(vbox.widget)
	return
}
//endregion Vertical Box
