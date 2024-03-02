package sectr

ui_compute_layout :: proc()
{
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
		parent         := current.parent
		parent_content := parent.computed.content
		computed       := & current.computed

		style  := current.style
		layout := & style.layout

		margins := Range2 { pts = {
			parent_content.p0 + { layout.margins.left,  layout.margins.top },
			parent_content.p1 - { layout.margins.right, layout.margins.bottom },
		}}

		anchor := & layout.anchor
		pos    : Vec2
		if UI_StyleFlag.Fixed_Position_X in style.flags {
			pos.x  = layout.pos.x
			pos.x -= margins.p0.x * anchor.x0
			pos.x += margins.p0.x * anchor.x1
		}
		if UI_StyleFlag.Fixed_Position_Y in style.flags {
			pos.y  = layout.pos.y
			pos.y -= margins.p1.y * anchor.y0
			pos.y += margins.p1.y * anchor.y1
		}

		size : Vec2
		if UI_StyleFlag.Fixed_Width in style.flags {
			size.x = layout.size.x
		}
		else {
			// TODO(Ed) : Not sure what todo here...
		}
		if UI_StyleFlag.Fixed_Height in style.flags {
			size.y = layout.size.y
		}
		else {
			// TODO(Ed) : Not sure what todo here...
		}

		half_size   := size * 0.5
		size_bounds := Range2 { pts = {
			Vec2 {},
			{ size.x, -size.y },
		}}

		aligned_bounds := Range2 { pts = {
			size_bounds.p0 + size * { -layout.alignment.x,  layout.alignment.y },
			size_bounds.p1 - size * {  layout.alignment.x, -layout.alignment.y },
		}}

		bounds := & computed.bounds
		(bounds^) = aligned_bounds
		(bounds^) = { pts = {
			pos + aligned_bounds.p0,
			pos + aligned_bounds.p1,
		}}

		border_offset := Vec2 { layout.border_width, layout.border_width }
		padding    := & computed.padding
		(padding^)  = { pts = {
			bounds.p0 + border_offset,
			bounds.p1 - border_offset,
		}}

		content   := & computed.content
		(content^) = { pts = {
			bounds.p0 + { layout.padding.left,  layout.padding.top },
			bounds.p1 - { layout.padding.right, layout.padding.bottom },
		}}

		current = ui_box_tranverse_next( current )
	}
}
