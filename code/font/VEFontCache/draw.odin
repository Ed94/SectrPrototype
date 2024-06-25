package VEFontCache

import "core:math"

DrawCall :: struct {
	pass              : FrameBufferPass,
	start_index       : u32,
	end_index         : u32,
	clear_before_draw : b32,
	region            : AtlasRegionKind,
	colour            : Colour,
}

DrawCall_Default :: DrawCall {
	pass              = .None,
	start_index       = 0,
	end_index         = 0,
	clear_before_draw = false,
	region            = .A,
	colour            = { 1.0, 1.0, 1.0, 1.0 }
}

DrawList :: struct {
	vertices : Array(Vertex),
	indices  : Array(u32),
	calls    : Array(DrawCall),
}

FrameBufferPass :: enum u32 {
	None            = 0,
	Glyph           = 1,
	Atlas           = 2,
	Target          = 3,
	Target_Uncached = 4,
}

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

blit_quad :: proc( draw_list : ^DrawList, p0 : Vec2 = {0, 0}, p1 : Vec2 = {1, 1}, uv0 : Vec2 = {0, 0}, uv1 : Vec2 = {1, 1} )
{
	// logf("Blitting: xy0: %0.2f, %0.2f xy1: %0.2f, %0.2f uv0: %0.2f, %0.2f uv1: %0.2f, %0.2f",
		// p0.x, p0.y, p1.x, p1.y, uv0.x, uv0.y, uv1.x, uv1.y);
	v_offset := cast(u32) draw_list.vertices.num

	vertex := Vertex {
		{p0.x, p0.y},
		uv0.x, uv0.y
	}
	append( & draw_list.vertices, vertex )

	vertex = Vertex {
		{p0.x, p1.y},
		uv0.x, uv1.y
	}
	append( & draw_list.vertices, vertex )

	vertex = Vertex {
		{p1.x, p0.y},
		uv1.x, uv0.y
	}
	append( & draw_list.vertices, vertex )

	vertex = Vertex {
		{p1.x, p1.y},
		uv1.x, uv1.y
	}
	append( & draw_list.vertices, vertex )

	quad_indices : []u32 = {
		0, 1, 2,
		2, 1, 3
	}
	for index : i32 = 0; index < 6; index += 1 {
		append( & draw_list.indices, v_offset + quad_indices[ index ] )
	}
	// draw_list_vert_slice  := array_to_slice(draw_list.vertices)
	// draw_list_index_slice := array_to_slice(draw_list.indices)
	return
}

// ve_fontcache_clear_drawlist
clear_draw_list :: proc( draw_list : ^DrawList ) {
	clear( draw_list.calls )
	clear( draw_list.indices )
	clear( draw_list.vertices )
}

