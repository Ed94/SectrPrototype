package fontstash

atlas_add_rect :: proc( ctx : ^Context, )
{

}

atlas_add_skyline_level :: proc (ctx : ^Context, id : u64, x, y, width, height : i32 ) -> (error : AllocatorError)
{
	error = atlas_insert( ctx, id, x, y + height, width)
	if error != AllocatorError.None {
		ensure( false, "Failed to insert into atlas")
		return
	}

	// Delete skyline segments that fall under the shadow of the new segment.
	for sky_id := id; sky_id < ctx.atlas.num; sky_id += 1
	{
		curr := & ctx.atlas.data[sky_id    ]
		next := & ctx.atlas.data[sky_id + 1]
		if curr.x >= next.x + next.width do break

		shrink := i16(next.x + next.width - curr.x)
		curr.x     += shrink
		curr.width -= shrink

		if curr.width > 0 do break

		atlas_remove(ctx, sky_id)
		sky_id -= 1
	}

	// Merge same height skyline segments that are next to each other.
	for sky_id := id; sky_id < ctx.atlas.num - 1;
	{
		curr := & ctx.atlas.data[sky_id    ]
		next := & ctx.atlas.data[sky_id + 1]

		if curr.y == next.y {
			curr.width += next.width
			atlas_remove(ctx, sky_id + 1)
		}
		else {
			sky_id += 1
		}
	}
	return
}

atlas_delete :: proc ( ctx : ^Context ) {
	using ctx
	array_free( ctx.atlas )
}

atlas_expand :: proc( ctx : ^Context, width, height : i32 )
{
	if width > ctx.width {
		atlas_insert( ctx, ctx.atlas.num, ctx.width, 0, width - ctx.width )
	}

	ctx.width  = width
	ctx.height = height
}

atlas_init :: proc( ctx : ^Context, width, height : i32, num_nodes : u32 = Init_Atlas_Nodes )
{
	error : AllocatorError
	ctx.atlas, error = init_reserve( AtlasNode, context.allocator, u64(num_nodes), dbg_name = "font atlas" )
	ensure(error != AllocatorError.None, "Failed to allocate font atlas")

	ctx.width  = width
	ctx.height = height

	array_append( & ctx.atlas, AtlasNode{ width = i16(width)} )
}

atlas_insert :: proc( ctx : ^Context, id : u64, x, y, width : i32 ) -> (error : AllocatorError)
{
	error = array_append_at( & ctx.atlas, AtlasNode{ i16(x), i16(y), i16(width) }, id )
	return
}

atlas_remove :: #force_inline proc( ctx : ^Context, id : u64 ) { remove_at( ctx.atlas, id ) }

atlas_reset :: proc( ctx : ^Context, width, height : i32 )
{
	ctx.width  = width
	ctx.height = height
	clear( ctx.atlas )

	array_append( & ctx.atlas, AtlasNode{ width = i16(width)} )
}

atlas_rect_fits :: proc( ctx : ^Context, location, width, height : i32 ) -> (max_height : i32)
{
	// Checks if there is enough space at the location of skyline span 'i',
	// and return the max height of all skyline spans under that at that location,
	// (think tetris block being dropped at that position). Or -1 if no space found.
	atlas := to_slice(ctx.atlas)
	node := atlas[location]

	space_left : i32
	if i32(node.x) + width > ctx.width {
		max_height = -1
		return
	}

	space_left = width;

	y        := i32(node.y)
	location := location
	for ; space_left > 0;
	{
		if u64(location) == ctx.atlas.num {
			max_height = -1
			return
		}

		node := atlas[location]

		y := max(y, i32(node.y))
		if y + height > ctx.height {
			max_height = -1
			return
		}

		space_left -= i32(node.width)
		location += 1
	}
	max_height = y
	return
}
