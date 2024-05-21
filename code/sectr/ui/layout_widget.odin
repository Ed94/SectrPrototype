package sectr

import "base:runtime"
import lalg "core:math/linalg"

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

		size_req_children   += size.min.x
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
			potential_size  := anchor.ratio.x * (1 / total_stretch_ratio) * avail_flex_space
			space_allocated  = lalg.max(potential_size, size.min.x)
			size.min.x       = space_allocated
		}
		else {
			space_allocated = size.min.x
		}
		space_allocated -= margins.left - margins.right
		size.min.x      -= margins.left - margins.right
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
				pos.x        = space_used
				space_used  += child_width + child.layout.margins.left + child.layout.margins.right
			}
		case .Left_To_Right:
			for child := container.first; child != nil; child = child.next {
				using child.layout
				child_width := allocate_space(child, total_stretch_ratio, avail_flex_space, container_height)
				anchor       = range2({0, 0}, {0, 0})
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
	container_width := container.computed.content.max.x - container.computed.content.min.x

	// do layout calculations for the children
	total_stretch_ratio : f32 = 0.0
	size_req_children   : f32 = 0
	for child := container.first; child != nil; child = child.next
	{
		using child.layout
		scaled_height_by_width : b32 = b32(.Scale_Height_By_Width_Ratio in flags)
		if scaled_height_by_width {
			size_req_children += size.min.y * container_width
			continue
		}
		if .Fixed_Height in flags
		{
			size_req_children += size.min.y
			continue
		}

		size_req_children   += size.min.y
		total_stretch_ratio += anchor.ratio.y
	}

	avail_flex_space := container_height - size_req_children

	allocate_space :: proc( child : ^UI_Box, total_stretch_ratio, avail_flex_space, container_width : f32 ) -> (space_allocated : f32)
	{
		using child.layout
		if .Scale_Height_By_Width_Ratio in flags {
			size.min.x      = container_width
			space_allocated = size.min.y * container_width
		}
		if ! (.Fixed_Height in flags) {
			potential_size  := (anchor.ratio.y * (1 / total_stretch_ratio) * avail_flex_space)
			space_allocated  = lalg.max(potential_size, size.min.y)
			size.min.y       = space_allocated
		}
		else {
			space_allocated = size.min.y
		}
		space_allocated -= margins.top - margins.bottom
		size.min.y      -= margins.top - margins.bottom
		flags |= {.Fixed_Height}
		return
	}

	switch direction
	{
		case .Top_To_Bottom:
			space_used : f32 = 0
			for child := container.first; child != nil; child = child.next {
				using child.layout
				child_height := allocate_space(child, total_stretch_ratio, avail_flex_space, container_width)
				anchor      = range2({0, 1}, {0, 0})
				alignment   = {0, 1}
				pos.y       = space_used
				space_used -= child_height - child.layout.margins.top - child.layout.margins.bottom
			}
		case .Bottom_To_Top:
			space_used : f32 = 0
			for child := container.first; child != nil; child = child.next {
				using child.layout
				child_height := allocate_space(child, total_stretch_ratio, avail_flex_space, container_width)
				anchor        = range2({0,0}, {0, 0})
				alignment     = {0, 0}
				pos.y         = space_used
				space_used   += child_height - child.layout.margins.top - child.layout.margins.bottom
			}
	}
}