directly_draw_massive_glyph :: proc( ctx : ^Context, entry : ^Entry, glyph : Glyph, bounds_0 : Vec2i, bounds_width, bounds_height : i32, over_sample, position, scale : Vec2 )
{
	flush_glyph_buffer_to_atlas( ctx )

	// Draw un-antialiased glyph to update FBO.
	glyph_draw_scale     := over_sample * entry.size_scale
	glyph_draw_translate := Vec2{ -f32(bounds_0.x), -f32(bounds_0.y)} * glyph_draw_scale + Vec2{ f32(ctx.atlas.glyph_padding), f32(ctx.atlas.glyph_padding) }
	screenspace_x_form( & glyph_draw_translate, & glyph_draw_scale, f32(ctx.atlas.buffer_width), f32(ctx.atlas.buffer_height) )

	cache_glyph( ctx, entry.id, glyph, glyph_draw_scale, glyph_draw_translate )

	// Figure out the source rect.
	glyph_position   := Vec2 {}
	glyph_width      := f32(bounds_width)  * entry.size_scale * over_sample.x
	glyph_height     := f32(bounds_height) * entry.size_scale * over_sample.y
	glyph_dst_width  := f32(bounds_width)  * entry.size_scale
	glyph_dst_height := f32(bounds_height) * entry.size_scale
	glyph_width      += f32(2 * ctx.atlas.glyph_padding)
	glyph_height     += f32(2 * ctx.atlas.glyph_padding)
	glyph_dst_width  += f32(2 * ctx.atlas.glyph_padding)
	glyph_dst_height += f32(2 * ctx.atlas.glyph_padding)

	// Figure out the destination rect.
	bounds_scaled := Vec2 {
		cast(f32) i32(f32(bounds_0.x) * entry.size_scale - 0.5),
		cast(f32) i32(f32(bounds_0.y) * entry.size_scale - 0.5),
	}
	dst        := position + scale * bounds_scaled
	dst_width  := scale.x * glyph_dst_width
	dst_height := scale.y * glyph_dst_height
	dst.x      -= scale.x * f32(ctx.atlas.draw_padding)
	dst.y      -= scale.y * f32(ctx.atlas.draw_padding)
	dst_size   := Vec2{ dst_width, dst_height }

	glyph_size := Vec2 { glyph_width, glyph_height }
	textspace_x_form( & glyph_position, & glyph_size, f32(ctx.atlas.buffer_width), f32(ctx.atlas.buffer_height) )

	// Add the glyph drawcall.
	call : DrawCall
	{
		using call
		pass        = .Target_Uncached
		colour      = ctx.colour
		start_index = u32(ctx.draw_list.indices.num)
		blit_quad( & ctx.draw_list, dst, dst + dst_size, glyph_position, glyph_position + glyph_size )
		end_index   = u32(ctx.draw_list.indices.num)
		append( & ctx.draw_list.calls, call )
	}

	// Clear glyph_update_FBO.
	call.pass              = .Glyph
	call.start_index       = 0
	call.end_index         = 0
	call.clear_before_draw = true
	append( & ctx.draw_list.calls, call )
}

draw_cached_glyph :: proc( ctx : ^Context, entry : ^Entry, glyph_index : Glyph, position, scale : Vec2 ) -> b32
{
	// Glyph not in current font
	if glyph_index == 0                                          do return true
	if parser_is_glyph_empty( & entry.parser_info, glyph_index ) do return true

	bounds_0, bounds_1 := parser_get_glyph_box( & entry.parser_info, glyph_index )

	bounds_width  := f32(bounds_1.x - bounds_0.x)
	bounds_height := f32(bounds_1.y - bounds_0.y)

	// Decide which atlas to target
	region_kind, region, over_sample := decide_codepoint_region( ctx, entry, glyph_index )

	// E region is special case and not cached to atlas
	if region_kind == .E
	{
		directly_draw_massive_glyph( ctx, entry, glyph_index, bounds_0, cast(i32) bounds_width, cast(i32) bounds_height, over_sample, position, scale )
		return true
	}

	// Is this codepoint cached?
	// lru_code    := u64(glyph_index) + ( ( 0x100000000 * u64(entry.id) ) & 0xFFFFFFFF00000000 )
	lru_code    := font_glyph_lru_code(entry.id, glyph_index)
	atlas_index := LRU_get( & region.state, lru_code )
	if atlas_index == - 1 {
		return false
	}

	atlas := & ctx.atlas
	atlas_width   := f32(atlas.width)
	atlas_height  := f32(atlas.height)
	glyph_padding := f32(atlas.glyph_padding)

	// Figure out the source bounding box in the atlas texture
	glyph_atlas_position, glyph_atlas_width, glyph_atlas_height := atlas_bbox( atlas, region_kind, atlas_index )

	glyph_width    := bounds_width  * entry.size_scale
	glyph_height   := bounds_height * entry.size_scale

	glyph_width  += glyph_padding
	glyph_height += glyph_padding
	glyph_scale  := Vec2 { glyph_width, glyph_height }

	bounds_0_scaled := Vec2{ f32(bounds_0.x), f32(bounds_0.y) } * entry.size_scale //- { 0.5, 0.5 }
	bounds_0_scaled  = {
		math.ceil(bounds_0_scaled.x),
		math.ceil(bounds_0_scaled.y),
	}
	// dst := position * scale * bounds_0_scaled
	dst := Vec2 {
		position.x + bounds_0_scaled.x * scale.x,
		position.y + bounds_0_scaled.y * scale.y,
	}
	dst_width  := scale.x * glyph_width
	dst_height := scale.y * glyph_height
	dst        -= scale   * glyph_padding
	dst_scale  := Vec2 { dst_width, dst_height }

	textspace_x_form( & glyph_atlas_position, & glyph_scale, atlas_width, atlas_height )

	// Add the glyph drawcall
	call := DrawCall_Default
	{
		using call
		pass        = .Target
		colour      = ctx.colour
		start_index = cast(u32) ctx.draw_list.indices.num

		blit_quad( & ctx.draw_list, dst, dst + dst_scale, glyph_atlas_position, glyph_atlas_position + glyph_scale )
		end_index   = cast(u32) ctx.draw_list.indices.num
	}
	append( & ctx.draw_list.calls, call )
	return true
}

