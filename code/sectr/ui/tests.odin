package sectr

import "core:math/linalg"
import str "core:strings"

test_hover_n_click :: proc()
{
	state := get_state(); using state

	first_btn := ui_button( "FIRST BOX!" )
	first_btn.layout.size.min = {1000, 1000}
	if first_btn.left_clicked || debug.frame_2_created {
		debug.frame_2_created = true

		second_layout := first_btn.layout
		second_layout.pos = { 250, 0 }
		ui_layout( second_layout )

		second_box := ui_button( "SECOND BOX!")
	}
}

test_draggable :: proc()
{
	state := get_state(); using state
	ui    := ui_context

	draggable_layout := UI_Layout {
		flags = {
			.Fixed_Position_X, .Fixed_Position_Y,
			.Fixed_Width, .Fixed_Height,
			.Origin_At_Anchor_Center,
		},
		// alignment = { 0.0, 0.5 },
		alignment      = { 0.5, 0 },
		text_alignment = { 0.0, 0.0 },
		// alignment = { 1.0, 1.0 },
		pos       = { 0, 0 },
		size      = range2({ 200, 200 }, {}),
	}
	scope( draggable_layout )
	scope( UI_Style {
		corner_radii = { 0.3, 0.3, 0.3, 0.3 },
	})

	draggable := ui_widget( "Draggable Box!", UI_BoxFlags { .Mouse_Clickable } )
	if draggable.first_frame {
		debug.draggable_box_pos  = draggable.layout.pos + { 0, -100 }
		debug.draggable_box_size = draggable.layout.size.min
	}

	// Dragging
	if draggable.active {
		debug.draggable_box_pos += mouse_world_delta()
	}

	if (ui.hot == draggable.key) {
		draggable.style.bg_color = Color_Blue
	}

	draggable.layout.pos  = debug.draggable_box_pos
	draggable.layout.size.min = debug.draggable_box_size

	draggable.text       = str_intern_fmt("%v", debug.draggable_box_pos)
	// draggable.text.runes = to_runes(draggable.text)
}

test_parenting :: proc( default_layout : ^UI_Layout, frame_style_default : ^UI_Style )
{
	state := get_state(); using state
	ui    := ui_context

	// frame := ui_widget( "Frame", {} )
	// ui_parent(frame)
	parent_layout := default_layout ^
	parent_layout.size      = range2( { 300, 300 }, {} )
	parent_layout.alignment = { 0.0, 0.0 }
	// parent_layout.margins   = { 100, 100, 100, 100 }
	// parent_layout.padding   = { 5, 10, 5, 5 }
	parent_layout.pos       = { 0, 0 }
	parent_layout.flags = {
		.Fixed_Position_X, .Fixed_Position_Y,
		.Fixed_Width, .Fixed_Height,
		.Origin_At_Anchor_Center
	}
	scope(parent_layout)

	parent_style := frame_style_default ^
	scope(parent_style)

	parent :=	ui_widget( "Parent", { .Mouse_Clickable })
	ui_parent_push(parent)
	{
		if parent.first_frame {
			debug.draggable_box_pos  = parent.layout.pos
			debug.draggable_box_size = parent.layout.size.min
		}
		if parent.active {
			debug.draggable_box_pos += mouse_world_delta()
		}
		if (ui.hot == parent.key) {
			parent.style.bg_color = Color_Blue
		}
		parent.layout.pos      = debug.draggable_box_pos
		parent.layout.size.min = debug.draggable_box_size
	}
	ui_resizable_handles( & parent, & debug.draggable_box_pos, & debug.draggable_box_size)

	child_layout := default_layout ^
	child_layout.size      = range2({ 100, 100 }, { 0, 0 })
	child_layout.alignment = { 0.0, 0.0 }
	// child_layout.margins   = { 20, 20, 20, 20 }
	child_layout.padding   = { 5, 5, 5, 5 }
	// child_layout.anchor    = range2({ 0.2, 0.1 }, { 0.1, 0.15 })
	child_layout.pos       = { 0, 0 }
	child_layout.flags = {
		.Fixed_Width, .Fixed_Height,
		// .Origin_At_Anchor_Center
	}

	child_style := frame_style_default ^
	child_style.bg_color = Color_GreyRed
	scope(child_layout, child_style)
	child := ui_widget( "Child", { .Mouse_Clickable })
	ui_parent_pop()
}

test_text_box :: proc()
{
	state := get_state(); using state
	ui    := ui_context

	@static pos : Vec2
	layout := ui_layout_peek().default
	layout.text_alignment = { 0.0, 0.0 }
	// style.flags     = { .Size_To_Text  }
	layout.padding   = { 10, 10, 10, 10 }
	layout.font_size = 16
	ui_layout( layout)

	text := str_intern( "Lorem ipsum dolor sit amet")

	text_box := ui_text("TEXT BOX!", text, flags = { .Mouse_Clickable })
	if text_box.first_frame {
		pos = text_box.layout.pos
	}

	if text_box.active {
		pos += mouse_world_delta()
	}

	text_box.layout.pos = pos
	text_box.layout.size.min = { text_box.computed.text_size.x * 1.5, text_box.computed.text_size.y * 3 }
}

