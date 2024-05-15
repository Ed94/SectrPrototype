package sectr

/*
Widget Layout Ops
*/

ui_layout_children_horizontally :: proc( container : ^UI_Box, direction : UI_LayoutDirectionX, width_ref : ^f32 )
{
	container_width : f32
	if width_ref != nil {
		container_width = width_ref ^
	}
	else {
		container_width = container.computed.content.max.x - container.computed.content.min.x
	}

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := container.first; child != nil; child = child.next
	{
		using child.layout
		scaled_width_by_height : b32 = b32(.Scale_Width_By_Height_Ratio in flags)
		if .Fixed_Width in flags
		{
			if scaled_width_by_height {
				height := size.max.y != 0 ? size.max.y : container_width
				width  := height * size.min.x

				size_req_children += width
				continue
			}

			size_req_children += size.min.x
			continue
		}

		total_stretch_ratio += anchor.ratio.x
	}

	avail_flex_space := container_width - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space : f32 )
	{
		using child.layout
		if ! (.Fixed_Width in flags) {
			size.min.x = anchor.ratio.x * (1 / total_stretch_ratio) * avail_flex_space
		}
		flags    |= {.Fixed_Width}
	}

	space_used : f32 = 0.0
	switch direction{
		case .Right_To_Left:
			for child := container.last; child != nil; child = child.prev {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 0})
				// alignment   = { 0, 0 }// - hbox.layout.alignment
				pos.x       = space_used
				space_used += size.min.x
				// size.min.y  = container.computed.content.max.y - container.computed.content.min.y
			}
		case .Left_To_Right:
			for child := container.first; child != nil; child = child.next {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 0})
				// alignment   = { 0, 0 }
				pos.x       = space_used
				space_used += size.min.x
				// size.min.y  = container.computed.content.max.y - container.computed.content.min.y
			}
	}
}

ui_layout_children_vertically :: proc( container : ^UI_Box, direction : UI_LayoutDirectionY, height_ref : ^f32 )
{
	container_height : f32
	if height_ref != nil {
		container_height = height_ref ^
	}
	else {
		container_height = container.computed.content.max.y - container.computed.content.min.y
	}

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := container.first; child != nil; child = child.next
	{
		using child.layout
		scaled_width_by_height : b32 = b32(.Scale_Width_By_Height_Ratio in flags)
		if .Fixed_Height in flags
		{
			if scaled_width_by_height {
				width  := size.max.x != 0 ? size.max.x : container_height
				height := width * size.min.y

				size_req_children += height
				continue
			}

			size_req_children += size.min.y
			continue
		}

		total_stretch_ratio += anchor.ratio.y
	}

	avail_flex_space := container_height - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space : f32 )
	{
		using child.layout
		if ! (.Fixed_Height in flags) {
			size.min.y = anchor.ratio.y * (1 / total_stretch_ratio) * avail_flex_space
		}
		flags |= {.Fixed_Height}
	}

	space_used : f32 = 0.0
	switch direction {
		case .Bottom_To_Top:
			for child := container.last; child != nil; child = child.prev {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 0})
				// alignment   = {0, 0}
				pos.y       = -space_used
				space_used += size.min.y
				size.min.x  = container.computed.content.max.x + container.computed.content.min.x
			}
		case .Top_To_Bottom:
			for child := container.first; child != nil; child = child.next {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 0})
				// alignment   = {0, 0}
				pos.y       = -space_used
				space_used += size.min.y
				size.min.x  = container.computed.content.max.x - container.computed.content.min.x
			}
	}
}
