package sectr

UI_ThemePtr :: struct {
	layout : ^UI_LayoutCombo,
	style  : ^UI_StyleCombo,
}

UI_Theme :: struct {
	layout : UI_LayoutCombo,
	style  : UI_StyleCombo,
}

ui_theme_push_via_proc :: #force_inline proc( procedure : #type proc() -> UI_Theme ) { ui_theme_push(procedure()) }
ui_theme_push_via_theme ::#force_inline proc( theme : UI_Theme ) {
	ui_layout_push( theme.layout )
	ui_style_push( theme.style )
}

ui_theme_pop :: #force_inline proc() {
	ui_layout_pop()
	ui_style_pop()
}

@(deferred_none = ui_theme_pop)
ui_theme_scope_via_layout_style :: #force_inline proc( layout : UI_Layout, style : UI_Style ) {
	using ui := get_state().ui_context
	ui_layout_push( layout )
	ui_style_push( style )
}

@(deferred_none = ui_theme_pop)
ui_theme_scope_via_combos :: #force_inline proc( layout : UI_LayoutCombo, style : UI_StyleCombo ) {
	using ui := get_state().ui_context
	ui_layout_push( layout )
	ui_style_push( style )
}

@(deferred_none = ui_theme_pop)
ui_theme_scope_via_proc :: #force_inline proc( procedure : #type proc() -> UI_Theme ) { ui_theme_push(procedure()) }

@(deferred_none = ui_theme_pop)
ui_theme_scope_via_theme :: #force_inline proc( theme : UI_Theme ) {
	using ui := get_state().ui_context
	ui_theme_push(theme)
}
