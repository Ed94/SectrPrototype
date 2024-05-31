/*
Yet another port of fontstash.

I decided to use this instead of the odin port as it deviated from the original, making it difficult to sift through.
So The code was small enough that I mine as well learn it by porting for my use case.

TODO(Ed): Add docs here and throughout
TODO(Ed): This is unfinished...

Original author's copyright for fonstash.h:
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
package fontstash

Range2_i16 :: struct #raw_union {
	using pts : Vec2_i16,
	using xy  : struct {
		x0, y0, x1, y1 : i16,
	}
}

Vec2     :: [2]f32
Vec2_i16 :: [2]i16
Rect     :: [4]f32

Invalid :: -1

Hash_Lut_Size    :: 256
Max_Fallbacks    :: 20
Max_VisStates    :: 20
Vertex_Count     :: 1024
Init_Atlas_Nodes :: 256

FontLuts      :: [Hash_Lut_Size]i32
FontFallbacks :: [Max_Fallbacks]i32

HandleErrorProc :: #type proc( uptr : rawptr, error, val : i32 )

RenderCreateProc :: #type proc( uptr : rawptr, width, height : i32 )
RenderResizeProc :: #type proc( uptr : rawptr, width, height : i32 )
RenderUpdateProc :: #type proc( uptr : rawptr, rect : ^i32, data : ^u8 )
RenderDrawProc   :: #type proc( uptr : rawptr, verts : ^f32, tcoords : ^f32, colors : ^i32, num_verts : i32 )
RenderDelete     :: #type proc( uptr : rawptr )

AlignFlag :: enum u32  {
	Left,
	Center,
	Right,
	Top,
	Middle,
	Bottom,
	Baseline,
}
AlignFlags :: bit_set[ AlignFlag; u32 ]

// FONSflags
QuadLocation :: enum u32 {
	Top_Left    = 1,
	Bottom_Left = 2,
}

Atlas :: struct {
	dud : i32,
}

AtlasNode :: struct {
	x, y, width : i16,
}

ErrorCode :: enum u32 {
	Atlas_Full,
	Scratch_Full,
	States_Overflow,
	States_Underflow,
}

Quad :: struct {
	x0, y0, s0, t0 : f32,
	x1, y1, s1, t1 : f32,
}

Glyph :: struct {
	codepoint   : rune,
	index, next : i32,
	size, blur  : i16,
	x_advance   : i16,
	box         : Range2_i16,
	offset      : Vec2_i16,
}

Font :: struct {
	parser_data : ParserData,
	name        : string,
	data        : []byte,
	free_data   : bool,

	ascender    : f32,
	descender   : f32,
	line_height : f32,

	glyphs        : Array(Glyph),
	lut           : FontLuts,
	fallbacks     : FontFallbacks,
	num_fallbacks : i32,
}

// Visible State tracking used for sharing font visualization preferences.
VisState :: struct {
	font      : i32,
	alignment : i32,
	size      : f32,
	color     : [4]u8,
	blur      : f32,
	spacing   : f32,
}

TextIter :: struct {
	x, y           : f32,
	next_x, next_y : f32,
	scale, spacing : f32,

	isize, iblur : i16,

	font : ^Font,
	prev_glyph_id : i32,

	codepoint  : rune,
	utf8_state : rune,

	str        : string,
	next       : string,
	end        : string,
}

decode_utf8 :: proc( state : ^rune, codepoint : ^rune, to_decode : byte ) -> bool
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
