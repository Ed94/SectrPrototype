package sectr

import "base:runtime"
import lalg "core:math/linalg"

// Problably cursed way to setup a 'scope' for a widget
// ui_build :: #force_inline proc( captures : $Type, $maker : #type proc(captures : Type) -> $ReturnType ) -> ReturnType { return maker(captures) }

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
	btn_flags := UI_BoxFlags { .Mouse_Clickable }
	btn.box    = ui_box_make( btn_flags | flags, label )
	btn.signal = ui_signal_from_box( btn.box )
	return
}

#region("Drop Down")
UI_DropDown :: struct {
	btn          : UI_Widget,
	title        : UI_Widget,
	vbox         : UI_VBox,
	is_open      : b32,
	should_close : b32,
}

@(deferred_out = ui_drop_down_end_auto)
ui_drop_down :: proc( drop_down : ^UI_DropDown, label : string, title_text : StrRunesPair,
	direction         := UI_LayoutDirection_Y.Top_To_Bottom,
	btn_flags         := UI_BoxFlags{},
	vb_flags          := UI_BoxFlags{},
	vb_compute_layout := true,
	btn_theme   : ^UI_Theme = nil,
	title_theme : ^UI_Theme = nil,
	vb_parent   : ^UI_Box   = nil,
) -> (deferred : ^UI_DropDown)
{
	deferred = drop_down
	ui_drop_down_begin(drop_down, label, title_text, direction, btn_flags, vb_flags, btn_theme, title_theme, vb_parent, vb_compute_layout)
	if ! drop_down.is_open do return
	ui_parent_push(drop_down.vbox)
	return
}

// Its assumed that the drop down has a vertical box parent already pushed
ui_drop_down_begin :: proc( drop_down : ^UI_DropDown, label : string, title_text : StrRunesPair,
	direction := UI_LayoutDirection_Y.Top_To_Bottom,
	btn_flags := UI_BoxFlags{},
	vb_flags  := UI_BoxFlags{},
	btn_theme   : ^UI_Theme = nil,
	title_theme : ^UI_Theme = nil,
	vb_parent   : ^UI_Box   = nil,
	vb_compute_layout := false )
{
	using drop_down

	if btn_theme == nil do push(theme_drop_down_btn)
	else                do push(btn_theme ^)
	defer                  ui_theme_pop()
	btn = ui_button( str_intern_fmt("%s.btn", label).str );
	{
		btn.layout.padding.left = 4
		ui_parent(btn)

		if title_theme == nil do push(theme_text)
		else                  do push(title_theme ^)
		defer                    ui_theme_pop()
		title = ui_text( str_intern_fmt("%s.btn.title", label).str, title_text)
	}

	if btn.pressed {
		is_open = ! is_open
	}
	is_open &= ! should_close
	should_close = false

	if is_open == false do return

	scope(theme_transparent)
	if vb_parent != nil {
		ui_parent_push(vb_parent)
	}
	vbox = ui_vbox_begin( direction, str_intern_fmt("%v.vbox", label).str, flags = {.Mouse_Clickable}, compute_layout = vb_compute_layout )
	vbox.layout.anchor.ratio.y = 1.0

	if vb_parent != nil {
		ui_parent_pop()
	}
}

ui_drop_down_end :: proc( drop_down : ^UI_DropDown ) {
	if ! drop_down.is_open do return
	ui_vbox_end(drop_down.vbox)
}

ui_drop_down_end_auto :: proc( drop_down : ^UI_DropDown) {
	if ! drop_down.is_open do return
	ui_vbox_end(drop_down.vbox, compute_layout = false)
	ui_parent_pop()
}
#endregion("Drop Down")

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

UI_HBox :: struct {
	using widget : UI_Widget,
	direction    : UI_LayoutDirection_X,
}

ui_hbox_begin :: proc( direction : UI_LayoutDirection_X, label : string, flags : UI_BoxFlags = {} ) -> (hbox : UI_HBox) {
	// profile(#procedure)
	hbox.direction = direction
	hbox.box       = ui_box_make( flags, label )
	hbox.signal    = ui_signal_from_box(hbox.box)
	// ui_box_compute_layout(hbox)
	switch direction {
		case .Left_To_Right:
			hbox.layout.flags |= { .Order_Children_Left_To_Right }
		case .Right_To_Left:
			hbox.layout.flags |= { .Order_Children_Right_To_Left }
	}
	return
}

