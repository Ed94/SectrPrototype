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
		bounds   := & computed.bounds
		style    := root.style
		layout   := & style.layout

		bounds.min = layout.pos
		bounds.max = layout.size.min

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


		margins := range2(
			{  layout.margins.left,  -layout.margins.top },
			{ -layout.margins.right,  layout.margins.bottom },
		)
		margined_bounds := range2(
			parent_content.p0 + margins.p0,
			parent_content.p1 + margins.p1,
		)
		margined_size := linalg.abs(margined_bounds.p1 - margined_bounds.p0)

		anchor := & layout.anchor
		// Margins + Anchors Applied
		adjusted_bounds := range2(
			{  margined_bounds.p0.x + margined_size.x * anchor.p0.x, margined_bounds.p0.y + margined_size.y * anchor.p0.y },
			{  margined_bounds.p1.x + margined_size.x * anchor.p1.x, margined_bounds.p1.y + margined_size.y * anchor.p1.y },
		)
		adjusted_bounds_size := linalg.abs(adjusted_bounds.p1 - adjusted_bounds.p0)

		// Resolves final constrained bounds of the parent for the child box
		// Will be applied to the box after the child's positon is resolved.

		fixed_pos := Vec2 { fixed_pos_x, fixed_pos_y }
		constraint_min := adjusted_bounds.min //* (1 - fixed_pos) + parent_content.min * fixed_pos
		constraint_max := adjusted_bounds.max //* (1 - fixed_pos) + parent_content.max * fixed_pos

		// constraint_min_x := adjusted_bounds.min.x //* (1 - fixed_pos_x) + parent_content.min.x * fixed_pos_x
		// constraint_min_y := adjusted_bounds.min.y //* (1 - fixed_pos_y) + parent_content.min.y * fixed_pos_y
		// constraint_max_x := adjusted_bounds.max.x //* (1 - fixed_pos_x) + parent_content.max.x * fixed_pos_x
		// constraint_max_y := adjusted_bounds.max.y //* (1 - fixed_pos_y) + parent_content.max.y * fixed_pos_y

		constrained_bounds := range2(
			constraint_min,
			constraint_max,
			// { constraint_min_x, constraint_min_y },
			// { constraint_max_x, constraint_max_y },
		)
		constrained_size := linalg.abs(constrained_bounds.p1 - constrained_bounds.p0)


		/*
		If fixed position (X or Y):
		* Ignore Margins
		* Ignore Anchors

		If fixed size (X or Y):
		* Ignore Parent constraints (can only be clipped)

		If auto-sized:
		* Enforce parent size constraint of bounds relative to
			where the adjusted content bounds are after applying margins & anchors.
			The 'side' conflicting with the bounds will end at that bound side instead of clipping.

		If size.min is not 0:
		* Ignore parent constraints if the bounds go below that value.

		If size.max is not 0:
		* Allow the child box to spread to entire adjusted content bounds.
		*/

		size_unit_bounds := range2(
			{  0.0,  0.0 },
			{  1.0, -1.0 },
		)

		alignment := layout.alignment
		aligned_unit_bounds := range2(
			size_unit_bounds.p0 + { -alignment.x,  alignment.y },
			size_unit_bounds.p1 - {  alignment.x, -alignment.y },
		)

		wtf := range2(
			{  constrained_bounds.p0.x,  constrained_bounds.p0.y },
			{  constrained_bounds.p1.x,  constrained_bounds.p1.y },
		)

		// projected_bounds := range2(
		// 	aligned_unit_bounds.p0 * wtf.p0,
		// 	aligned_unit_bounds.p1 * wtf.p1,
		// )


		constrained_half_size := constrained_size * 0.5
		min_half_size         := layout.size.min  * 0.5
		max_half_size         := layout.size.max  * 0.5
		half_size             := linalg.max( constrained_half_size, min_half_size )
		half_size              = linalg.min( half_size, max_half_size )

		projected_bounds := range2(
			aligned_unit_bounds.p0 * half_size,
			aligned_unit_bounds.p1 * half_size,
		)

		rel_projected_bounds := range2(
			layout.pos + projected_bounds.p0,
			layout.pos + projected_bounds.p1,
		)

		bounds : Range2

		// Resolve and apply the size constraint based off of positon of box and the constrained bounds

		// Check to see if left or right side is over
		if ! (.Fixed_Width in style.flags)
		{
			bounds.p0.x = rel_projected_bounds.p0.x < constrained_bounds.p0.x ? constrained_bounds.p0.x : rel_projected_bounds.p0.x
			bounds.p1.x = rel_projected_bounds.p1.x > constrained_bounds.p1.x ? constrained_bounds.p1.x : rel_projected_bounds.p1.x
		}
		else {
			size_unit_bounds := range2(
				{  0.0,  0.0 },
				{  1.0, -1.0 },
			)

			alignment := layout.alignment
			aligned_unit_bounds := range2(
				size_unit_bounds.p0 + { -alignment.x,  alignment.y },
				size_unit_bounds.p1 - {  alignment.x, -alignment.y },
			)

			// Apply size.p0.x directly
			bounds.p0.x = aligned_unit_bounds.p0.x * layout.size.min.x
			bounds.p1.x = aligned_unit_bounds.p1.x * layout.size.min.x

			bounds.p0.x += constrained_bounds.p0.x
			bounds.p1.x += constrained_bounds.p0.x

			bounds.p0.x += layout.pos.x
			bounds.p1.x += layout.pos.x
		}

		if ! (.Fixed_Height in style.flags)
		{
			bounds.p0.y = rel_projected_bounds.p0.y > constrained_bounds.p0.y ? constrained_bounds.p0.y : rel_projected_bounds.p0.y
			bounds.p1.y = rel_projected_bounds.p1.y < constrained_bounds.p1.y ? constrained_bounds.p1.y : rel_projected_bounds.p1.y
		}
		else {
			size_unit_bounds := range2(
				{  0.0,  0.0 },
				{  1.0, -1.0 },
			)

			alignment := layout.alignment
			aligned_unit_bounds := range2(
				size_unit_bounds.p0 + { -alignment.x,  alignment.y },
				size_unit_bounds.p1 - {  alignment.x, -alignment.y },
			)

			// Apply size.p0.y directly
			bounds.p0.y = aligned_unit_bounds.p0.y * layout.size.min.y
			bounds.p1.y = aligned_unit_bounds.p1.y * layout.size.min.y

			bounds.p0.y += constrained_bounds.p0.y //+ aligned_unit_bounds
			bounds.p1.y += constrained_bounds.p0.y //+ aligned_unit_bounds

			bounds.p0.y += layout.pos.y
			bounds.p1.y += layout.pos.y
		}

		// Enforce the min/max size
		bounds_size := bounds.p1 - bounds.p0
		// if bounds_size > layout.size.max {
			// Enforce max


		// }


		text_size : Vec2
		// If the computed matches, we already have the size, don't bother.
		if current.first_frame || ! size_to_text || computed.text_size.y != size_range2(computed.bounds).y {
			text_size = cast(Vec2) measure_text_size( current.text.str, style.font, style.font_size, 0 )
		}
		else {
			text_size = computed.text_size
		}
		if size_to_text {
			// size = text_size
		}


		computed.bounds = bounds

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
