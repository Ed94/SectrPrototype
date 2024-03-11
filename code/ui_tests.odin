package sectr

import "core:math/linalg"

test_hover_n_click :: proc()
{
	state := get_state(); using state

	first_btn := ui_button( "FIRST BOX!" )
	if first_btn.left_clicked || debug.frame_2_created {
		debug.frame_2_created = true

		second_layout := first_btn.style.layout
		second_layout.pos = { 250, 0 }
		ui_set_layout( second_layout )

		second_box := ui_button( "SECOND BOX!")
	}
}

test_draggable :: proc()
{
	state := get_state(); using state
	ui    := ui_context

	draggable_layout := UI_Layout {
		anchor    = {},
		// alignment = { 0.0, 0.5 },
		alignment = { 0.5, 0.5 },
		text_alignment = { 0.0, 0.0 },
		// alignment = { 1.0, 1.0 },
		// corner_radii = { 0.3, 0.3, 0.3, 0.3 },
		pos       = { 0, 0 },
		size      = { 200, 200 },
	}
	ui_style_theme_set_layout( draggable_layout )

	draggable := ui_widget( "Draggable Box!", UI_BoxFlags { .Mouse_Clickable, .Mouse_Resizable } )
	if draggable.first_frame {
		debug.draggable_box_pos  = draggable.style.layout.pos + { 0, -100 }
		debug.draggable_box_size = draggable.style.layout.size
	}

	// Dragging
	if draggable.dragging {
		debug.draggable_box_pos += mouse_world_delta()
	}

	// Resize
	if draggable.resizing
	{
		og_layout := ui_context.active_start_style.layout

		center            := debug.draggable_box_pos
		original_distance := linalg.distance(ui.active_start_signal.cursor_pos, center)
		cursor_distance   := linalg.distance(draggable.cursor_pos, center)
		scale_factor      := cursor_distance * (1 / original_distance)

		debug.draggable_box_size = og_layout.size * scale_factor
	}

	if (ui.hot == draggable.key) && (ui.hot_resizable || ui.active_start_signal.resizing) {
		draggable.style.bg_color = Color_Blue
	}

	draggable.style.layout.pos  = debug.draggable_box_pos
	draggable.style.layout.size = debug.draggable_box_size
}

test_text_box :: proc()
{
	state := get_state(); using state
	ui    := ui_context

	@static pos : Vec2
	style := ui_style_peek( .Default )
	ui_style_theme( { styles = { style, style, style, style, }} )

	text := str_intern( "Lorem ipsum dolor sit amet")
	font_size := 30

	text_box := ui_text("TEXT BOX!", text, flags = { .Mouse_Clickable })
	if text_box.first_frame {
		pos = text_box.style.layout.pos
	}

	if text_box.dragging {
		pos += mouse_world_delta()
	}

	text_box.style.layout.pos = pos
}