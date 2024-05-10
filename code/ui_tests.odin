package sectr

import "core:math/linalg"
import str "core:strings"

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
		alignment      = { 0.5, 0.5 },
		text_alignment = { 0.0, 0.0 },
		// alignment = { 1.0, 1.0 },
		// corner_radii = { 0.3, 0.3, 0.3, 0.3 },
		pos       = { 0, 0 },
		size      = range2({ 200, 200 }, {}),
	}
	ui_style_theme_set_layout( draggable_layout )

	draggable := ui_widget( "Draggable Box!", UI_BoxFlags { .Mouse_Clickable, .Mouse_Resizable } )
	if draggable.first_frame {
		debug.draggable_box_pos  = draggable.style.layout.pos + { 0, -100 }
		debug.draggable_box_size = draggable.style.layout.size.min
	}

	// Dragging
	if draggable.active {
		debug.draggable_box_pos += mouse_world_delta()
	}

	if (ui.hot == draggable.key) {
		draggable.style.bg_color = Color_Blue
	}

	draggable.style.layout.pos  = debug.draggable_box_pos
	draggable.style.layout.size.min = debug.draggable_box_size

	draggable.text       = { str_fmt_alloc("%v", debug.draggable_box_pos), {} }
	draggable.text.runes = to_runes(draggable.text.str)
}

test_parenting :: proc( default_layout : ^UI_Layout, frame_style_default : ^UI_Style )
{
	state := get_state(); using state
	ui    := ui_context

	// frame := ui_widget( "Frame", {} )
	// ui_parent(frame)
	parent_layout := default_layout ^
	parent_layout.size      = range2( { 300, 300 }, {} )
	parent_layout.alignment = { 0.5, 0.5 }
	parent_layout.margins   = { 100, 100, 100, 100 }
	parent_layout.padding   = { 5, 10, 5, 5 }
	parent_layout.pos       = { 0, 0 }

	parent_theme := frame_style_default ^
	parent_theme.layout = parent_layout
	parent_theme.flags = {
		// .Fixed_Position_X, .Fixed_Position_Y,
		.Fixed_Width, .Fixed_Height,
	}
	ui_theme_via_style(parent_theme)

	parent :=	ui_widget( "Parent", { .Mouse_Clickable, .Mouse_Resizable })
	ui_parent(parent)
	{
		if parent.first_frame {
			debug.draggable_box_pos  = parent.style.layout.pos
			debug.draggable_box_size = parent.style.layout.size.min
		}
		if parent.active {
			debug.draggable_box_pos += mouse_world_delta()
		}
		if (ui.hot == parent.key) {
			parent.style.bg_color = Color_Blue
		}
		parent.style.layout.pos      = debug.draggable_box_pos
		parent.style.layout.size.min = debug.draggable_box_size
	}

	child_layout := default_layout ^
	child_layout.size      = range2({ 0, 0 }, { 0, 0 })
	child_layout.alignment = { 0.5, 0.5 }
	child_layout.margins   = { 20, 20, 20, 20 }
	child_layout.padding   = { 5, 5, 5, 5 }
	child_layout.anchor    = range2({ 0.2, 0.1 }, { 0.1, 0.15 })
	child_layout.pos       = { 0, 0 }

	child_theme := frame_style_default ^
	child_theme.bg_color = Color_GreyRed
	child_theme.flags = {
		// .Fixed_Width, .Fixed_Height,
		.Origin_At_Anchor_Center
	}
	child_theme.layout = child_layout
	ui_theme_via_style(child_theme)
	child := ui_widget( "Child", { .Mouse_Clickable })
}

test_text_box :: proc()
{
	state := get_state(); using state
	ui    := ui_context

	@static pos : Vec2
	style := ui_style_peek( .Default )
	style.text_alignment = { 1.0, 1.0 }
	// style.flags     = { .Size_To_Text  }
	style.padding   = { 10, 10, 10, 10 }
	style.layout.font_size = 32
	ui_style_theme( { styles = { style, style, style, style, }} )

	text := str_intern( "Lorem ipsum dolor sit amet")

	text_box := ui_text("TEXT BOX!", text, flags = { .Mouse_Clickable })
	if text_box.first_frame {
		pos = text_box.style.layout.pos
	}

	if text_box.active {
		pos += mouse_world_delta()
	}

	text_box.style.layout.pos = pos

	text_box.style.size.min = { text_box.computed.text_size.x * 1.5, text_box.computed.text_size.y * 3 }
}