test_whitespace_ast :: proc( default_layout : ^UI_Layout, frame_style_default : ^UI_Style )
{
	profile("Whitespace AST test")
	state := get_state(); using state
	ui    := ui_context

	text_layout := default_layout^
	text_layout.flags = {
		// .Origin_At_Anchor_Center,
		.Fixed_Position_X, .Fixed_Position_Y,
		// .Fixed_Width,      .Fixed_Height,
	}
	// text_layout.font_size = 16
	text_layout.text_alignment = { 0.0, 0.5 }
	text_layout.alignment      = { 0.0, 1.0 }
	text_layout.size.min       = { 1600, 14 }
	text_style := frame_style_default ^
	// text_style.text_color = Color_Black
	text_style_combo := to_ui_style_combo(text_style)
	text_style_combo.default.bg_color  = Color_Transparent
	text_style_combo.disabled.bg_color = Color_Transparent
	text_style_combo.hot.bg_color      = Color_Transparent
	text_style_combo.active.bg_color   = Color_Transparent
	scope( text_layout, text_style )

	alloc_error : AllocatorError; success : bool
	// debug.lorem_content, success = os.read_entire_file( debug.path_lorem, frame_allocator() )

	// debug.lorem_parse, alloc_error = pws_parser_parse( transmute(string) debug.lorem_content, frame_slab_allocator() )
	// verify( alloc_error == .None, "Faield to parse due to allocation failure" )

	text_space := str_intern( " " )
	text_tab   := str_intern( "\t")

	// index := 0
	widgets : Array(UI_Widget)
	// widgets, alloc_error = array_init_reserve( UI_Widget, frame_slab_allocator(), 8 )
	widgets, alloc_error = make( Array(UI_Widget), 64 * Kilobyte )
	widgets_ptr := & widgets

	label_id := 0

	builder : StringBuilder
	str.builder_init_len_cap( & builder, len = 0, cap = 64 * Kilobyte )

	line_id := 0
	for line in array_to_slice( debug.lorem_parse.lines )
	{
		if line_id == 0 {
			line_id += 1
			continue
		}
		profile("line")

		ui_layout( text_layout )

		// profile_begin("label fmt")
		str.builder_reset( & builder)
		label := str_fmt_builder( & builder, "line %d", line_id )
		// profile_end()

		line_hbox := ui_widget(label, {.Mouse_Clickable})

		if false && line_hbox.key == ui.hot
		{
			line_hbox.text = StrCached {}
			ui_parent(line_hbox)

			chunk_layout          := text_layout
			chunk_layout.alignment = { 0.0, 0.0 }
			chunk_layout.anchor    = range2({ 0.0, 0.0 }, { 0.0, 0.0 })
			chunk_layout.pos       = {}
			chunk_layout.flags     = { .Fixed_Position_X, .Size_To_Text }

			chunk_style := text_style
			scope( chunk_layout, chunk_style )

			head := line.first
			for ; head != nil;
			{
				ui_layout( chunk_layout )
				widget : UI_Widget

				#partial switch head.type
				{
					case .Visible:
						label := str_fmt( "%v %v", head.content, label_id )
						widget = ui_text( label, head.content )
						label_id += 1

						chunk_layout.pos.x += size_range2( widget.computed.bounds ).x

					case .Spaces:
						label := str_fmt( "%v %v", "space", label_id )
						widget = ui_text_spaces( label )
						label_id += 1

						// for idx in 1 ..< len( head.content.runes )
						// {
							// TODO(Ed): VIRTUAL WHITESPACE
							// widget.style.layout.size.x += range2_size( widget.computed.bounds )
						// }
						chunk_layout.pos.x += size_range2( widget.computed.bounds ).x

					case .Tabs:
						label := str_fmt( "%v %v", "tab", label_id )
						widget = ui_text_tabs( label )
						label_id += 1

						// for idx in 1 ..< len( head.content.runes )
						// {
							// TODO(Ed): VIRTUAL WHITESPACE
							// widget.style.layout.size.x += range2_size( widget.computed.bounds )
						// }
						chunk_layout.pos.x += size_range2( widget.computed.bounds ).x
				}

				array_append( widgets_ptr, widget )
				head = head.next
			}

			line_hbox.layout.size.min.x = chunk_layout.pos.x
		}
		else
		{
			// profile("line (single-box)")

			line_hbox.layout.flags |= { .Size_To_Text }

			str.builder_reset( & builder)
			head := line.first.next
			for ; head != nil;
			{
				// profile("write ast node")
				str.write_string( & builder, head.content )
				head = head.next
			}

			// profile("intern")
			line_hbox.text = str_intern( to_string( builder ) )
		}

		if len(line_hbox.text) > 0 {
			// profile("append actual")
			array_append( widgets_ptr, line_hbox )
			text_layout.pos.x  = text_layout.pos.x
			text_layout.pos.y -= size_range2(line_hbox.computed.bounds).y
		}
		else {
			// profile("end")
			widget := & widgets.data[ widgets.num - 1 ]
			if widget.box != nil {
				text_layout.pos.y -= size_range2( widget.computed.bounds ).y
			}
		}

		line_id += 1
	}

	label_id += 1 // Dummy action
}
