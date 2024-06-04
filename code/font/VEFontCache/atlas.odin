package VEFontCache

GlyphDrawBuffer :: struct {
	over_sample   : Vec2,
	buffer_batch  : u32,
	buffer_width  : u32,
	buffer_height : u32,
	draw_padding  : u32,

	update_batch_x  : i32,
	clear_draw_list : DrawList,
	draw_list       : DrawList,
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

	using glyph_update_batch : GlyphDrawBuffer,
}