test_whitespace_ast :: proc( default_layout : ^UI_Layout, frame_style_default : ^UI_Style )
{
	profile("Whitespace AST test")
	state := get_state(); using state
	ui    := ui_context

	text_style := frame_style_default ^
	text_style.flags = {
		.Origin_At_Anchor_Center,
		.Fixed_Position_X, .Fixed_Position_Y,
		// .Fixed_Width, .Fixed_Height,
	}
	text_style.text_alignment = { 0.0, 0.5 }
	text_style.alignment = { 0.0, 1.0 }
	text_style.size.min = { 1600, 30 }

	text_theme := UI_StyleTheme { styles = {
		text_style,
		text_style,
		text_style,
		text_style,
	}}
	text_theme.default.bg_color  = Color_Transparent
	text_theme.disabled.bg_color = Color_Frame_Disabled
	text_theme.hot.bg_color      = Color_Frame_Hover
	text_theme.active.bg_color   = Color_Frame_Select
	ui_style_theme( text_theme )

	layout_text := text_style.layout


	alloc_error : AllocatorError; success : bool
	// debug.lorem_content, success = os.read_entire_file( debug.path_lorem, frame_allocator() )

	// debug.lorem_parse, alloc_error = pws_parser_parse( transmute(string) debug.lorem_content, frame_slab_allocator() )
	// verify( alloc_error == .None, "Faield to parse due to allocation failure" )

	text_space := str_intern( " " )
	text_tab   := str_intern( "\t")

	// index := 0
	widgets : Array(UI_Widget)
	// widgets, alloc_error = array_init_reserve( UI_Widget, frame_slab_allocator(), 8 )
	widgets, alloc_error = array_init_reserve( UI_Widget, frame_slab_allocator(), 4 * Kilobyte )
	widgets_ptr := & widgets

	label_id := 0

	line_id := 0
	for line in array_to_slice_num( debug.lorem_parse.lines )
	{
		if line_id == 0 {
			line_id += 1
			continue
		}

		ui_style_theme_set_layout( layout_text )
		line_hbox := ui_widget(str_fmt_alloc( "line %v", line_id ), {.Mouse_Clickable})

		if line_hbox.key == ui.hot
		{
			line_hbox.text = StrRunesPair {}
			ui_parent(line_hbox)

			chunk_layout := layout_text
			chunk_layout.alignment = { 0.0, 1.0 }
			chunk_layout.anchor = range2({ 0.0, 0 }, { 0.0, 0 })
			chunk_layout.pos = {}

			chunk_style := text_style
			chunk_style.flags = { .Fixed_Position_X, .Size_To_Text }
			chunk_style.layout = chunk_layout

			chunk_theme := UI_StyleTheme { styles = {
				chunk_style,
				chunk_style,
				chunk_style,
				chunk_style,
			}}
			ui_style_theme( chunk_theme )

			head := line.first
			for ; head != nil;
			{
				ui_style_theme_set_layout( chunk_layout )
				widget : UI_Widget

				#partial switch head.type
				{
					case .Visible:
						label := str_intern( str_fmt_alloc( "%v %v", head.content.str, label_id ))
						widget = ui_text( label.str, head.content )
						label_id += 1

						chunk_layout.pos.x += size_range2( widget.computed.bounds ).x

					case .Spaces:
						label := str_intern( str_fmt_alloc( "%v %v", "space", label_id ))
						widget = ui_text_spaces( label.str )
						label_id += 1

						for idx in 1 ..< len( head.content.runes )
						{
							// TODO(Ed): VIRTUAL WHITESPACE
							// widget.style.layout.size.x += range2_size( widget.computed.bounds )
						}
						chunk_layout.pos.x += size_range2( widget.computed.bounds ).x

					case .Tabs:
						label := str_intern( str_fmt_alloc( "%v %v", "tab", label_id ))
						widget = ui_text_tabs( label.str )
						label_id += 1

						for idx in 1 ..< len( head.content.runes )
						{
							// widget.style.layout.size.x += range2_size( widget.computed.bounds )
						}
						chunk_layout.pos.x += size_range2( widget.computed.bounds ).x
				}

				array_append( widgets_ptr, widget )
				head = head.next
			}

			line_hbox.style.size.min.x = chunk_layout.pos.x
		}
		else
		{
			builder_backing : [16 * Kilobyte] byte
			builder         := str.builder_from_bytes( builder_backing[:] )

			line_hbox.style.flags |= { .Size_To_Text }

			head := line.first.next
			for ; head != nil;
			{
				str.write_string( & builder, head.content.str )
				head = head.next
			}

			line_hbox.text = str_intern( to_string( builder ) )
			// if len(line_hbox.text.str) == 0 {
			// 	line_hbox.text = str_intern( " " )
			// }
		}

		if len(line_hbox.text.str) > 0 {
			array_append( widgets_ptr, line_hbox )
			layout_text.pos.x  = text_style.layout.pos.x
			layout_text.pos.y += size_range2(line_hbox.computed.bounds).y
		}
		else {
			layout_text.pos.y += size_range2( (& widgets.data[ widgets.num - 1 ]).computed.bounds ).y
		}

		line_id += 1
	}

	label_id += 1 // Dummy action
}
