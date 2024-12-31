package sectr

UI_LoggerScope :: struct
{
	using window : UI_Window,
}

ui_log_scope_builder :: proc( captures : rawptr = nil ) -> ( should_raise : b32 = false )
{
	profile("ui_log_scope_builder")

	log_scope := cast(^UI_LoggerScope) captures
	using log_scope

	scope(theme_window_panel)
	dragged, resized, maximized, closed := ui_window( & window, "log_scope.window", str_intern("Log Scope"), child_layout = .Top_To_Bottom )

	should_raise |= dragged | resized | maximized
	return
}

ui_log_scope_open :: #force_inline proc "contextless" () {
	get_state().screen_ui.log_scope.is_open = true
}
