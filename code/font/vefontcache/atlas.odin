package vefontcache

Atlas_Region_Kind :: enum u8 {
	None   = 0x00,
	A      = 0x41,
	B      = 0x42,
	C      = 0x43,
	D      = 0x44,
	E      = 0x45,
	Ignore = 0xFF, // ve_fontcache_cache_glyph_to_atlas uses a -1 value in clear draw call
}

Atlas_Region :: struct {
	state : LRU_Cache,

	width  : i32,
	height : i32,

	size     : Vec2i,
	capacity : Vec2i,
	offset   : Vec2i,

	next_idx : i32,
}

Atlas :: struct {
	width  : i32,
	height : i32,

	glyph_padding     : f32, // Padding to add to bounds_<width/height>_scaled for choosing which atlas region.
	glyph_over_scalar : f32, // Scalar to apply to bounds_<width/height>_scaled for choosing which atlas region.

	region_a : Atlas_Region,
	region_b : Atlas_Region,
	region_c : Atlas_Region,
	region_d : Atlas_Region,
}

atlas_bbox :: #force_inline proc "contextless" ( atlas : ^Atlas, region : Atlas_Region_Kind, local_idx : i32 ) -> (position, size: Vec2)
{
	profile(#procedure)
	switch region
	{
		case .A:
			size.x = f32(atlas.region_a.width)
			size.y = f32(atlas.region_a.height)

			position.x = cast(f32) (( local_idx % atlas.region_a.capacity.x ) * atlas.region_a.width)
			position.y = cast(f32) (( local_idx / atlas.region_a.capacity.x ) * atlas.region_a.height)

			position.x += f32(atlas.region_a.offset.x)
			position.y += f32(atlas.region_a.offset.y)

		case .B:
			size.x = f32(atlas.region_b.width)
			size.y = f32(atlas.region_b.height)

			position.x = cast(f32) (( local_idx % atlas.region_b.capacity.x ) * atlas.region_b.width)
			position.y = cast(f32) (( local_idx / atlas.region_b.capacity.x ) * atlas.region_b.height)

			position.x += f32(atlas.region_b.offset.x)
			position.y += f32(atlas.region_b.offset.y)

		case .C:
			size.x = f32(atlas.region_c.width)
			size.y = f32(atlas.region_c.height)

			position.x = cast(f32) (( local_idx % atlas.region_c.capacity.x ) * atlas.region_c.width)
			position.y = cast(f32) (( local_idx / atlas.region_c.capacity.x ) * atlas.region_c.height)

			position.x += f32(atlas.region_c.offset.x)
			position.y += f32(atlas.region_c.offset.y)

		case .D:
			size.x = f32(atlas.region_d.width)
			size.y = f32(atlas.region_d.height)

			position.x = cast(f32) (( local_idx % atlas.region_d.capacity.x ) * atlas.region_d.width)
			position.y = cast(f32) (( local_idx / atlas.region_d.capacity.x ) * atlas.region_d.height)

			position.x += f32(atlas.region_d.offset.x)
			position.y += f32(atlas.region_d.offset.y)

		case .Ignore, .None, .E:
	}
	return
}

decide_codepoint_region :: #force_inline proc (ctx : ^Context, entry : ^Entry, glyph_index : Glyph ) -> (region_kind : Atlas_Region_Kind, region : ^Atlas_Region, over_sample : Vec2)
{
	profile(#procedure)
	if parser_is_glyph_empty(&entry.parser_info, glyph_index) {
		return .None, nil, {}
	}

	bounds_0, bounds_1 := parser_get_glyph_box(&entry.parser_info, glyph_index)
	bounds_size        := vec2(bounds_1) - vec2(bounds_0)

	atlas             := & ctx.atlas
	glyph_buffer      := & ctx.glyph_buffer
	glyph_padding_dbl := atlas.glyph_padding * 2

	bounds_size_scaled := bounds_size * entry.size_scale * atlas.glyph_over_scalar + glyph_padding_dbl

	// Use a lookup table for faster region selection
	region_lookup := [4]struct { kind: Atlas_Region_Kind, region: ^Atlas_Region } {
		{ .A, & atlas.region_a },
		{ .B, & atlas.region_b },
		{ .C, & atlas.region_c },
		{ .D, & atlas.region_d },
	}

	for region in region_lookup do if bounds_size_scaled.x <= f32(region.region.width) && bounds_size_scaled.y <= f32(region.region.height) {
		return region.kind, region.region, glyph_buffer.over_sample
	}

	if bounds_size_scaled.x <= f32(glyph_buffer.width) \
	&& bounds_size_scaled.y <= f32(glyph_buffer.height) {
		over_sample = \
			bounds_size_scaled.x <= f32(glyph_buffer.width  / 2) &&
			bounds_size_scaled.y <= f32(glyph_buffer.height / 2) ? \
			  {2.0, 2.0} \
			: {1.0, 1.0}
		return .E, nil, over_sample
	}
	return .None, nil, {}
}

// Grab an atlas LRU cache slot.
atlas_reserve_slot :: #force_inline proc ( region : ^Atlas_Region, lru_code : u64 ) -> (atlas_index : i32)
{
	if region.next_idx < region.state.capacity
	{
		evicted         := lru_put( & region.state, lru_code, region.next_idx )
		atlas_index      = region.next_idx
		region.next_idx += 1
		assert( evicted == lru_code )
	}
	else
	{
		next_evict_codepoint := lru_get_next_evicted( & region.state )
		assert( next_evict_codepoint != 0xFFFFFFFFFFFFFFFF )

		atlas_index = lru_peek( & region.state, next_evict_codepoint, must_find = true )
		assert( atlas_index != -1 )

		evicted := lru_put( & region.state, lru_code, atlas_index )
		assert( evicted == next_evict_codepoint )
	}

	assert( lru_get( & region.state, lru_code ) != - 1 )
	return
}
