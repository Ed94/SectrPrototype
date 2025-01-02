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

	regions : [4] ^Atlas_Region,
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

decide_codepoint_region :: #force_inline proc (atlas : Atlas, glyph_buffer : Glyph_Draw_Buffer,  size_scale : f32, glyph_index : Glyph, bounds_size : Vec2 ) -> (region_kind : Atlas_Region_Kind,  over_sample : Vec2)
{
	profile(#procedure)
	glyph_padding_dbl  := atlas.glyph_padding * 2
	bounds_size_scaled := bounds_size * size_scale + glyph_padding_dbl

	for kind in 0 ..< 4 do if bounds_size_scaled.x <= f32( atlas.regions[kind].width) && bounds_size_scaled.y <= f32(atlas.regions[kind].height) {
		return cast(Atlas_Region_Kind) kind, glyph_buffer.over_sample
	}

	if bounds_size_scaled.x <= f32(glyph_buffer.width) \
	&& bounds_size_scaled.y <= f32(glyph_buffer.height) {
		over_sample = \
			bounds_size_scaled.x <= f32(glyph_buffer.width  / 2) &&
			bounds_size_scaled.y <= f32(glyph_buffer.height / 2) ? \
			  {2.0, 2.0} \
			: {1.0, 1.0}
		return .E, over_sample
	}
	return .None, {}
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
		next_evict_codepoint := lru_get_next_evicted( region.state )
		// assert( next_evict_codepoint != 0xFFFFFFFFFFFFFFFF )

		atlas_index = lru_peek( region.state, next_evict_codepoint, must_find = true )
		// assert( atlas_index != -1 )

		evicted := lru_put( & region.state, lru_code, atlas_index )
		// assert( evicted == next_evict_codepoint )
	}

	assert( lru_get( & region.state, lru_code ) != - 1 )
	return
}

check_and_reserve_slot_in_atlas :: #force_inline proc( ctx : Context, glyph_index : Glyph,
	lru_code    : u64,
	atlas_index : ^i32,
	region      : ^Atlas_Region,
) -> (found, should_cache : b8 )
{
	profile(#procedure)
	// assert( glyph_index != -1 )

	if ctx.temp_codepoint_seen_num > i32(cap(ctx.temp_codepoint_seen)) do return

	if (atlas_index ^) == - 1
	{
		// Check to see if we reached capacity for the atlas
		if region.next_idx > region.state.capacity 
		{
			// We will evict LRU. We must predict which LRU will get evicted, and if it's something we've seen then we need to take slowpath and flush batch.
			next_evict_codepoint := lru_get_next_evicted( region.state )
			success : bool
			found, success   = ctx.temp_codepoint_seen[next_evict_codepoint]
			// assert(success != false)
			if (found) {
				return
			}
		}

		should_cache = true
		(atlas_index ^) = atlas_reserve_slot(region, lru_code)
	}

	found = true
	return
}