// Constructs a triangle fan to fill a shape using the provided path
// outside_point represents the center point of the fan.
//
// Note(Original Author):
// WARNING: doesn't actually append drawcall; caller is responsible for actually appending the drawcall.
// ve_fontcache_draw_filled_path
draw_filled_path :: proc( draw_list : ^DrawList, outside_point : Vec2, path : []Vec2,
	scale     := Vec2 { 1, 1 },
	translate := Vec2 { 0, 0 },
	debug_print_verbose : b32 = false
)
{
	if debug_print_verbose
	{
		log("outline_path:")
		for point in path {
			vec := point * scale + translate
			logf(" %0.2f %0.2f", vec.x, vec.y )
		}
	}

	v_offset := cast(u32) draw_list.vertices.num
	for point in path {
		vertex := Vertex {
			pos = point * scale + translate,
			u = 0,
			v = 0,
		}
		append( & draw_list.vertices, vertex )
	}

	outside_vertex := cast(u32) draw_list.vertices.num
	{
		vertex := Vertex {
			pos = outside_point * scale + translate,
			u = 0,
			v = 0,
		}
		append( & draw_list.vertices, vertex )
	}

	for index : u32 = 1; index < u32(len(path)); index += 1 {
		indices := & draw_list.indices
		append( indices, outside_vertex )
		append( indices, v_offset + index - 1 )
		append( indices, v_offset + index )
	}
}

