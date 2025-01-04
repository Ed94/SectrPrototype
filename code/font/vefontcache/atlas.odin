package vefontcache

Atlas_Region_Kind :: enum u8 {
	None   = 0x00,
	A      = 0x01,
	B      = 0x02,
	C      = 0x03,
	D      = 0x04,
	E      = 0x05,
	Ignore = 0xFF, // ve_fontcache_cache_glyph_to_atlas uses a -1 value in clear draw call
}

Atlas_Region :: struct {
	state : LRU_Cache,

	size     : Vec2i,
	capacity : Vec2i,
	offset   : Vec2i,

	width  : i32,
	height : i32,

	next_idx : i32,
}

Atlas :: struct {
	region_a : Atlas_Region,
	region_b : Atlas_Region,
	region_c : Atlas_Region,
	region_d : Atlas_Region,

	regions : [5] ^Atlas_Region,

	glyph_padding     : f32, // Padding to add to bounds_<width/height>_scaled for choosing which atlas region.
	glyph_over_scalar : f32, // Scalar to apply to bounds_<width/height>_scaled for choosing which atlas region.

	width  : i32,
	height : i32,
}

atlas_region_bbox :: proc( region : Atlas_Region, local_idx : i32 ) -> (position, size: Vec2)
{
	size.x = f32(region.width)
	size.y = f32(region.height)

	position.x = cast(f32) (( local_idx % region.capacity.x ) * region.width)
	position.y = cast(f32) (( local_idx / region.capacity.x ) * region.height)

	position.x += f32(region.offset.x)
	position.y += f32(region.offset.y)
	return
}

atlas_decide_region :: #force_inline proc "contextless" (atlas : Atlas, glyph_buffer_size : Vec2, bounds_size_scaled : Vec2 ) -> (region_kind : Atlas_Region_Kind)
{
	profile(#procedure)
	glyph_padding_dbl  := atlas.glyph_padding * 2
	padded_bounds      := bounds_size_scaled + glyph_padding_dbl

	for kind in 1 ..= 4 do if padded_bounds.x <= f32( atlas.regions[kind].width) && padded_bounds.y <= f32(atlas.regions[kind].height) {
		return cast(Atlas_Region_Kind) kind
	}

	if padded_bounds.x <= glyph_buffer_size.x && padded_bounds.y <= glyph_buffer_size.y{
		return .E
	}
	return .None
}

// Grab an atlas LRU cache slot.
atlas_reserve_slot :: #force_inline proc ( region : ^Atlas_Region, lru_code : u32 ) -> (atlas_index : i32)
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
		next_evict_codepoint := lru_get_next_evicted( region.state )
		assert( next_evict_codepoint != 0xFFFFFFFF)

		atlas_index = lru_peek( region.state, next_evict_codepoint, must_find = true )
		assert( atlas_index != -1 )

		evicted := lru_put( & region.state, lru_code, atlas_index )
		assert( evicted == next_evict_codepoint )
	}

	assert( lru_get( & region.state, lru_code ) != - 1 )
	return
}
