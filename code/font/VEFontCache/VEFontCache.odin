/*
A port of (https://github.com/hypernewbie/VEFontCache) to Odin.

Status:
This port is heavily tied to the grime package in SectrPrototype.

TODO(Ed): Make an idiomatic port of this for Odin (or just dupe the data structures...)
*/
package VEFontCache

Font_ID :: i64
Glyph   :: i32

Colour :: [4]f32
Vec2   :: [2]f32
Vec2i  :: [2]u32

AtlasRegionKind :: enum {
	A = 0,
	B = 1,
	C = 2,
	D = 3
}

Vertex :: struct {
	pos  : Vec2,
	u, v : f32,
}

// GlyphDrawBuffer :: struct {
// 	over_sample : Vec2,

// 	batch   : i32,
// 	width   : i32,
// 	height  : i32,
// 	padding : i32,
// }

ShapedText :: struct {
	glyphs         : Array(Glyph),
	positions      : Array(Vec2),
	end_cursor_pos : Vec2,
}

ShapedTextCache :: struct {
	storage       : Array(ShapedText),
	state         : LRU_Cache,
	next_cache_id : i32,
}

Entry :: struct {
	parser_info : ParserInfo,
	shaper_info : ShaperInfo,
	id          : Font_ID,
	used        : b32,
	size        : f32,
	size_scale  : f32,
}

Entry_Default :: Entry {
	id         = 0,
	used       = false,
	size       = 24.0,
	size_scale = 1.0,
}

Context :: struct {
	backing : Allocator,

	parser_kind : ParserKind,
	parser_ctx  : ParserContext,
	shaper_ctx  : ShaperContext,

	entries : Array(Entry),

	temp_path           : Array(Vec2),
	temp_codepoint_seen : HMapChained(bool),

	snap_width  : u32,
	snap_height : u32,

	colour     : Colour,
	cursor_pos : Vec2,

	draw_list   : DrawList,
	atlas       : Atlas,
	shape_cache : ShapedTextCache,

	text_shape_adv : b32,
}

Module_Ctx :: Context

InitAtlasRegionParams :: struct {
	width  : u32,
	height : u32,
}

InitAtlasParams :: struct {
	width           : u32,
	height          : u32,
	glyph_padding   : u32,

	region_a : InitAtlasRegionParams,
	region_b : InitAtlasRegionParams,
	region_c : InitAtlasRegionParams,
	region_d : InitAtlasRegionParams,
}

InitAtlasParams_Default :: InitAtlasParams {
	width         = 4 * Kilobyte,
	height        = 2 * Kilobyte,
	glyph_padding = 1,

	region_a = {
		width  = 32,
		height = 32,
	},
	region_b = {
		width  = 32,
		height = 64,
	},
	region_c = {
		width  = 64,
		height = 64,
	},
	region_d = {
		width  = 128,
		height = 128,
	}
}

InitGlyphDrawParams :: struct {
	over_sample  : Vec2i,
	buffer_batch : u32,
	padding      : u32,
}

InitGlyphDrawParams_Default :: InitGlyphDrawParams {
	over_sample  = { 4, 4 },
	buffer_batch = 4,
	padding      = InitAtlasParams_Default.glyph_padding,
}

InitShapeCacheParams :: struct {
	capacity       : u32,
	reserve_length : u32,
}

InitShapeCacheParams_Default :: InitShapeCacheParams {
	capacity       = 256,
	reserve_length = 64,
}

