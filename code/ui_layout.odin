package sectr

import "core:math"
import "core:math/linalg"

ui_compute_layout :: proc()
{
	profile(#procedure)
	state := get_state()

	root := state.project.workspace.ui.root
	{
		computed := & root.computed
		style    := root.style
		layout   := & style.layout
		computed.bounds.min = layout.pos
		computed.bounds.max = layout.size.min
		computed.content    = computed.bounds
	}

	current := root.first
	for ; current != nil;
	{
		profile("Layout Box")
		style  := current.style

		// These are used to choose via multiplication weather to apply
		// position & size constraints of the parent.
		// The parent's unadjusted content bounds however are enforced for position,
		// they cannot be ignored. The user may bypass them by doing the
		// relative offset math vs world/screen space if they desire.
		fixed_pos_x  : f32 = cast(f32) int(.Fixed_Position_X in style.flags)
		fixed_pos_y  : f32 = cast(f32) int(.Fixed_Position_Y in style.flags)
		fixed_width  : f32 = cast(f32) int(.Fixed_Width      in style.flags)
		fixed_height : f32 = cast(f32) int(.Fixed_Height     in style.flags)

		size_to_text : bool = .Size_To_Text in style.flags

		parent         := current.parent
		computed       := & current.computed

		parent_content      := parent.computed.content
		parent_content_size := parent_content.max - parent_content.min
		parent_center       := parent_content.min + parent_content_size * 0.5

		layout := & style.layout

		/*
		If fixed position (X or Y):
		* Ignore Margins
		* Ignore Anchors

		If clampped position (X or Y):
		* Positon cannot exceed the anchors/margins bounds.

		If fixed size (X or Y):
		* Ignore Parent constraints (can only be clipped)

		If auto-sized:
		* Enforce parent size constraint of bounds relative to
			where the adjusted content bounds are after applying margins & anchors.
			The 'side' conflicting with the bounds will end at that bound side instead of clipping.

		If size.min is not 0:
		* Ignore parent constraints if the bounds go below that value.

		If size.max is 0:
		* Allow the child box to spread to entire adjusted content bounds, otherwise clampped to max size.
		*/

		// 1. Anchors
		anchor := & layout.anchor
		// anchored_pos  := parent_content.min + parent_content_size * anchor.min
		// anchored_size := parent_content_size * linalg.abs( anchor.p1 - anchor.p0 )
		anchored_bounds := range2(
			{
				parent_content.min.x + parent_content_size.x * anchor.min.x,
				parent_content.min.y + parent_content_size.y * anchor.min.y,
			},
			{
				parent_content.max.x - parent_content_size.x * anchor.max.x,
				parent_content.max.y - parent_content_size.y * anchor.max.y,
			}
		)
		anchored_bounds_origin := (anchored_bounds.min + anchored_bounds.max) * 0.5

		// 2. Apply Margins
		margins := range2(
			{ layout.margins.left,  layout.margins.bottom },
			{ layout.margins.right, layout.margins.top },
		)
		margined_bounds := range2(
			anchored_bounds.min + margins.min,
			anchored_bounds.max - margins.max,
		)
		margined_bounds_origin := (margined_bounds.min + margined_bounds.max) * 0.5
		margined_size          :=  margined_bounds.max - margined_bounds.min

		// 3. Enforce Min/Max Size Constraints
		adjusted_max_size_x := layout.size.max.x > 0 ? min( margined_size.x, layout.size.max.x ) : margined_size.x
		adjusted_max_size_y := layout.size.max.y > 0 ? min( margined_size.y, layout.size.max.y ) : margined_size.y

		adjusted_size : Vec2
		adjusted_size.x = max( adjusted_max_size_x, layout.size.min.x)
		adjusted_size.y = max( adjusted_max_size_y, layout.size.min.y)

		if .Fixed_Width in style.flags {
			adjusted_size.x = layout.size.min.x
		}
		if .Fixed_Height in style.flags {
			adjusted_size.y = layout.size.min.y
		}

		text_size : Vec2
		// If the computed matches, we already have the size, don't bother.
		if current.first_frame || ! size_to_text || computed.text_size.y != size_range2(computed.bounds).y {
			text_size = cast(Vec2) measure_text_size( current.text.str, style.font, style.font_size, 0 )
		}
		else {
			text_size = computed.text_size
		}

		// 4. Adjust Alignment of pivot position
		alignment := layout.alignment
		alignment_offset := Vec2 {
			// adjusted_size.x * (alignment.x - 0.5),
			// adjusted_size.y * (alignment.y - 0.5),
		}

		// 5. Determine relative position

		// TODO(Ed): Let the user determine the coordinate space origin?
		// rel_pos := margined_bounds_origin + alignment_offset + layout.pos
		rel_pos := margined_bounds_origin + layout.pos

		if .Fixed_Position_X in style.flags {
			rel_pos.x = parent_center.x + layout.pos.x
		}
		if .Fixed_Position_Y in style.flags {
			rel_pos.y = parent_center.y + layout.pos.y
		}

		vec2_one := Vec2 { 1, 1 }

		// Determine the box bounds
		bounds := range2(
			rel_pos - adjusted_size * alignment,
			rel_pos + adjusted_size * (vec2_one - alignment),
		)

		// Determine Padding's outer bounds
		border_offset := Vec2	{ layout.border_width, layout.border_width }

		padding_bounds := range2(
			bounds.min + border_offset,
			bounds.min - border_offset,
		)

		// Determine Content Bounds
		content_bounds := range2(
			bounds.min + { layout.padding.left,  layout.padding.bottom },
			bounds.max - { layout.padding.right, layout.padding.top },
		)

		computed.anchors = anchored_bounds
		computed.margins = margined_bounds
		computed.bounds  = bounds
		computed.padding = padding_bounds
		computed.content = content_bounds

		// TODO(Ed): Needs a rework based on changes to rest of layout above being changed
		// Text 
		if len(current.text.str) > 0
		{
			bottom_left := content_bounds.min
			top_right   := content_bounds.max

			content_size := Vec2 { top_right.x - bottom_left.x, top_right.y - bottom_left.y }
			text_pos : Vec2
			text_pos = top_right
			text_pos.x += (-content_size.x - text_size.x) * layout.text_alignment.x
			text_pos.y += (-content_size.y + text_size.y) * layout.text_alignment.y

			computed.text_size = text_size
			computed.text_pos  = { text_pos.x, -text_pos.y }
		}

		current = ui_box_tranverse_next( current )
	}
}
