/*
Yet another port of fontstash.

I decided t use this instead of the odin port as it already deviated from the original impl.
So The code was small enough that I mine as well learn it by porting for my use case.

Original copyright for fonstash.h:
------------------------------------------------------------------------------
 Copyright (c) 2009-2013 Mikko Mononen memon@inside.org

 This software is provided 'as-is', without any express or implied
 warranty.  In no event will the authors be held liable for any damages
 arising from the use of this software.
 Permission is granted to anyone to use this software for any purpose,
 including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 1. The origin of this software must not be misrepresented; you must not
	claim that you wrote the original software. If you use this software
	in a product, an acknowledgment in the product documentation would be
	appreciated but is not required.
 2. Altered source versions must be plainly marked as such, and must not be
	misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
------------------------------------------------------------------------------
*/
package sectr

import stbtt "vendor:stb/truetype"

Range2_i16 :: struct #raw_union {
	using pts : Vec2_i16,
	using xy  : struct {
		x0, y0, x1, y1 : i16,
	}
}

Vec2_i16 :: [2]i16

FSTASH_Invalid :: -1

FSTASH_Hash_Lut_Size    :: 256
FSTASH_Max_Fallbacks    :: 20
FSTASH_Max_States       :: 20
FSTASH_Vertex_Count     :: 1024
FSTASH_Init_Atlas_Nodes :: 256

FSTASH_FontLuts      :: [FSTASH_Hash_Lut_Size]i32
FSTASH_FontFallbacks :: [FSTASH_Max_Fallbacks]i32

FSTASH_HandleErrorProc :: #type proc( uptr : rawptr, error, val : i32 )

FSTASH_RenderCreateProc :: #type proc( uptr : rawptr, width, height : i32 )
FSTASH_RenderResizeProc :: #type proc( uptr : rawptr, width, height : i32 )
FSTASH_RenderUpdateProc :: #type proc( uptr : rawptr, rect : ^i32, data : ^u8 )
FSTASH_RenderDrawProc   :: #type proc( uptr : rawptr, verts : ^f32, tcoords : ^f32, colors : ^i32, num_verts : i32 )
FSTASH_RenderDelete     :: #type proc( uptr : rawptr )

FSTASH_AlignFlag :: enum u32  {
	Left,
	Center,
	Right,
	Top,
	Middle,
	Bottom,
	Baseline,
}
FSTASH_AlignFlags :: bit_set[ FSTASH_AlignFlag; u32 ]

// FONSflags
FSTASH_QuadLocation :: enum u32 {
	Top_Left    = 1,
	Bottom_Left = 2,
}

FSTASH_Atlas :: struct {
	dud : i32,
}

FSTASH_AtlasNode :: struct {
	x, y, width : i16,
}

FSTASH_ErrorCode :: enum u32 {
	Atlas_Full,
	Scratch_Full,
	States_Overflow,
	States_Underflow,
}

FSTASH_Quad :: struct {
	x0, y0, s0, t0 : f32,
	x1, y1, s1, t1 : f32,
}

FSTASH_Font :: struct {
	info      : stbtt.fontinfo,
	name      : string,
	data      : []byte,
	free_data : bool,

	ascender    : f32,
	descender   : f32,
	line_height : f32,

	glyphs        : Array(FSTASH_Glyph),
	lut           : FSTASH_FontLuts,
	fallbacks     : FSTASH_FontFallbacks,
	num_fallbacks : i32,
}

FSTASH_Glyph :: struct {
	codepoint   : rune,
	index, next : i32,
	size, blur  : i16,
	x_advance   : i16,
	box         : Range2_i16,
	offset      : Vec2_i16,
}

FSTASH_Params :: struct {
	width, height : i32,
	quad_location : FSTASH_QuadLocation, // (flags)
	render_create : FSTASH_RenderCreateProc,
	render_resize : FSTASH_RenderResizeProc,
	render_update : FSTASH_RenderUpdateProc,
	render_draw   : FSTASH_RenderDrawProc,
	render_delete : FSTASH_RenderDelete,
}

FSTASH_State :: struct {
	font      : i32,
	alignment : i32,
	size      : f32,
	color     : [4]u8,
	blur      : f32,
	spacing   : f32,
}

FSTASH_TextIter :: struct {
	x, y           : f32,
	next_x, next_y : f32,
	scale, spacing : f32,

	isize, iblur : i16,

	font : ^FSTASH_Font,
	prev_glyph_id : i32,

	codepoint  : rune,
	utf8_state : rune,

	str        : string,
	next       : string,
	end        : string,
}

FSTASH_Context :: struct {
	params : FSTASH_Params,

// Atlas
	atlas           : Array(FSTASH_AtlasNode),
	texture_data    : []byte,
	width, height   : i32,
// ----

	normalized_size : Vec2,

	verts   : [FSTASH_Vertex_Count * 2]f32,
	tcoords : [FSTASH_Vertex_Count * 2]f32,
	colors  : [FSTASH_Vertex_Count    ]f32,

	states  : [FSTASH_Max_States]FSTASH_State,
	num_states : i32,

	handle_error : FSTASH_HandleErrorProc,
	error_uptr : rawptr,
}

