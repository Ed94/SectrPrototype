package fontstash

import stbtt    "vendor:stb/truetype"
import freetype "thirdparty:freetype"

ParserKind :: enum u32 {
	stb_true_type,
	freetype,
}

ParserData :: struct #raw_union {
		stbtt_info : stbtt.fontinfo,
		// freetype_info :
}

ParserContext :: struct {
	ft_library : freetype.Library
}

//#region("freetype")

ft_init :: proc() -> i32 {
	using Module_Context
	return 1
}



//#endregion("freetype")

//#region("stb_truetype")

tt_init :: proc() -> i32 { return 1 }

tt_load_font :: proc( parser_data : ^ParserData, data : []byte ) -> b32
{
	parser_data.stbtt_info.userdata = Module_Context
	stb_error := stbtt.InitFont( & parser_data.stbtt_info, & data[0], 0 )
	return stb_error
}

tt_get_font_metrics :: proc( parser_data : ^ParserData, ascent, descent, line_gap : ^i32 ) {
	stbtt.GetFontVMetrics( & parser_data.stbtt_info, ascent, descent, line_gap )
}

tt_get_pixel_height_scale :: proc( parser_data : ^ParserData, size : f32 ) -> f32
{
	return stbtt.ScaleForPixelHeight( & parser_data.stbtt_info, size )
}

tt_get_glyph_index :: proc( parser_data : ^ParserData, codepoint : rune ) -> i32
{
	return stbtt.FindGlyphIndex( & parser_data.stbtt_info, codepoint )
}

tt_build_glyph_bitmap :: proc( parser_data : ^ParserData, glyph_index : i32,
	size, scale : f32, advance, left_side_bearing, x0, y0, x1, y1 : ^i32 ) -> i32
{
	stbtt.GetGlyphHMetrics( & parser_data.stbtt_info, glyph_index, advance, left_side_bearing )
	stbtt.GetGlyphBitmapBox( & parser_data.stbtt_info, glyph_index, scale, scale, x0, y0, x1, y1 )
	return 1
}

tt_render_glyph_bitmap :: proc( parser_data : ^ParserData, output : [^]byte,
	out_width, out_height, out_stride : i32, scale_x, scale_y : f32, glyph_index : i32 )
{
	stbtt.MakeGlyphBitmap( & parser_data.stbtt_info, output, out_width, out_height, out_stride, scale_x, scale_y, glyph_index )
}

tt_get_glyph_kern_advance :: proc( parser_data : ^ParserData, glyph_1, glyph_2 : i32 ) -> i32
{
	return stbtt.GetGlyphKernAdvance( & parser_data.stbtt_info, glyph_1, glyph_2 )
}

//#endregion("stb_truetype")
