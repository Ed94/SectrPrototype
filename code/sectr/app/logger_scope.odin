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
	dragged, resized, maximized, closed := ui_window( & window, "Logger Scope: Window", str_intern("Log Scope"), child_layout = .Top_To_Bottom )

	should_raise |= dragged | resized | maximized
	return
}

ui_logger_scope_open :: #force_inline proc "contextless" () {
	get_state().screen_ui.logger_scope.is_open = true
}
