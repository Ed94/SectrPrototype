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

	draggable := ui_widget( "Draggable Box!", UI_BoxFlags { .Mouse_Clickable, .Focusable, .Click_To_Focus } )

	if draggable.first_frame {
		debug.draggable_box_pos  = draggable.style.layout.pos
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
		original_distance := linalg.distance(ui.cursor_active_start, center)
		cursor_distance   := linalg.distance(draggable.cursor_pos, center)
		scale_factor      := cursor_distance * (1 / original_distance)

		debug.draggable_box_size = og_layout.size * scale_factor
	}

	if ui.hot_resizable || ui.active_resizing {
		draggable.style.bg_color = Color_Blue
	}

	draggable.style.layout.pos  = debug.draggable_box_pos
	draggable.style.layout.size = debug.draggable_box_size
}