// TODO(Ed): Change this to be whitespace aware so that we can optimize the caching of shpaes properly.
// Right now the entire text provided to this call is considered a "shape" this is really bad as basically it invalidates caching for large chunks of text
// Instead we should be aware of whitespace tokens and the chunks between them (the whitespace lexer could be abused for this). 
// From there we should maek a 'draw text shape' that breaks up the batch text draws for each of the shapes.
draw_text :: proc( ctx : ^Context, font : FontID, text_utf8 : string, position : Vec2, scale : Vec2 ) -> b32
{
	assert( ctx != nil )
	assert( font >= 0 && font < FontID(ctx.entries.num) )

	context.allocator = ctx.backing

	position    := position
	snap_width  := f32(ctx.snap_width)
	snap_height := f32(ctx.snap_height)
	if ctx.snap_width  > 0 do position.x = cast(f32) cast(u32) (position.x * snap_width  + 0.5) / snap_width
	if ctx.snap_height > 0 do position.y = cast(f32) cast(u32) (position.y * snap_height + 0.5) / snap_height

	entry  := & ctx.entries.data[ font ]

	// entry.size_scale = parser_scale( & entry.parser_info, entry.size )

	post_shapes_draw_cursor_pos : Vec2
	last_shaped                 : ^ShapedText

	ChunkType   :: enum u32 { Visible, Formatting }
	chunk_kind  : ChunkType
	chunk_start : int = 0
	chunk_end   : int = 0

	text_utf8_bytes := transmute([]u8) text_utf8
	text_chunk      : string

	when true {
	text_chunk = transmute(string) text_utf8_bytes[ : ]
	if len(text_chunk) > 0 {
		shaped := shape_text_cached( ctx, font, text_chunk )
		post_shapes_draw_cursor_pos += draw_text_shape( ctx, font, entry, shaped, position, scale, snap_width, snap_height )
		ctx.cursor_pos = post_shapes_draw_cursor_pos
		position   += shaped.end_cursor_pos
		last_shaped = shaped
	}
	}
	else {
	last_byte_offset : int = 0
	byte_offset      : int = 0
	for codepoint, offset in text_utf8
	{
		Rune_Space           :: ' '
		Rune_Tab             :: '\t'
		Rune_Carriage_Return :: '\r'
		Rune_Line_Feed       :: '\n'
		// Rune_Tab_Vertical :: '\v'

		byte_offset = offset

		switch codepoint
		{
			case Rune_Space: fallthrough
			case Rune_Tab: fallthrough
			case Rune_Line_Feed: fallthrough
			case Rune_Carriage_Return:
				if chunk_kind == .Formatting {
					chunk_end        = byte_offset
					last_byte_offset = byte_offset
				}
				else
				{
					text_chunk = transmute(string) text_utf8_bytes[ chunk_start : byte_offset]
					if len(text_chunk) > 0 {
						shaped := shape_text_cached( ctx, font, text_chunk )
						post_shapes_draw_cursor_pos += draw_text_shape( ctx, font, entry, shaped, position, scale, snap_width, snap_height )
						ctx.cursor_pos = post_shapes_draw_cursor_pos
						position   += shaped.end_cursor_pos
						last_shaped = shaped
					}

					chunk_start = byte_offset
					chunk_end   = chunk_start
					chunk_kind  = .Formatting

					last_byte_offset = byte_offset
					continue
				}
		}

		// Visible Chunk
		if chunk_kind == .Visible {
			chunk_end        = byte_offset
			last_byte_offset = byte_offset
		}
		else
		{
			text_chunk = transmute(string) text_utf8_bytes[ chunk_start : byte_offset ]
			if len(text_chunk) > 0 {
				shaped := shape_text_cached( ctx, font, text_chunk )
				post_shapes_draw_cursor_pos += draw_text_shape( ctx, font, entry, shaped, position, scale, snap_width, snap_height )
				ctx.cursor_pos = post_shapes_draw_cursor_pos
				position   += shaped.end_cursor_pos
				last_shaped = shaped
			}

			chunk_start = byte_offset
			chunk_end   = chunk_start
			chunk_kind  = .Visible

			last_byte_offset = byte_offset
		}
	}

	text_chunk = transmute(string) text_utf8_bytes[ chunk_start : byte_offset ]
	if len(text_chunk) > 0 {
		shaped := shape_text_cached( ctx, font, text_chunk )
		post_shapes_draw_cursor_pos += draw_text_shape( ctx, font, entry, shaped, position, scale, snap_width, snap_height )
		ctx.cursor_pos = post_shapes_draw_cursor_pos
		position   += shaped.end_cursor_pos
		last_shaped = shaped
	}

	chunk_start = byte_offset
	chunk_end   = chunk_start
	chunk_kind  = .Visible

	last_byte_offset = byte_offset

	ctx.cursor_pos = post_shapes_draw_cursor_pos
	}
	return true
}

draw_text_batch :: proc( ctx : ^Context, entry : ^Entry, shaped : ^ShapedText, batch_start_idx, batch_end_idx : i32, position, scale : Vec2 )
{
	flush_glyph_buffer_to_atlas( ctx )
	for index := batch_start_idx; index < batch_end_idx; index += 1
	{
		glyph_index       := shaped.glyphs.data[ index ]
		shaped_position   := shaped.positions.data[index]
		glyph_translate   := position + shaped_position * scale
		glyph_cached      := draw_cached_glyph( ctx, entry, glyph_index, glyph_translate, scale)
		assert( glyph_cached == true )
	}
}


// Helper for draw_text, all raw text content should be confirmed to be either formatting or visible shapes before getting cached.
draw_text_shape :: proc( ctx : ^Context, font : FontID, entry : ^Entry, shaped : ^ShapedText, position, scale : Vec2, snap_width, snap_height : f32 ) -> (cursor_pos : Vec2)
{
	batch_start_idx : i32 = 0
	for index : i32 = 0; index < i32(shaped.glyphs.num); index += 1
	{
		glyph_index := shaped.glyphs.data[ index ]
		if is_empty( ctx, entry, glyph_index )              do continue
		if can_batch_glyph( ctx, font, entry, glyph_index ) do continue

		// Glyph has not been catched, needs to be directly drawn.
		draw_text_batch( ctx, entry, shaped, batch_start_idx, index, position, scale )
		reset_batch_codepoint_state( ctx )

		cache_glyph_to_atlas( ctx, font, glyph_index )

		lru_code := font_glyph_lru_code(font, glyph_index)
		set( & ctx.temp_codepoint_seen, lru_code, true )
		ctx.temp_codepoint_seen_num += 1

		batch_start_idx = index
	}

	draw_text_batch( ctx, entry, shaped, batch_start_idx, i32(shaped.glyphs.num), position, scale )
	reset_batch_codepoint_state( ctx )
	cursor_pos = position + shaped.end_cursor_pos * scale
	return
}

