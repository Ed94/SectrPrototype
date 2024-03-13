package sectr

ui_compute_layout :: proc()
{
	profile(#procedure)
	state := get_state()

	root := state.project.workspace.ui.root
	{
		computed := & root.computed
		bounds   := & computed.bounds
		style    := root.style
		layout   := & style.layout

		bounds.min = layout.pos
		bounds.max = layout.size

		computed.content = bounds^
		computed.padding = {}
	}

	current := root.first
	for ; current != nil;
	{
		profile("Layout Box")
		parent         := current.parent
		parent_content := parent.computed.content
		computed       := & current.computed

		style  := current.style
		layout := & style.layout

		margins := range2(
			{  layout.margins.left,  -layout.margins.top },
			{ -layout.margins.right,  layout.margins.bottom },
		)

		margined_bounds := range2(
			parent_content.p0 + margins.p0,
			parent_content.p1 + margins.p1,
		)

		margined_size := margined_bounds.p1 - margined_bounds.p0

		anchored_bounds := range2(
			margined_bounds.p0 + margined_size * layout.anchor.p0,
			margined_bounds.p0 + margined_size * layout.anchor.p1,
		)

		anchored_size := Vec2 {
			anchored_bounds.max.x - anchored_bounds.min.x,
			anchored_bounds.max.y - anchored_bounds.min.y,
		}

		anchor := & layout.anchor
		pos    : Vec2
		if UI_StyleFlag.Fixed_Position_X in style.flags {
			pos.x  = layout.pos.x
			pos.x += anchored_bounds.p0.x
		}
		if UI_StyleFlag.Fixed_Position_Y in style.flags {
			pos.y  = layout.pos.y
			pos.y += anchored_bounds.p0.y
		}

		text_size : Vec2
		// If the computed matches, we alreayd have the size, don't bother.
		// if computed.text_size.y == style.font_size {
		if current.first_frame || ! style.size_to_text || computed.text_size.y != size_range2(computed.bounds).y {
			text_size = cast(Vec2) measure_text_size( current.text.str, style.font, style.font_size, 0 )
		}
		else {
			text_size = computed.text_size
		}

		size : Vec2
		if UI_StyleFlag.Fixed_Width in style.flags {
			size.x = layout.size.x
		}
		else {
			size.x = anchored_size.x
		}

		if UI_StyleFlag.Fixed_Height in style.flags {
			size.y = layout.size.y
		}
		else {
			size.y = anchored_size.y
		}

		if style.size_to_text {
			size = text_size
		}

		half_size   := size * 0.5
		size_bounds := range2(
			Vec2 {},
			{ size.x, -size.y },
		)

		aligned_bounds := range2(
			size_bounds.p0 + size * { -layout.alignment.x,  layout.alignment.y },
			size_bounds.p1 - size * {  layout.alignment.x, -layout.alignment.y },
		)

		bounds := & computed.bounds
		(bounds^) = aligned_bounds
		(bounds^) = range2(
			pos + aligned_bounds.p0,
			pos + aligned_bounds.p1,
		)

		border_offset := Vec2 { layout.border_width, layout.border_width }
		padding    := & computed.padding
		(padding^)  = range2(
			bounds.p0 + border_offset,
			bounds.p1 + border_offset,
		)

		content   := & computed.content
		(content^) = range2(
			bounds.p0 + {  layout.padding.left,  -layout.padding.top },
			bounds.p1 + { -layout.padding.right,  layout.padding.bottom },
		)

		// Text
		if len(current.text.str) > 0
		{
			// profile("Text")
			top_left     := content.p0
			bottom_right := content.p1

			content_size := Vec2 { top_left.x - bottom_right.x, top_left.y - bottom_right.y }
			text_pos : Vec2
			text_pos = top_left
			text_pos.x += (-content_size.x - text_size.x) * layout.text_alignment.x
			text_pos.y += (-content_size.y + text_size.y) * layout.text_alignment.y

			computed.text_size = text_size
			computed.text_pos  = { text_pos.x, -text_pos.y }
		}

		current = ui_box_tranverse_next( current )
	}
}