// Auto-layout children
ui_hbox_end :: proc( hbox : UI_HBox, width_ref : ^f32 = nil, compute_layout := false )
{
	// profile(#procedure)
	// if compute_layout do ui_box_compute_layout(hbox.box, dont_mark_fresh = true)
	// ui_layout_children_horizontally( hbox.box, hbox.direction, width_ref )
}

@(deferred_in_out= ui_hbox_end_auto)
ui_hbox :: #force_inline proc( direction : UI_LayoutDirection_X, label : string, flags : UI_BoxFlags = {}, width_ref : ^f32 = nil ) -> (hbox : UI_HBox) {
	hbox = ui_hbox_begin(direction, label, flags)
	ui_parent_push(hbox.box)
	return
}

// Auto-layout children and pop parent from parent stack
ui_hbox_end_auto :: #force_inline proc( direction : UI_LayoutDirection_X, label : string, flags : UI_BoxFlags = {}, width_ref : ^f32 = nil, hbox : UI_HBox ) {
	ui_hbox_end(hbox, width_ref)
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
	compute_layout := false ) -> (resizable : UI_Resizable)
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

// Adds resizable handles to a widget
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
	compute_layout := false) -> (drag_signal : b32)
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
			app_color := app_color_theme()
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
				corner_radii = {5, 5, 5, 5},
				blur_size    = 0,
				font         = get_state().default_font,
				text_color   = app_color.text_default,
				cursor       = {},
			}
			layout_combo = to_ui_layout_combo(layout)
			style_combo  = to_ui_style_combo(style)
			{
				using layout_combo.hot
				using style_combo.hot
				bg_color = app_color.resize_hndl_hot
			}
			{
				using layout_combo.active
				using style_combo.active
				bg_color = app_color.resize_hndl_active
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
		return str_intern(str_fmt("%v.%v", parent_label, label )).str
	}
	context.user_ptr = & parent.label

	Handle_Construction:
	{
		ui_parent(parent)
		theme_handle( theme, {handle_width, 0}, {handle_width,0})
		if left {
			handle_left = ui_widget(name("resize_handle_left"), flags )
			handle_left.layout.anchor.left  = 0
			handle_left.layout.anchor.right = 1
			handle_left.layout.alignment    = { 1, 0 }
		}
		if right {
			handle_right = ui_widget(name("resize_handle_right"), flags )
			handle_right.layout.anchor.left = 1
		}
		theme_handle( theme, {0, handle_width}, {0, handle_width})
		if top {
			handle_top = ui_widget(name("resize_handle_top"), flags )
			handle_top.layout.anchor.bottom = 1
			handle_top.layout.alignment     = { 0, 0 }
		}
		if bottom {
			handle_bottom = ui_widget(name("resize_handle_bottom"), flags)
			handle_bottom.layout.anchor.top  = 1
			handle_bottom.layout.alignment   = { 0, 1 }
		}
		theme_handle( theme, {0,0}, {handle_width, handle_width}, {.Fixed_Width, .Fixed_Height} )
		if corner_tl {
			handle_corner_tl = ui_widget(name("corner_top_left"), flags)
			handle_corner_tl.layout.anchor.bottom = 1
			handle_corner_tl.layout.alignment     = { 1, 0 }
		}
		if corner_tr {
			handle_corner_tr = ui_widget(name("corner_top_right"), flags)
			handle_corner_tr.layout.anchor    = range2({1, 1}, {})
			handle_corner_tr.layout.alignment = { 0, 0 }
		}
		if corner_bl {
			handle_corner_bl = ui_widget(name("corner_bottom_left"), flags)
			handle_corner_bl.layout.anchor    = range2({}, {0, 1})
			handle_corner_bl.layout.alignment = { 1, 1 }
		}
		if corner_br {
			handle_corner_br = ui_widget(name("corner_bottom_right"), flags)
			handle_corner_br.layout.anchor    = range2({1, 0}, {0, 1})
			handle_corner_br.layout.alignment = { 0, 1 }
		}
	}

	process_handle_drag :: proc ( handle : ^UI_Widget,
		direction                :  Vec2,
		target_alignment         :  Vec2,
		target_center_aligned    :  Vec2,
		pos                      : ^Vec2,
		size                     : ^Vec2,
		alignment                : ^Vec2, ) -> b32
	{
		@static active_context       : ^UI_State
		@static was_dragging         : b32 = false
		@static start_size           : Vec2
		@static prev_left_shift_held : b8
		@static prev_alignment       : Vec2

		ui := get_state().ui_context
		using handle
		if ui.last_pressed_key != key || (!active && (!released || !was_dragging)) do return false

		direction        := direction
		align_adjsutment := left_shift_held ? target_center_aligned : target_alignment

		size_delta  := ui_drag_delta()
		pos_adjust  := size^ * (alignment^ - align_adjsutment)
		pos_reverse := size^ * (alignment^ - prev_alignment)

		shift_changed := (left_shift_held != prev_left_shift_held)

		if active
		{
			if pressed
			{
				active_context = ui
				start_size     = size^
				prev_left_shift_held = left_shift_held
			}
			if (.Origin_At_Anchor_Center in parent.layout.flags) && !left_shift_held {
				pos_adjust  = size^ * 0.5 * direction
				pos_reverse = size^ * 0.5 * direction
			}

			latest_size := start_size + size_delta * direction

			if pressed
			{
				pos^ -= pos_adjust
			}
			else if shift_changed
			{
				if (.Origin_At_Anchor_Center in parent.layout.flags) {
					pos^      -= pos_reverse
					alignment^ = !left_shift_held ? target_center_aligned : target_alignment
				}
				else
				{
					if !left_shift_held {
						pos^ -= size^ * direction * 0.5
						alignment^ = target_center_aligned
					}
					else {
						pos^ += size^ * direction * 0.5 // Right
						alignment^ = target_alignment
					}
				}
			}
			else
			{
				size^      = latest_size
				alignment^ = align_adjsutment
			}
			was_dragging = true
		}
		else if released// && was_dragging
		{
			// This needed to be added as for some reason, this was getting called in screen_ui even when we were resizing with a handle in a worksapce
			if active_context != ui do return false

			if (.Origin_At_Anchor_Center in parent.layout.flags) && !left_shift_held  {
				pos_adjust  = size^ * 0.5 * direction
				pos_reverse = size^ * 0.5 * direction
			}
			pos^          += pos_adjust
			alignment^     = align_adjsutment
			was_dragging   = false
			start_size     = 0
		}

		prev_left_shift_held = handle.left_shift_held
		prev_alignment       = align_adjsutment
		return was_dragging
	}

	state     := get_state()
	alignment := & parent.layout.alignment

	if .Origin_At_Anchor_Center in parent.layout.flags
	{
		if right     do drag_signal |= process_handle_drag( & handle_right,     { 1,  0}, { 0.5,    0}, {0, 0}, pos, size, alignment )
		if left      do drag_signal |= process_handle_drag( & handle_left,      {-1,  0}, {-0.5,    0}, {0, 0}, pos, size, alignment )
		if top       do drag_signal |= process_handle_drag( & handle_top,       { 0,  1}, {   0,  0.5}, {0, 0}, pos, size, alignment )
		if bottom    do drag_signal |= process_handle_drag( & handle_bottom,    { 0, -1}, {   0, -0.5}, {0, 0}, pos, size, alignment )
		if corner_tr do drag_signal |= process_handle_drag( & handle_corner_tr, { 1,  1}, { 0.5,  0.5}, {0, 0}, pos, size, alignment )
		if corner_tl do drag_signal |= process_handle_drag( & handle_corner_tl, {-1,  1}, {-0.5,  0.5}, {0, 0}, pos, size, alignment )
		if corner_br do drag_signal |= process_handle_drag( & handle_corner_br, { 1, -1}, { 0.5, -0.5}, {0, 0}, pos, size, alignment )
		if corner_bl do drag_signal |= process_handle_drag( & handle_corner_bl, {-1, -1}, {-0.5, -0.5}, {0, 0}, pos, size, alignment )
	}
	else
	{
		if right     do drag_signal |= process_handle_drag( & handle_right,     {  1,  0 }, {0,  0}, { 0.5,    0}, pos, size, alignment )
		if left      do drag_signal |= process_handle_drag( & handle_left,      { -1,  0 }, {1,  0}, { 0.5,    0}, pos, size, alignment )
		if top       do drag_signal |= process_handle_drag( & handle_top,       {  0,  1 }, {0, -1}, { 0.0, -0.5}, pos, size, alignment )
		if bottom    do drag_signal |= process_handle_drag( & handle_bottom,    {  0, -1 }, {0,  0}, { 0.0, -0.5}, pos, size, alignment )
		if corner_tr do drag_signal |= process_handle_drag( & handle_corner_tr, {  1,  1 }, {0, -1}, { 0.5, -0.5}, pos, size, alignment )
		if corner_tl do drag_signal |= process_handle_drag( & handle_corner_tl, { -1,  1 }, {1, -1}, { 0.5, -0.5}, pos, size, alignment )
		if corner_br do drag_signal |= process_handle_drag( & handle_corner_br, {  1, -1 }, {0,  0}, { 0.5, -0.5}, pos, size, alignment )
		if corner_bl do drag_signal |= process_handle_drag( & handle_corner_bl, { -1, -1 }, {1,  0}, { 0.5, -0.5}, pos, size, alignment )
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

UI_ScrollBox :: struct {
	using widget : UI_Widget,
	scroll_bar   : UI_Widget,
	content      : UI_Widget,
}

// TODO(Ed): Implement
ui_scroll_box :: proc( label : string, flags : UI_BoxFlags ) -> (scroll_box : UI_ScrollBox) {

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

ui_text_wrap_panel :: proc( parent : ^UI_Widget )
{
	fatal("NOT IMPLEMENTED")
}
#endregion("Text")

#region("Text Input")
UI_TextInput_Policy :: struct {
	disallow_decimal       : b32,
	disallow_leading_zeros : b32,
	digits_only            : b32,
	digit_min, digit_max   : f32,
	max_length             : u32,
}

// Note(Ed): Currently only supports single-line input (may stay that way).
// This is a precursor to a proper text editor widget
UI_TextInputBox :: struct {
	using widget      : UI_Widget,
	input_str         : Array(rune),
	editor_cursor_pos : Vec2i,
	using policy      : UI_TextInput_Policy,
}

ui_text_input_box_reload :: #force_inline proc ( text_box : ^UI_TextInputBox, allocator : Allocator ) {
	text_box.input_str.backing = allocator
}

ui_text_input_box :: proc( text_input_box : ^UI_TextInputBox, label : string,
	flags     : UI_BoxFlags = {.Mouse_Clickable, .Focusable, .Click_To_Focus},
	allocator := context.allocator,
	policy    : UI_TextInput_Policy = {}
)
{
	// state        := get_state()
	iter_next    :: next
	input        := get_input_state()
	ui           := ui_context()

	text_input_box.box    = ui_box_make( flags, label )
	text_input_box.signal = ui_signal_from_box( text_input_box.box )
	using text_input_box

	// TODO(Ed): This thing needs to be pulling from the theme stack
	app_color := app_color_theme()
	if      active do style.bg_color = app_color.input_box_bg_active
	else if hot    do style.bg_color = app_color.input_box_bg_hot
	else           do style.bg_color = app_color.input_box_bg

	if input_str.header == nil {
		error : AllocatorError
		input_str, error = make( Array(rune), Kilo, allocator )
		ensure(error == AllocatorError.None, "Failed to allocate array for input_str of input_box")
	}

	if active
	{
		// TODO(Ed): Can problably be moved to ui_signal
		if ! was_active {
			ui.last_invalid_input_time = {}
		}
		if pressed {
			editor_cursor_pos = { i32(input_str.num), 0 }
		}

		// TODO(Ed): Abstract this to navigation bindings
		if btn_pressed(input.keyboard.left) {
			editor_cursor_pos.x = max(editor_cursor_pos.x - 1, 0)
		}
		if btn_pressed(input.keyboard.right) {
			editor_cursor_pos.x = min(i32(input_str.num), editor_cursor_pos.x + 1)
		}

		// TODO(Ed): Confirm btn_pressed is working (if not figure out why)
		// if btn_pressed(input.keyboard.left) {
		// 	if input_str.num > 0 {
		// 		editor_cursor_pos = max(0, editor_cursor_pos - 1)
		// 		remove_at( value_str, u64(editor_cursor_pos) )
		// 	}
		// }
		// if btn_pressed(input.keyboard.right) {
		// 	screen_ui.active = 0
		// }

		iter_obj  := input_key_event_iter(); iter := & iter_obj
		for event := iter_next( iter ); event != nil; event = iter_next( iter )
		{
			if event.frame_id != get_frametime().current_frame do break

			if event.key == .backspace && event.type == .Key_Pressed {
				if input_str.num > 0 {
						editor_cursor_pos.x = max(editor_cursor_pos.x - 1, 0)
						remove_at( input_str, u64(editor_cursor_pos.x) )
						break
				}
			}
			if event.key == .enter && event.type == .Key_Pressed {
				ui.active = 0
				break
			}
		}

		decimal_detected := false
		for code in input_codes_pressed_slice()
		{
			accept_digits  := ! digits_only || '0' <= code && code <= '9'
			accept_decimal := ! disallow_decimal || ! decimal_detected && code =='.'

			if disallow_leading_zeros && input_str.num == 0 && code == '0' {
				ui.last_invalid_input_time = time_now()
				continue
			}
			if max_length > 0 && input_str.num >= u64(max_length) {
				ui.last_invalid_input_time = time_now()
				continue
			}

			if accept_digits || accept_decimal {
				append_at( & input_str, code, u64(editor_cursor_pos.x))
				editor_cursor_pos.x = min(editor_cursor_pos.x + 1, i32(input_str.num))
			}
			else {
				ui.last_invalid_input_time = time_now()
				continue
			}
		}
		clear( get_state().input_events.codes_pressed )

		invalid_color := RGBA8 { 70, 40, 40, 255}

		// Visual feedback - change background color briefly when invalid input occurs
		feedback_duration :: 0.2 // seconds
		curr_duration := duration_seconds( time_diff( ui.last_invalid_input_time, time_now() ))
		if ui.last_invalid_input_time._nsec != 0 && curr_duration < feedback_duration {
			style.bg_color = invalid_color
		}
	}

	ui_parent(text_input_box)
	name :: proc( label : string ) -> string {
		parent_label := (transmute(^string) context.user_ptr) ^
		return str_intern(str_fmt("%v: %v", parent_label, label )).str
	}
	context.user_ptr = & parent.label

	// TODO(Ed): Allow for left and center alignment of text
	value_txt : UI_Widget; {
		scope(theme_text)
		value_txt = ui_text(name("input_str"), to_str_runes_pair(array_to_slice(input_str)))
		using value_txt
		layout.alignment      = {0.0, 0.0}
		layout.text_alignment = {1.0, 0.5}
		layout.anchor.left    = 0.0
		layout.size.min       = cast(Vec2) measure_text_size( text.str, style.font, layout.font_size, 0 )

		if active {
			ui_parent(value_txt)

			ascent, descent, line_gap := get_font_vertical_metrics(style.font, layout.font_size)
			cursor_height             := ascent - descent

			text_before_cursor := to_string(array_to_slice(input_str)[ :editor_cursor_pos.x ])
			cursor_x_offset    := measure_text_size(text_before_cursor, style.font, layout.font_size, 0).x
			text_size          := measure_text_size(to_string(array_to_slice(input_str)), style.font, layout.font_size, 0).x

			ui_layout( UI_Layout {
				flags     = { .Fixed_Width },
				size      = range2({1, 0}, {}),
				anchor    = range2({1.0, 0},{0.0, 0.0}),
				alignment = { 0.0, 0 },
				pos       = { cursor_x_offset - text_size, 0 }
			})
			cursor_widget := ui_widget(name("cursor"), {})
			cursor_widget.style.bg_color = RGBA8{255, 255, 255, 255}
			cursor_widget.layout.anchor.right = 0.0
		}
	}
}
#endregion("Text Input")

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
	direction    : UI_LayoutDirection_Y,
}