// ve_fontcache_flush_drawlist
flush_draw_list :: proc( ctx : ^Context ) {
	assert( ctx != nil )
	clear_draw_list( & ctx.draw_list )
}

flush_glyph_buffer_to_atlas :: proc( ctx : ^Context )
{
	// Flush drawcalls to draw list
	merge_draw_list( & ctx.draw_list, & ctx.atlas.clear_draw_list )
	merge_draw_list( & ctx.draw_list, & ctx.atlas.draw_list)
	clear_draw_list( & ctx.atlas.draw_list )
	clear_draw_list( & ctx.atlas.clear_draw_list )

	// Clear glyph_update_FBO
	if ctx.atlas.update_batch_x != 0
	{
		call := DrawCall_Default
		call.pass = .Glyph
		call.start_index = 0
		call.end_index   = 0
		call.clear_before_draw = true

		append( & ctx.draw_list.calls, call )
		ctx.atlas.update_batch_x = 0
	}
}

// ve_fontcache_drawlist
get_draw_list :: proc( ctx : ^Context ) -> ^DrawList {
	assert( ctx != nil )
	return & ctx.draw_list
}

// TODO(Ed): See render.odin's render_text_layer, should provide the ability to get a slice of the draw list to render the latest layer
DrawListLayer :: struct {}
get_draw_list_layer :: proc() -> DrawListLayer { return {} }
flush_layer :: proc( draw_list : ^DrawList ) {}

// ve_fontcache_merge_drawlist
merge_draw_list :: proc( dst, src : ^DrawList )
{
	error : AllocatorError

	v_offset := cast(u32) dst.vertices.num
	for index : u32 = 0; index < cast(u32) src.vertices.num; index += 1 {
		error = append( & dst.vertices, src.vertices.data[index] )
		assert( error == .None )
	}
	// error = append( & dst.vertices, src.vertices )
	// assert( error == .None )

	i_offset := cast(u32) dst.indices.num
	for index : u32 = 0; index < cast(u32) src.indices.num; index += 1 {
		error = append( & dst.indices, src.indices.data[index] + v_offset )
		assert( error == .None )
	}

	for index : u32 = 0; index < cast(u32) src.calls.num; index += 1 {
		src_call := src.calls.data[ index ]
		src_call.start_index += i_offset
		src_call.end_index   += i_offset
		append( & dst.calls, src_call )
		assert( error == .None )
	}
}

optimize_draw_list :: proc( draw_list : ^DrawList, call_offset : u64 )
{
	assert( draw_list != nil )

	calls := array_to_slice(draw_list.calls)

	write_index : u64 = call_offset
	for index : u64 = 1 + call_offset; index < u64(draw_list.calls.num); index += 1
	{
		assert( write_index <= index )
		draw_0 := & draw_list.calls.data[ write_index ]
		draw_1 := & draw_list.calls.data[ index ]

		merge : b32 = true
		if draw_0.pass      != draw_1.pass        do merge = false
		if draw_0.end_index != draw_1.start_index do merge = false
		if draw_0.region    != draw_1.region      do merge = false
		if draw_1.clear_before_draw               do merge = false
		if draw_0.colour    != draw_1.colour      do merge = false

		if merge
		{
			// logf("merging %v : %v %v", draw_0.pass, write_index, index )
			draw_0.end_index   = draw_1.end_index
			draw_1.start_index = 0
			draw_1.end_index   = 0
		}
		else
		{
			// logf("can't merge %v : %v %v", draw_0.pass, write_index, index )
			write_index += 1
			if write_index != index {
				draw_2 := & draw_list.calls.data[ write_index ]
				draw_2^ = draw_1^
			}
		}
	}

	resize( & draw_list.calls, u64(write_index + 1) )
}
