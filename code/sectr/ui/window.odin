package sectr

UI_Window :: struct
{
	frame        : UI_Widget,
	frame_bar    : UI_HBox,
	tile_text    : UI_Widget,
	maximize_btn : UI_Widget,
	close_btn    : UI_Widget,
	position     : Vec2,
	size         : Vec2,
	min_size     : Vec2,
	is_open      : b32,
	is_maximized : b32,
}

ui_window_begin :: proc( window : ^UI_Window, label : string,
	title       : StrRunesPair = {},
	closable    := true,
	maximizable := true,
	draggable   := true,
	resizable   := true
) -> (dragged, resized, maximized : b32)
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
			// .Size_To_Content,
			.Fixed_Width, .Fixed_Height, 
			// .Min_Size_To_Content_Y,
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

	if len(title.str) == 0 && ! closable && ! maximizable && ! draggable do return
	ui_parent(frame)

	draggable_flag : UI_BoxFlags = draggable ? {.Mouse_Clickable} : {}

	scope(theme_window_bar)
	frame_bar = ui_hbox(.Left_To_Right, str_intern_fmt("%v.frame_bar", label). str, draggable_flag);
	ui_parent(frame_bar)

	scope(theme_text)
	tile_text = ui_text( str_intern_fmt("%v.title_text", label).str, title, {.Disabled}); {
		using tile_text
		layout.anchor.ratio.x = 1.0
		layout.margins        = { 0, 0, 15, 0}
		layout.font_size      = 14
	}

	scope(theme_window_bar_btn)
	maximize_btn = ui_button( str_intern_fmt("%v.maximize_btn", label).str ); {
		using maximize_btn
		if maximize_btn.pressed {
			is_maximized = ~is_maximized
			maximized = true
		}
		if is_maximized do text = str_intern("min")
		else do text = str_intern("max")
	}
	close_btn = ui_button( str_intern_fmt("%v.close_btn", label).str ); {
		using close_btn
		text = str_intern("close")
		if close_btn.hot     do style.bg_color =  app_color_theme().window_btn_close_bg_hot
		if close_btn.pressed do is_open = false
		style.corner_radii = { 0, 0, 0, 0 }
	}
	
	if frame_bar.active {
		position += get_input_state().mouse.delta
		dragged   = true
	}

	return
}
