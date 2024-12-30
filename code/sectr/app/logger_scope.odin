package sectr

UI_LoggerScope :: struct
{
	using window : UI_Window,
}

ui_logger_scope_builder :: proc( captures : rawptr = nil ) -> ( should_raise : b32 = false )
{
	profile("Logger Scope")

	logger_scope := cast(^UI_LoggerScope) captures
	using logger_scope

	scope(theme_window_panel)
	dragged, resized, maximized := ui_window_begin( & window, "Logger Scope: Window")

	should_raise |= dragged | resized | maximized
	return
}

ui_logger_scope_open :: #force_inline proc "contextless" () {
	get_state().screen_ui.logger_scope.is_open = true
}
