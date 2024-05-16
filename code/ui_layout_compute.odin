package sectr

ui_box_compute_layout :: proc( box : ^UI_Box,
	dont_mark_fresh           : b32 = false,
	ancestors_layout_required : b32 = false,
	root_layout_required      : b32 = false )
{
	// profile("Layout Box")
	state := get_state()
	ui    := state.ui_context

	parent := box.parent

	style  := box.style
	layout := & box.layout

	// These are used to choose via multiplication weather to apply
	// position & size constraints of the parent.
	// The parent's unadjusted content bounds however are enforced for position,
	// they cannot be ignored. The user may bypass them by doing the
	// relative offset math vs world/screen space if they desire.
	// fixed_pos_x  : f32 = cast(f32) int(.Fixed_Position_X in layout.flags)
	// fixed_pos_y  : f32 = cast(f32) int(.Fixed_Position_Y in layout.flags)
	// fixed_width  : f32 = cast(f32) int(.Fixed_Width      in layout.flags)
	// fixed_height : f32 = cast(f32) int(.Fixed_Height     in layout.flags)

	size_to_text : bool = .Size_To_Text in layout.flags

	computed := & box.computed

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
	if layout.font_size == computed.text_size.y {
		text_size = computed.text_size
	}
	else {
		text_size = cast(Vec2) measure_text_size( box.text.str, style.font, layout.font_size, 0 )
	}

	if size_to_text {
		adjusted_size = text_size
	}

	if .Size_To_Content in layout.flags {
		// Preemtively traverse the children of this parent and have them compute their layout.
		// This parent will just set its size to the max bounding area of those children.
		// This will recursively occur if child also depends on their content size from their children, etc.
		ui_box_compute_layout_children(box)
		//ui_compute_children_bounding_area(box)
	}

	// TODO(Ed): Should this force override all of the previous auto-sizing possible?
	if .Fixed_Width in layout.flags {
		adjusted_size.x = layout.size.min.x
	}
	if .Fixed_Height in layout.flags {
		adjusted_size.y = layout.size.min.y
	}

	// 5. Determine relative position

	origin_center   := margined_bounds_origin
	origin_top_left := Vec2 { margined_bounds.min.x, margined_bounds.max.y }

	origin := .Origin_At_Anchor_Center in layout.flags ? origin_center : origin_top_left

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
	bounds : Range2

	if ! (.Origin_At_Anchor_Center in layout.flags) {
		// The convention offset adjust the box so that the top-left point is at the top left of the anchor's bounds
		tl_convention_offset := adjusted_size * {0, -1}
		bounds = range2(
			rel_pos - adjusted_size * alignment              + tl_convention_offset,
			rel_pos + adjusted_size * (vec2_one - alignment) + tl_convention_offset,
		)
	}
	else {
		centered_convention_offset := adjusted_size * -0.5
		bounds = range2(
			(rel_pos + centered_convention_offset) - adjusted_size * -alignment            ,
			(rel_pos + centered_convention_offset) + adjusted_size * (alignment + vec2_one),
		)
	}

	// Determine Padding's outer bounds
	border_offset := Vec2	{ layout.border_width, layout.border_width }

	padding_bounds := range2(
		bounds.min + border_offset,
		bounds.min - border_offset,
	)

	// Determine Content Bounds
	content_bounds := range2(
		bounds.min + { layout.padding.left,  layout.padding.bottom } + border_offset,
		bounds.max - { layout.padding.right, layout.padding.top }    - border_offset,
	)

	computed.bounds = bounds
	computed.padding = padding_bounds
	computed.content = content_bounds

	if len(box.text.str) > 0
	{
		content_size := content_bounds.max - content_bounds.min
		text_pos : Vec2
		text_pos = content_bounds.min + { 0, text_size.y }
		// text_pos.x += ( content_size.x - text_size.x ) * layout.text_alignment.x
		// text_pos.y += ( content_size.y - text_size.y ) * layout.text_alignment.y
		text_pos += (content_size - text_size) * layout.text_alignment

		computed.text_size = text_size
		computed.text_pos  = { text_pos.x, text_pos.y }
	}
	computed.fresh = true && !dont_mark_fresh
}

ui_box_compute_layout_children :: proc( box : ^UI_Box )
{
	for current := box.first; current != nil && current.prev != box; current = ui_box_tranverse_next( current )
	{
		if current == box do return
		if current.computed.fresh do continue
		ui_box_compute_layout( current )
	}
}

ui_compute_layout :: proc( ui : ^UI_State )
{
	profile(#procedure)
	state := get_state()

	root := ui.root
	{
		computed := & root.computed
		style    := root.style
		layout   := & root.layout
		if ui == & state.screen_ui {
			computed.bounds.min = transmute(Vec2) state.app_window.extent * -1
			computed.bounds.max = transmute(Vec2) state.app_window.extent
		}
		computed.content    = computed.bounds
	}

	for current := root.first; current != nil; current = ui_box_tranverse_next( current )
	{
		if ! current.computed.fresh {
			ui_box_compute_layout( current )
		}
		array_append( & ui.render_queue, UI_RenderBoxInfo {
			current.computed,
			current.style,
			current.text,
			current.layout.font_size,
			current.layout.border_width,
		})
	}
}
