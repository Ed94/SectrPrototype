package sectr

UI_LoggerScope :: struct
{
	
}

ui_logger_scope :: proc( captures : rawptr = nil ) -> ( should_raise : b32 = false )
{
	profile("Logger Scope")
	return
}