fstash_decode_utf8 :: proc( state : ^rune, codepoint : ^rune, to_decode : byte ) -> bool
{
	UTF8_Accept :: 0
	UTF8_Reject :: 1

	@static UTF8_Decode_Table := [?]u8 {
		// The first part of the table maps bytes to character classes that
		// to reduce the size of the transition table and create bitmasks.
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 00..1F
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 20..3F
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 40..5F
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,  // 60..7F
		1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,  9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,  // 80..9F
		7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,  // A0..BF
		8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,  // C0..DF
		10,3,3,3,3,3,3,3,3,3,3,3,3,4,3,3, 11,6,6,6,5,8,8,8,8,8,8,8,8,8,8,8, // E0..FF

		// The second part is a transition table that maps a combination
		// of a state of the automaton and a character class to a state.
		0,12,24,36,60,96,84,12,12,12,48,72, 12,12,12,12,12,12,12,12,12,12,12,12,
		12, 0,12,12,12,12,12, 0,12, 0,12,12, 12,24,12,12,12,12,12,24,12,24,12,12,
		12,12,12,12,12,12,12,24,12,12,12,12, 12,24,12,12,12,12,12,12,12,24,12,12,
		12,12,12,12,12,12,12,36,12,36,12,12, 12,36,12,12,12,12,12,36,12,36,12,12,
		12,36,12,12,12,12,12,12,12,12,12,12,
	}

	to_decode_rune := rune(to_decode)
	type           := UTF8_Decode_Table[to_decode_rune]

	// Update codepoint otherwise initialize it.
	(codepoint^) = ((state^) != UTF8_Accept) ?          \
			((to_decode_rune & 0x3F) | ((codepoint^) << 6)) \
		: ((0xFF >> type) & (to_decode_rune))

	(state^) = cast(rune)(UTF8_Decode_Table[256 + (state^) * 16 + rune(type)])
	return (state^) == UTF8_Accept
}

fstash_atlas_delete :: proc ( ctx : ^FSTASH_Context ) {
	using ctx
	array_free( ctx.atlas )
}

fstash_atlas_expand :: proc( ctx : ^FSTASH_Context, width, height : i32 )
{
	if width > ctx.width {
		fstash_atlas_insert( ctx, ctx.atlas.num, ctx.width, 0, width - ctx.width )
	}

	ctx.width  = width
	ctx.height = height
}

fstash_atlas_init :: proc( ctx : ^FSTASH_Context, width, height : i32, num_nodes : u32 = FSTASH_Init_Atlas_Nodes )
{
	error : AllocatorError
	ctx.atlas, error = array_init_reserve( FSTASH_AtlasNode, context.allocator, u64(num_nodes), dbg_name = "font atlas" )
	ensure(error != AllocatorError.None, "Failed to allocate font atlas")

	ctx.width  = width
	ctx.height = height

	array_append( & ctx.atlas, FSTASH_AtlasNode{ width = i16(width)} )
}

fstash_atlas_insert :: proc( ctx : ^FSTASH_Context, id : u64, x, y, width : i32 ) -> (error : AllocatorError)
{
	error = array_append_at( & ctx.atlas, FSTASH_AtlasNode{ i16(x), i16(y), i16(width) }, id )
	return
}

fstash_atlas_remove :: proc( ctx : ^FSTASH_Context, id : u64 )
{
	array_remove_at( ctx.atlas, id )
}

fstash_atlas_reset :: proc( ctx : ^FSTASH_Context, width, height : i32 )
{
	ctx.width  = width
	ctx.height = height
	array_clear( ctx.atlas )

	array_append( & ctx.atlas, FSTASH_AtlasNode{ width = i16(width)} )
}

fstash_atlas_add_skyline_level :: proc (ctx : ^FSTASH_Context, id : u64, x, y, width, height : i32 ) -> (error : AllocatorError)
{
	insert :: fstash_atlas_insert
	remove :: fstash_atlas_remove

	error = insert( ctx, id, x, y + height, width)
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

		remove(ctx, sky_id)
		sky_id -= 1
	}


	// Merge same height skyline segments that are next to each other.
	for sky_id := id; sky_id < ctx.atlas.num - 1;
	{
		curr := & ctx.atlas.data[sky_id    ]
		next := & ctx.atlas.data[sky_id + 1]

		if curr.y == next.y {
			curr.width += next.width
			remove(ctx, sky_id + 1)
		}
		else {
			sky_id += 1
		}
	}
	return
}

fstash_atlas_rect_fits :: proc( ctx : ^FSTASH_Context, location, width, height : i32 ) -> (max_height : i32)
{
	// Checks if there is enough space at the location of skyline span 'i',
	// and return the max height of all skyline spans under that at that location,
	// (think tetris block being dropped at that position). Or -1 if no space found.
	atlas := array_to_slice(ctx.atlas)
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

fstash_atlas_add_rect :: proc( ctx : ^FSTASH_Context, )
{
	
}
