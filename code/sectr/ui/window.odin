package sectr

UI_Window :: struct
{
	frame        : UI_Widget,
	bar          : UI_HBox,
	children_box : struct #raw_union { 
		box   : UI_Widget,
		hbox  : UI_HBox,
		vbox  : UI_VBox,
	},
	tile_text    : UI_Widget,
	maximize_btn : UI_Widget,
	close_btn    : UI_Widget,
	position     : Vec2,
	size         : Vec2,
	min_size     : Vec2,
	is_open      : b32,
	is_maximized : b32,
}

// Same as UI_LayoutDirection_XY but children may have the option to have their container just be a sub-box
UI_Window_ChildLayout :: enum(i32) {
	None,
	Left_To_Right,
	Right_to_Left,
	Top_To_Bottom,
	Bottom_To_Top,
}

@(deferred_in=ui_window_end_auto)
ui_window :: proc (window : ^UI_Window, label : string,
	title       : StrRunesPair = {},
	closable    := true,
	maximizable := true,
	draggable   := true,
	resizable   := true,
	child_layout : UI_Window_ChildLayout = .None
) -> (dragged, resized, maximized, closed : b32)
{
	dragged, resized, maximized, closed = ui_window_begin(window, label, title, closable, maximizable, draggable, resizable, child_layout)
	ui_parent_push(window.frame)
	return
}

ui_window_begin :: proc( window : ^UI_Window, label : string,
	title        : StrRunesPair = {},
	closable     := true,
	maximizable  := true, 
	draggable    := true,
	resizable    := true,
	child_layout : UI_Window_ChildLayout = .None
) -> (dragged, resized, maximized, closed : b32)
{
	using window
	if ! is_open do return

	if size.x < min_size.x do size.x = min_size.x
	if size.y < min_size.y do size.y = min_size.y

	frame = ui_widget(label, {})
	using frame

	if ! is_maximized 
	{
		layout.flags = {
			.Fixed_Width, .Fixed_Height, 
			.Fixed_Position_X, .Fixed_Position_Y, 
			.Origin_At_Anchor_Center 
		}
		layout.pos   = position
		layout.size  = range2( size, {})
	}
	else
	{
		layout.flags = {.Origin_At_Anchor_Center }
		layout.pos   = {}
	}

	if resizable {
		resized = ui_resizable_handles( & frame, & position, & size)
	}

	if len(title.str) > 0 || closable || maximizable || draggable {
		dragged, maximized, closed = ui_window_bar(window, title, closable, maximizable, draggable)
	}

	// child_bounds = bar.computed.bounds = 
	// child_position

	switch child_layout
	{
		case .None:


		case .Left_To_Right:
		case .Right_to_Left:
		case .Top_To_Bottom:
		case .Bottom_To_Top:
	}

	return
}

ui_window_end :: proc (window : ^UI_Window)
{
}

ui_window_end_auto :: proc( window : ^UI_Window, label : string,
	title        : StrRunesPair = {},
	closable     := true,
	maximizable  := true,
	draggable    := true,
	resizable    := true,
	child_layout : UI_Window_ChildLayout = .None
)
{
	ui_parent_pop()
}

ui_window_bar :: proc( window : ^UI_Window,
	title       : StrRunesPair = {},
	closable    := true,
	maximizable := true,
	draggable   := true,
) -> (dragged, maximized, closed : b32)
{
	using window
	ui_parent(frame)
	draggable_flag : UI_BoxFlags = draggable ? {.Mouse_Clickable} : {}

	scope(theme_window_bar)
	bar = ui_hbox(.Left_To_Right, str_intern_fmt("%v.bar", frame.label). str, draggable_flag);
	ui_parent(bar)

	if len(title.str) > 0
	{
		scope(theme_text)
		tile_text = ui_text( str_intern_fmt("%v.title_text", bar.label).str, title, {.Disabled}); {
			using tile_text
			layout.anchor.ratio.x = 1.0
			layout.margins        = { 0, 0, 15, 0}
			layout.font_size      = 14
		}
	}

	scope(theme_window_bar_btn)
	if maximizable 
	{
		maximize_btn = ui_button( str_intern_fmt("%v.maximize_btn", bar.label).str ); {
			using maximize_btn
			if maximize_btn.pressed {
				is_maximized = ~is_maximized
				maximized = true
			}
			if is_maximized do text = str_intern("min")
			else do text = str_intern("max")
		}
	}
	if closable
	{
		close_btn = ui_button( str_intern_fmt("%v.close_btn", bar.label).str ); {
			using close_btn
			text = str_intern("close")
			if close_btn.hot     do style.bg_color = app_color_theme().window_btn_close_bg_hot
			if close_btn.pressed {
				is_open = false
				closed  = true
			}
			style.corner_radii = { 0, 0, 0, 0 }
		}
	}

	if bar.active {
		position += get_input_state().mouse.delta
		dragged   = true
	}

	return
}