init :: proc( ctx : ^Context,
	allocator                   := context.allocator,
	atlas_params                := InitAtlasParams_Default,
	glyph_draw_params           := InitGlyphDrawParams_Default,
	shape_cache_params          := InitShapeCacheParams_Default,
	advance_snap_smallfont_size : u32 = 12,
	entires_reserve             : u32 = Kilobyte,
	temp_path_reserve           : u32 = Kilobyte,
	temp_codepoint_seen_reserve : u32 = 4 * Kilobyte,
)
{
	assert( ctx != nil, "Must provide a valid context" )
	using ctx

	ctx.backing       = allocator
	context.allocator = ctx.backing

	error : AllocatorError
	entries, error = make( Array(Entry), u64(entires_reserve) )
	assert(error == .None, "VEFontCache.init : Failed to allocate entries")

	temp_path, error = make( Array(Vec2), u64(temp_path_reserve) )
	assert(error == .None, "VEFontCache.init : Failed to allocate temp_path")

	temp_codepoint_seen, error = make( HMapChained(bool), hmap_closest_prime( uint(temp_codepoint_seen_reserve)) )
	assert(error == .None, "VEFontCache.init : Failed to allocate temp_path")

	draw_list.vertices, error = make( Array(Vertex), 4 * Kilobyte )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.vertices")

	draw_list.indices, error = make( Array(u32), 8 * Kilobyte )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.indices")

	draw_list.calls, error = make( Array(DrawCall), 512 )
	assert(error == .None, "VEFontCache.init : Failed to allocate draw_list.calls")

	init_atlas_region :: proc( region : ^AtlasRegion, params : InitAtlasParams, region_params : InitAtlasRegionParams ) {
		using region

		next_idx = 0;
		width    = region_params.width
		height   = region_params.height
		size = {
			params.width  / 4,
			params.height / 2,
		}
		capacity = {
			size.x / width,
			size.y / height,
		}

		error : AllocatorError
		// state.cache, error = make( HMapChained(LRU_Link), uint(capacity.x * capacity.y) )
		// assert( error == .None, "VEFontCache.init_atlas_region : Failed to allocate state.cache")
		LRU_init( & state, capacity.x * capacity.y )
	}
	init_atlas_region( & atlas.region_a, atlas_params, atlas_params.region_a )
	init_atlas_region( & atlas.region_b, atlas_params, atlas_params.region_b )
	init_atlas_region( & atlas.region_c, atlas_params, atlas_params.region_c )
	init_atlas_region( & atlas.region_d, atlas_params, atlas_params.region_d )

	atlas.region_b.offset.y = atlas.region_a.size.y
	atlas.region_c.offset.x = atlas.region_a.size.x
	atlas.region_d.offset.x = atlas.width / 2

	LRU_init( & shape_cache.state, shape_cache_params.capacity )
	for idx : u32 = 0; idx < shape_cache_params.capacity; idx += 1 {
		stroage_entry := & shape_cache.storage.data[idx]
		using stroage_entry
		glyphs, error = make( Array(Glyph), cast(u64) shape_cache_params.reserve_length )
		assert( error != .None, "VEFontCache.init : Failed to allocate glyphs array for shape cache storage" )

		positions, error = make( Array(Vec2), cast(u64) shape_cache_params.reserve_length )
		assert( error != .None, "VEFontCache.init : Failed to allocate positions array for shape cache storage" )
	}

	// Note(From original author): We can actually go over VE_FONTCACHE_GLYPHDRAW_BUFFER_BATCH batches due to smart packing!
	{
		using atlas
		draw_list.calls, error = make( Array(DrawCall), cast(u64) glyph_draw_params.buffer_batch * 2 )
		assert( error != .None, "VEFontCache.init : Failed to allocate calls for draw_list" )

		draw_list.indices, error = make( Array(u32), cast(u64) glyph_draw_params.buffer_batch * 2 * 6 )
		assert( error != .None, "VEFontCache.init : Failed to allocate indices array for draw_list" )

		draw_list.vertices, error = make( Array(Vertex), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error != .None, "VEFontCache.init : Failed to allocate vertices array for draw_list" )

		clear_draw_list.calls, error = make( Array(DrawCall), cast(u64) glyph_draw_params.buffer_batch * 2 )
		assert( error != .None, "VEFontCache.init : Failed to allocate calls for calls for clear_draw_list" )

		clear_draw_list.indices, error = make( Array(u32), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error != .None, "VEFontCache.init : Failed to allocate calls for indices array for clear_draw_list" )

		clear_draw_list.vertices, error = make( Array(Vertex), cast(u64) glyph_draw_params.buffer_batch * 2 * 4 )
		assert( error != .None, "VEFontCache.init : Failed to allocate vertices array for clear_draw_list" )
	}

	shaper_init( & shaper_ctx )
}
