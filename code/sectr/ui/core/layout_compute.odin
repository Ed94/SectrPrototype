package sectr

ui_box_compute_layout :: proc( box : ^UI_Box,
	dont_mark_fresh           : b32 = false,
	ancestors_layout_required : b32 = false,
	root_layout_required      : b32 = false )
{
	profile("Layout Box")
	state := get_state()
	ui    := state.ui_context
	using box

	size_to_text : bool = .Size_To_Text in layout.flags

	parent_content      := parent.computed.content
	parent_content_size := parent_content.max - parent_content.min
	parent_center       := parent_content.min + parent_content_size * 0.5

	/*
	If fixed position (X or Y):
	* Ignore Margins
	* Ignore Anchors

	If clampped position (X or Y):
	* Positon cannot exceed the anchors/margins bounds.

	If fixed size (X or Y):
	* Ignore Parent constraints (can only be clipped)

	If an axis is auto-sized by a ratio of the other axis
	* Using the referenced axis, set the size of the ratio'd axis by that ratio.

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
	anchored_bounds := range2(
		parent_content.min + parent_content_size * anchor.min,
		parent_content.max - parent_content_size * anchor.max,
	)
	// anchored_bounds_origin := (anchored_bounds.min + anchored_bounds.max) * 0.5

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

	text_size : Vec2
	if len(box.text.str) > 0
	{
		text_size = computed.text_shape.size
		// if layout.font_size == computed.text_size.y {
		// 	text_size = computed.text_size
		// }
		// else {
		// 	text_size = cast(Vec2) measure_text_size( box.text.str, style.font, layout.font_size, 0 )
		// }
	}

	if size_to_text {
		adjusted_size = text_size
	}

	if .Scale_Width_By_Height_Ratio in layout.flags {
		adjusted_size.x = adjusted_size.y * layout.size.min.x
	}
	else if .Fixed_Width in layout.flags {
		adjusted_size.x = layout.size.min.x
	}

	if .Scale_Height_By_Width_Ratio in layout.flags {
		adjusted_size.y = adjusted_size.x * layout.size.min.y
	}
	else if .Fixed_Height in layout.flags {
		adjusted_size.y = layout.size.min.y
	}

	border_offset := Vec2	{ layout.border_width, layout.border_width }

	// TODO(Ed): These are still WIP
	if .Size_To_Content_XY in layout.flags {
		// Preemtively traverse the children of this parent and have them compute their layout.
		// This parent will just set its size to the max bounding area of those children.
		// This will recursively occur if child also depends on their content size from their children, etc.
		// ui_box_compute_layout_children(box)
		children_bounds := ui_compute_children_overall_bounds(box)
		resolved_bounds := range2(
			children_bounds.min - { layout.padding.left,  layout.padding.bottom } - border_offset,
			children_bounds.max + { layout.padding.right, layout.padding.top }    + border_offset,
		)
		adjusted_size = size_range2( resolved_bounds )
	}
	if .Size_To_Content_X in layout.flags {
		children_bounds := ui_compute_children_overall_bounds(box)
		resolved_bounds := range2(
			children_bounds.min - { layout.padding.left,  layout.padding.bottom } - border_offset,
			children_bounds.max + { layout.padding.right, layout.padding.top }    + border_offset,
		)
		adjusted_size.x = size_range2( resolved_bounds ).x
	}
	if .Size_To_Content_Y in layout.flags {
		children_bounds := ui_compute_children_overall_bounds(box)
		// resolved_bounds := range2(
		// 	children_bounds.min - { layout.padding.left,  layout.padding.bottom } - border_offset,
		// 	children_bounds.max + { layout.padding.right, layout.padding.top }    + border_offset,
		// )
		adjusted_size.y = size_range2(children_bounds).y
	}

	// 5. Determine relative position

	origin_center      := margined_bounds_origin
	origin_top_left    := Vec2 { margined_bounds.min.x, margined_bounds.max.y }
	origin_bottom_left := Vec2 { margined_bounds.min.x, margined_bounds.min.y }

	origin  := .Origin_At_Anchor_Center in layout.flags ? origin_center : origin_bottom_left
	rel_pos := origin + layout.pos

	if .Fixed_Position_X in layout.flags {
		rel_pos.x = origin.x + layout.pos.x
	}
	if .Fixed_Position_Y in layout.flags {
		rel_pos.y = origin.y + layout.pos.y
	}

	vec2_one := Vec2 { 1, 1 }

	// 6. Determine the box bounds
	// Adjust Alignment of pivot position
	alignment := layout.alignment
	bounds    : Range2
	if ! (.Origin_At_Anchor_Center in layout.flags) {
		// alignment *= -1 // Inversing so that it goes toward top-right.
		bounds = range2(
			rel_pos - adjusted_size * alignment             ,
			rel_pos + adjusted_size * (vec2_one - alignment),
		)
	}
	else {
		centered_convention_offset := adjusted_size * -0.5
		bounds = range2(
			(rel_pos + centered_convention_offset) - adjusted_size * -alignment            ,
			(rel_pos + centered_convention_offset) + adjusted_size * (alignment + vec2_one),
		)
	}

	// 7. Padding & Content
	// Determine Padding's outer bounds
	padding_bounds := range2(
		bounds.min + border_offset,
		bounds.min - border_offset,
	)

	// Determine Content Bounds
	content_bounds := range2(
		bounds.min + { layout.padding.left,  layout.padding.bottom } + border_offset,
		bounds.max - { layout.padding.right, layout.padding.top }    - border_offset,
	)

	computed.bounds  = bounds
	computed.padding = padding_bounds
	computed.content = content_bounds

	// 8. Text position & size
	if len(box.text.str) > 0
	{
		ascent, descent, line_gap := get_font_vertical_metrics(style.font, layout.font_size)

		// offset := text_size
		// offset += { 0, -descent }

		content_size := content_bounds.max - content_bounds.min
		text_pos : Vec2
		text_pos  = content_bounds.min
		text_pos += (content_size - text_size) * layout.text_alignment
		text_pos += { 0, -descent }

		computed.text_size = text_size
		computed.text_pos  = text_pos
	}
	computed.fresh = true && !dont_mark_fresh

	if .Order_Children_Left_To_Right in layout.flags {
		ui_layout_children_horizontally( box, .Left_To_Right )
	}
	else if .Order_Children_Right_To_Left in layout.flags {
		ui_layout_children_horizontally( box, .Right_To_Left )
	}
	else if .Order_Children_Top_To_Bottom in layout.flags {
		ui_layout_children_vertically( box, .Top_To_Bottom )
	}
	else if .Order_Children_Bottom_To_Top in layout.flags {
		ui_layout_children_vertically( box, .Bottom_To_Top )
	}

	if computed.fresh {
		ui_collision_register( box )
	}
}

ui_compute_children_overall_bounds :: proc ( box : ^UI_Box ) -> ( children_bounds : Range2 )
{
	// for current := box.first; current != nil && current.prev != box; current = ui_box_tranverse_next_depth_first( current, parent_limit = box )
		for current := ui_box_tranverse_next_depth_first( box,     parent_limit = box, bypass_intersection_test = false ); current != nil; 
				current  = ui_box_tranverse_next_depth_first( current, parent_limit = box, bypass_intersection_test = false )
	{
		if current == box do return
		if ! current.computed.fresh do  ui_box_compute_layout( current )
		if current == box.first {
			children_bounds = current.computed.bounds
			continue
		}
		children_bounds = join_range2( current.computed.bounds, children_bounds )
	}
	return
}

ui_box_compute_layout_children :: proc( box : ^UI_Box )
{
	// for current := box.first; current != nil && current.prev != box; current = ui_box_tranverse_next_depth_first( current, parent_limit = box )
	// for current := box.first; current != nil && current.prev != box; current = ui_box_traverse_next_breadth_first( current )
	for current := ui_box_tranverse_next_depth_first( box,     parent_limit = box, bypass_intersection_test = false ); current != nil; 
			current  = ui_box_tranverse_next_depth_first( current, parent_limit = box, bypass_intersection_test = false )
	{
		if current == box do return
		if current.computed.fresh do continue
		ui_box_compute_layout( current )
	}
}
