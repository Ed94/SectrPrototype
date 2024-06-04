package VEFontCache

AtlasRegion :: struct {
	state : LRU_Cache,

	width  : u32,
	height : u32,

	size     : Vec2i,
	capacity : Vec2i,
	offset   : Vec2i,

	next_idx : u32,
}

Atlas :: struct {
	width  : u32,
	height : u32,

	glyph_padding : u32,

	region_a : AtlasRegion,
	region_b : AtlasRegion,
	region_c : AtlasRegion,
	region_d : AtlasRegion,

	using glyph_update_batch : GlyphDrawBuffer,
}

atlas_bbox :: proc( atlas : ^Atlas, region : AtlasRegionKind, local_idx : u32 ) -> (position : Vec2, width, height : f32)
{
	switch region
	{
		case .A:
			width  = f32(atlas.region_a.width)
			height = f32(atlas.region_b.height)

			position.x = cast(f32) (( local_idx % atlas.region_a.capacity.x ) * atlas.region_a.width)
			position.y = cast(f32) (( local_idx % atlas.region_a.capacity.x ) * atlas.region_a.height)

			position.x += f32(atlas.region_a.offset.x)
			position.y += f32(atlas.region_a.offset.y)

		case .B:
			width  = f32(atlas.region_b.width)
			height = f32(atlas.region_b.height)

			position.x = cast(f32) (( local_idx % atlas.region_b.capacity.x ) * atlas.region_b.width)
			position.y = cast(f32) (( local_idx % atlas.region_b.capacity.x ) * atlas.region_b.height)

			position.x += f32(atlas.region_b.offset.x)
			position.y += f32(atlas.region_b.offset.y)

		case .C:
			width  = f32(atlas.region_c.width)
			height = f32(atlas.region_c.height)

			position.x = cast(f32) (( local_idx % atlas.region_c.capacity.x ) * atlas.region_c.width)
			position.y = cast(f32) (( local_idx % atlas.region_c.capacity.x ) * atlas.region_c.height)

			position.x += f32(atlas.region_c.offset.x)
			position.y += f32(atlas.region_c.offset.y)

		case .D:
			width  = f32(atlas.region_d.width)
			height = f32(atlas.region_d.height)

			position.x = cast(f32) (( local_idx % atlas.region_d.capacity.x ) * atlas.region_d.width)
			position.y = cast(f32) (( local_idx % atlas.region_d.capacity.x ) * atlas.region_d.height)

			position.x += f32(atlas.region_d.offset.x)
			position.y += f32(atlas.region_d.offset.y)

		case .None: fallthrough
		case .E:
			assert(false, "What?")
	}
	return
}

can_batch_glyph :: proc( ctx : ^Context, font : FontID, entry : ^Entry, glyph_index : Glyph ) -> b32
{
	assert( ctx != nil )
	assert( entry.id == font )

	// Decide which atlas to target
	assert( glyph_index != -1 )
	region, state, next_index, over_sample := decide_codepoint_region( ctx, entry, glyph_index )

	// E region can't batch
	if region == .E || region == .None    do return false
	if ctx.temp_codepoint_seen_num > 1024 do return false
	// Note(Ed): Why 1024?

	// Is this glyph cached?
	// lru_code    := u64(glyph_index) + ( ( 0x100000000 * u64(font) ) & 0xFFFFFFFF00000000 )
	lru_code    := font_glyph_lru_code(font, glyph_index)
	atlas_index := LRU_get( state, lru_code )
	if atlas_index == - 1
	{
		if (next_index^) >= u32(state.capacity) {
			// We will evict LRU. We must predict which LRU will get evicted, and if it's something we've seen then we need to take slowpath and flush batch.
			next_evict_codepoint := LRU_get_next_evicted( state )
			seen := get( ctx.temp_codepoint_seen, next_evict_codepoint )
			assert(seen != nil)

			if (seen^) {
				return false
			}
		}

		cache_glyph_to_atlas( ctx, font, glyph_index )
	}

	assert( LRU_get( state, lru_code ) != 1 )
	set( ctx.temp_codepoint_seen, lru_code, true )
	ctx.temp_codepoint_seen_num += 1
	return true
}

decide_codepoint_region :: proc( ctx : ^Context, entry : ^Entry, glyph_index : Glyph
) -> (region : AtlasRegionKind, state : ^LRU_Cache, next_idx : ^u32, over_sample : Vec2)
{
	if parser_is_glyph_empty( entry.parser_info, glyph_index ) {
		region = .None
	}

	bounds_0, bounds_1 := parser_get_glyph_box( entry.parser_info, glyph_index )
	bounds_width  := bounds_1.x - bounds_0.x
	bounds_height := bounds_1.y - bounds_0.y

	atlas := & ctx.atlas

	bounds_width_scaled  := cast(u32) (f32(bounds_width)  * entry.size_scale + 2.0 * f32(atlas.glyph_padding))
	bounds_height_scaled := cast(u32) (f32(bounds_height) * entry.size_scale + 2.0 * f32(atlas.glyph_padding))

	if bounds_width_scaled <= atlas.region_a.width && bounds_height_scaled <= atlas.region_a.height
	{
		// Region A for small glyphs. These are good for things such as punctuation.
		region   = .A
		state    = & atlas.region_a.state
		next_idx = & atlas.region_a.next_idx
	}
	else if bounds_width_scaled <= atlas.region_b.width && bounds_height_scaled <= atlas.region_b.height
	{
		// Region B for tall glyphs. These are good for things such as european alphabets.
		region   = .B
		state    = & atlas.region_b.state
		next_idx = & atlas.region_b.next_idx
	}
	else if bounds_width_scaled <= atlas.region_c.width && bounds_height_scaled <= atlas.region_c.height
	{
		// Region C for big glyphs. These are good for things such as asian typography.
		region   = .C
		state    = & atlas.region_c.state
		next_idx = & atlas.region_c.next_idx
	}
	else if bounds_width_scaled <= atlas.region_d.width && bounds_height_scaled <= atlas.region_d.height
	{
		// Region D for huge glyphs. These are good for things such as titles and 4k.
		region   = .D
		state    = & atlas.region_d.state
		next_idx = & atlas.region_d.next_idx
	}
	else if bounds_width_scaled <= atlas.buffer_width && bounds_height_scaled <= atlas.buffer_height
	{
		// Region 'E' for massive glyphs. These are rendered uncached and un-oversampled.
		region   = .E
		state    = nil
		next_idx = nil
		if bounds_width_scaled <= atlas.buffer_width / 2 && bounds_height_scaled <= atlas.buffer_height / 2 {
			over_sample = { 2.0, 2.0 }
		}
		else {
			over_sample = { 1.0, 1.0 }
		}
		return
	}
	else {
		region = .None
		return
	}

	assert(state    != nil)
	assert(next_idx != nil)
	return
}
