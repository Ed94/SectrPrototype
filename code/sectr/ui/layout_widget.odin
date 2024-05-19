package sectr

import "base:runtime"

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
	container_height := container.computed.content.max.y - container.computed.content.min.y

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := container.first; child != nil; child = child.next
	{
		using child.layout
		scaled_width_by_height : b32 = b32(.Scale_Width_By_Height_Ratio in flags)
		if .Scale_Width_By_Height_Ratio in flags
		{
			size_req_children += size.min.x * container_height
			continue
		}
		if .Fixed_Width in flags
		{
			size_req_children += size.min.x
			continue
		}

		total_stretch_ratio += anchor.ratio.x
	}

	avail_flex_space := container_width - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space, container_height : f32 ) -> (space_allocated : f32)
	{
		using child.layout
		if .Scale_Width_By_Height_Ratio in flags {
			size.min.y      = container_height
			space_allocated = size.min.x * container_height
		}
		else if ! (.Fixed_Width in flags) {
			size.min.x      = anchor.ratio.x * (1 / total_stretch_ratio) * avail_flex_space
			space_allocated = size.min.x
		}
		else {
			space_allocated = size.min.x
		}
		space_allocated -= child.layout.margins.left - child.layout.margins.right
		size.min.x      -= child.layout.margins.left - child.layout.margins.right
		flags |= {.Fixed_Width}
		return
	}

	space_used : f32 = 0.0
	switch direction{
		case .Right_To_Left:
			for child := container.last; child != nil; child = child.prev {
				using child.layout
				child_width := allocate_space(child, total_stretch_ratio, avail_flex_space, container_height)
				anchor       = range2({0, 0}, {0, 0})
				width : f32
				pos.x        = space_used
				space_used  += child_width + child.layout.margins.left + child.layout.margins.right
			}
		case .Left_To_Right:
			for child := container.first; child != nil; child = child.next {
				using child.layout
				child_width := allocate_space(child, total_stretch_ratio, avail_flex_space, container_height)
				anchor       = range2({0, 0}, {0, 0})
				width : f32
				pos.x        = space_used
				space_used  += child_width + child.layout.margins.left + child.layout.margins.right
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
			size.min.y = (anchor.ratio.y * (1 / total_stretch_ratio) * avail_flex_space)
		}
		flags |= {.Fixed_Height}
	}

	space_used : f32 = 0.0
	switch direction
	{
		case .Bottom_To_Top:
			for child := container.last; child != nil; child = child.prev {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0,0}, {0, 0})
				pos.y       = -space_used
				space_used += size.min.y + child.layout.margins.top + child.layout.margins.bottom
				size.min.x  = container.computed.content.max.x + container.computed.content.min.x
			}
		case .Top_To_Bottom:
			for child := container.first; child != nil; child = child.next {
				allocate_space(child, total_stretch_ratio, avail_flex_space)
				using child.layout
				anchor      = range2({0, 0}, {0, 0})
				pos.y       = -space_used
				space_used += size.min.y + child.layout.margins.top + child.layout.margins.bottom
				size.min.x  = container.computed.content.max.x - container.computed.content.min.x
			}
	}
}
