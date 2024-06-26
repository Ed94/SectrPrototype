package VEFontCache

AtlasRegionKind :: enum u8 {
	None   = 0x00,
	A      = 0x41,
	B      = 0x42,
	C      = 0x43,
	D      = 0x44,
	E      = 0x45,
	Ignore = 0xFF, // ve_fontcache_cache_glyph_to_atlas uses a -1 value in clear draw call
}

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
}

atlas_bbox :: proc( atlas : ^Atlas, region : AtlasRegionKind, local_idx : i32 ) -> (position : Vec2, width, height : f32)
{
	switch region
	{
		case .A:
			width  = f32(atlas.region_a.width)
			height = f32(atlas.region_b.height)

			position.x = cast(f32) (( local_idx % atlas.region_a.capacity.x ) * i32(atlas.region_a.width))
			position.y = cast(f32) (( local_idx / atlas.region_a.capacity.x ) * i32(atlas.region_a.height))

			position.x += f32(atlas.region_a.offset.x)
			position.y += f32(atlas.region_a.offset.y)

		case .B:
			width  = f32(atlas.region_b.width)
			height = f32(atlas.region_b.height)

			position.x = cast(f32) (( local_idx % atlas.region_b.capacity.x ) * i32(atlas.region_b.width))
			position.y = cast(f32) (( local_idx / atlas.region_b.capacity.x ) * i32(atlas.region_b.height))

			position.x += f32(atlas.region_b.offset.x)
			position.y += f32(atlas.region_b.offset.y)

		case .C:
			width  = f32(atlas.region_c.width)
			height = f32(atlas.region_c.height)

			position.x = cast(f32) (( local_idx % atlas.region_c.capacity.x ) * i32(atlas.region_c.width))
			position.y = cast(f32) (( local_idx / atlas.region_c.capacity.x ) * i32(atlas.region_c.height))

			position.x += f32(atlas.region_c.offset.x)
			position.y += f32(atlas.region_c.offset.y)

		case .D:
			width  = f32(atlas.region_d.width)
			height = f32(atlas.region_d.height)

			position.x = cast(f32) (( local_idx % atlas.region_d.capacity.x ) * i32(atlas.region_d.width))
			position.y = cast(f32) (( local_idx / atlas.region_d.capacity.x ) * i32(atlas.region_d.height))

			position.x += f32(atlas.region_d.offset.x)
			position.y += f32(atlas.region_d.offset.y)

		case .Ignore: fallthrough
		case .None: fallthrough
		case .E:
	}
	return
}

can_batch_glyph :: #force_inline proc( ctx : ^Context, font : FontID, entry : ^Entry, glyph_index : Glyph,
	lru_code    : u64,
	atlas_index : i32,
	region_kind : AtlasRegionKind,
	region      : ^AtlasRegion,
	over_sample : Vec2
) -> b32
{
	// profile(#procedure)
	assert( glyph_index != -1 )

	// E region can't batch
	if region_kind == .E || region_kind == .None do return false
	if ctx.temp_codepoint_seen_num > 1024        do return false
	// TODO(Ed): Why 1024?

	if atlas_index == - 1
	{
		if region.next_idx > u32( region.state.capacity) {
			// We will evict LRU. We must predict which LRU will get evicted, and if it's something we've seen then we need to take slowpath and flush batch.
			next_evict_codepoint := LRU_get_next_evicted( & region.state )
			seen, success := ctx.temp_codepoint_seen[next_evict_codepoint]
			assert(success != false)

			if (seen) {
				return false
			}
		}

		cache_glyph_to_atlas( ctx, font, glyph_index, lru_code, atlas_index, entry, region_kind, region, over_sample )
	}

	assert( LRU_get( & region.state, lru_code ) != -1 )
	mark_batch_codepoint_seen( ctx, lru_code)
	return true
}

decide_codepoint_region :: #force_inline proc( ctx : ^Context, entry : ^Entry, glyph_index : Glyph
) -> (region_kind : AtlasRegionKind, region : ^AtlasRegion, over_sample : Vec2)
{
	if parser_is_glyph_empty( & entry.parser_info, glyph_index ) {
		region_kind = .None
	}

	bounds_0, bounds_1 := parser_get_glyph_box( & entry.parser_info, glyph_index )
	bounds_width  := bounds_1.x - bounds_0.x
	bounds_height := bounds_1.y - bounds_0.y

	atlas        := & ctx.atlas
	glyph_buffer := & ctx.glyph_buffer

	bounds_width_scaled  := cast(u32) (f32(bounds_width)  * entry.size_scale + 2.0 * f32(atlas.glyph_padding))
	bounds_height_scaled := cast(u32) (f32(bounds_height) * entry.size_scale + 2.0 * f32(atlas.glyph_padding))

	if bounds_width_scaled <= atlas.region_a.width && bounds_height_scaled <= atlas.region_a.height
	{
		// Region A for small glyphs. These are good for things such as punctuation.
		region_kind = .A
		region      = & atlas.region_a
	}
	else if bounds_width_scaled <= atlas.region_b.width && bounds_height_scaled <= atlas.region_b.height
	{
		// Region B for tall glyphs. These are good for things such as european alphabets.
		region_kind = .B
		region      = & atlas.region_b
	}
	else if bounds_width_scaled <= atlas.region_c.width && bounds_height_scaled <= atlas.region_c.height
	{
		// Region C for big glyphs. These are good for things such as asian typography.
		region_kind = .C
		region      = & atlas.region_c
	}
	else if bounds_width_scaled <= atlas.region_d.width && bounds_height_scaled <= atlas.region_d.height
	{
		// Region D for huge glyphs. These are good for things such as titles and 4k.
		region_kind = .D
		region      = & atlas.region_d
	}
	else if bounds_width_scaled <= glyph_buffer.width && bounds_height_scaled <= glyph_buffer.height
	{
		// Region 'E' for massive glyphs. These are rendered uncached and un-oversampled.
		region_kind = .E
		region      = nil
		if bounds_width_scaled <= glyph_buffer.width / 2 && bounds_height_scaled <= glyph_buffer.height / 2 {
			over_sample = { 2.0, 2.0 }
		}
		else {
			over_sample = { 1.0, 1.0 }
		}
		return
	}
	else {
		region_kind = .None
		return
	}

	over_sample = glyph_buffer.over_sample
	assert(region != nil)
	return
}