ui_vbox_begin :: proc( direction : UI_LayoutDirection_Y, label : string, flags : UI_BoxFlags = {}, height_ref : ^f32 = nil, compute_layout := false ) -> (vbox : UI_VBox) {
	// profile(#procedure)
	vbox.direction = direction
	vbox.box       = ui_box_make( flags, label )
	vbox.signal    = ui_signal_from_box( vbox.box )
	// if compute_layout do ui_box_compute_layout(vbox, dont_mark_fresh = true)
	switch direction {
		case .Top_To_Bottom:
			vbox.layout.flags |= { .Order_Children_Top_To_Bottom }
		case .Bottom_To_Top:
			vbox.layout.flags |= { .Order_Children_Bottom_To_Top }
	}
	return
}

// Auto-layout children
ui_vbox_end :: proc( vbox : UI_VBox, height_ref : ^f32 = nil, compute_layout := false ) {
	// profile(#procedure)
	// if compute_layout do ui_box_compute_layout(vbox, dont_mark_fresh = true)
	// ui_layout_children_vertically( vbox.box, vbox.direction, height_ref )
}

// Auto-layout children and pop parent from parent stack
ui_vbox_end_pop_parent :: proc( direction : UI_LayoutDirection_Y, label : string, flags : UI_BoxFlags = {}, height_ref : ^f32 = nil, compute_layout := false, vbox : UI_VBox) {
	ui_parent_pop()
	ui_vbox_end(vbox)
}

@(deferred_in_out = ui_vbox_end_pop_parent)
ui_vbox :: #force_inline proc( direction : UI_LayoutDirection_Y, label : string, flags : UI_BoxFlags = {}, height_ref : ^f32 = nil, compute_layout := false ) -> (vbox : UI_VBox) {
	vbox = ui_vbox_begin(direction, label, flags, height_ref, compute_layout )
	ui_parent_push(vbox.widget)
	return
}
#endregion("Vertical Box")
