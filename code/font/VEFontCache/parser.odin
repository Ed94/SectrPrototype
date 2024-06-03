package VEFontCache

/*
Notes:

Freetype will do memory allocations and has an interface the user can implement.
That interface is not exposed from this parser but could be added to parser_init.
*/

import "core:c"
import stbtt    "vendor:stb/truetype"
import freetype "thirdparty:freetype"

ParserKind :: enum u32 {
	STB_TrueType,
	Freetype,
}

ParserFontInfo :: struct {
	label : string,
	kind  : ParserKind,
	using _ : struct #raw_union {
		stbtt_info    : stbtt.fontinfo,
		freetype_info : freetype.Face
	}
}

// Based directly off of stb_truetype's vertex
ParserGlyphVertex :: struct {
	x,          y          : u16,
	contour_x0, contour_y0 : u16,
	contour_x1, contour_y1 : u16,
	type,       padding    : u8,
}
ParserGlyphShape :: []ParserGlyphVertex

ParserContext :: struct {
	kind       : ParserKind,
	ft_library : freetype.Library,

	fonts : HMapChained(ParserFontInfo),
}

parser_init :: proc( ctx : ^ParserContext )
{
	switch ctx.kind
	{
		case .Freetype:
			result := freetype.init_free_type( & ctx.ft_library )
			assert( result == freetype.Error.Ok, "VEFontCache.parser_init: Failed to initialize freetype" )

		case .STB_TrueType:
			// Do nothing intentional
	}

	error : AllocatorError
	ctx.fonts, error = make( HMapChained(ParserFontInfo), 256 )
	assert( error == .None, "VEFontCache.parser_init: Failed to allocate fonts array" )
}

parser_load_font :: proc( ctx : ParserContext, label : string, data : []byte ) -> (font : ^ParserFontInfo)
{
	key  := font_key_from_label(label)
	font  = get( ctx.fonts, key )
	if font != nil do return

	error : AllocatorError
	font, error = set( ctx.fonts, key, ParserFontInfo {} )
	assert( error != .None, "VEFontCache.parser_load_font: Failed to set a new parser font info" )
	switch ctx.kind
	{
		case .Freetype:
			error := freetype.new_memory_face( ctx.ft_library, raw_data(data), cast(i32) len(data), 0, & font.freetype_info )
			if error != .Ok do return

		case .STB_TrueType:
			success := stbtt.InitFont( & font.stbtt_info, raw_data(data), 0 )
			if ! success do return
	}

	font.label = label
	return
}

parser_unload_font :: proc( font : ^ParserFontInfo )
{
	switch font.kind {
		case .Freetype:
			error := freetype.done_face( font.freetype_info )
			assert( error == .Ok, "VEFontCache.parser_unload_font: Failed to unload freetype face" )

		case .STB_TrueType:
			// Do Nothing
	}
}

parser_scale_for_pixel_height :: #force_inline proc( font : ^ParserFontInfo, size : f32 ) -> f32
{
	switch font.kind {
		case .Freetype:
			freetype.set_pixel_sizes( font.freetype_info, 0, cast(u32) size )
			size_scale := size / cast(f32)font.freetype_info.units_per_em
			return size_scale

		case.STB_TrueType:
			return stbtt.ScaleForPixelHeight( & font.stbtt_info, size )
	}
	return 0
}

parser_scale_for_mapping_em_to_pixels :: proc( font : ^ParserFontInfo, size : f32 ) -> f32
{
	switch font.kind {
		case .Freetype:
			Inches_To_CM  :: cast(f32) 2.54
			Points_Per_CM :: cast(f32) 28.3465
			CM_Per_Point  :: cast(f32) 1.0 / DPT_DPCM
			CM_Per_Pixel  :: cast(f32) 1.0 / DPT_PPCM
			DPT_DPCM      :: cast(f32) 72.0 * Inches_To_CM // 182.88 points/dots per cm
			DPT_PPCM      :: cast(f32) 96.0 * Inches_To_CM // 243.84 pixels per cm
			DPT_DPI       :: cast(f32) 72.0

			// TODO(Ed): Don't assume the dots or pixels per inch.
			system_dpi :: DPT_DPI

			FT_Font_Size_Point_Unit :: 1.0 / 64.0
			FT_Point_10             :: 64.0

			points_per_em := (size / system_dpi ) * DPT_DPI
			freetype.set_char_size( font.freetype_info, 0, cast(freetype.F26Dot6) (f32(points_per_em) * FT_Point_10), cast(u32) DPT_DPI, cast(u32) DPT_DPI )
			size_scale := size / cast(f32) font.freetype_info.units_per_em;
			return size_scale

		case .STB_TrueType:
			return stbtt.ScaleForMappingEmToPixels( & font.stbtt_info, size )
	}
	return 0
}

parser_is_glyph_empty :: proc( font : ^ParserFontInfo, glyph_index : Glyph ) -> b32
{
	switch font.kind
	{
		case .Freetype:
			error := freetype.load_glyph( font.freetype_info, cast(u32) glyph_index, { .No_Bitmap, .No_Hinting, .No_Scale } )
			if error == .Ok
			{
				if font.freetype_info.glyph.format == .Outline {
					return font.freetype_info.glyph.outline.n_points == 0
				}
				else if font.freetype_info.glyph.format == .Bitmap {
					return font.freetype_info.glyph.bitmap.width == 0 && font.freetype_info.glyph.bitmap.rows == 0;
				}
			}
			return false

		case .STB_TrueType:
			return stbtt.IsGlyphEmpty( & font.stbtt_info, cast(c.int) glyph_index )
	}
	return false
}

// TODO(Ed): This makes freetype second class I guess but VEFontCache doesn't have native support for freetype originally so....
// parser_convert_freetype_outline_to_stb_truetype_shape :: proc( outline : freetype.Outline ) -> (shape : ParserGlyphShape, error : AllocatorError)
// {

// }

parser_get_glyph_shape :: proc( font : ^ParserFontInfo, glyph_index : Glyph ) -> (shape : ParserGlyphShape, error : AllocatorError)
{
	switch font.kind
	{
		case .Freetype:
			error := freetype.load_glyph( font.freetype_info, cast(u32) glyph_index, { .No_Bitmap, .No_Hinting, .No_Scale } )
			if error != .Ok {
				return
			}

			glyph := font.freetype_info.glyph
			if glyph.format != .Outline {
				return
			}

			/*
			convert freetype outline to stb_truetype shape

			freetype docs: https://freetype.org/freetype2/docs/glyphs/glyphs-6.html

			stb_truetype shape info:
			The shape is a series of contours. Each one starts with
			a STBTT_moveto, then consists of a series of mixed
			STBTT_lineto and STBTT_curveto segments. A lineto
			draws a line from previous endpoint to its x,y; a curveto
			draws a quadratic bezier from previous endpoint to
			its x,y, using cx,cy as the bezier control point.
			*/
			{
				FT_CURVE_TAG_CONIC :: 0x00
				FT_CURVE_TAG_ON    :: 0x01
				FT_CURVE_TAG_CUBIC :: 0x02

				// TODO(Ed): This makes freetype second class I guess but VEFontCache doesn't have native support for freetype originally so....
				outline := & glyph.outline

				contours := transmute([^]i16) outline.contours
				for contour : i32 = 0; contour < i32(outline.n_contours); contour += 1
				{
					start_point := (contour == 0) ? 0 : i32( contours[contour - 1] + 1)
					end_point   := i32(contours[contour])

					for index := start_point; index < end_point; index += 1
					{
						points := transmute( [^]freetype.Vector) outline.points
						tags   := transmute( [^]u8) outline.tags

						point := points[index]
						tag   := tags[index]

						next_index := (index == end_point) ? start_point : index + 1
						next_point := points[next_index]
						next_tag   := tags[index]

						if (tag & FT_CURVE_TAG_CONIC) > 0 {

						}
					}
				}
			}

		case .STB_TrueType:
			stb_shape : [^]stbtt.vertex
			nverts    := stbtt.GetGlyphShape( & font.stbtt_info, cast(i32) glyph_index, & stb_shape )
			if nverts == 0 || shape == nil {
				shape = transmute(ParserGlyphShape) stb_shape[0:0]
			}
			shape = transmute(ParserGlyphShape) stb_shape[:nverts]
			error = AllocatorError.None
			return
	}

	return
}

parser_free_shape :: proc( font : ^ParserFontInfo, shape : ParserGlyphShape )
{
	// switch font.kind
	// {
	// 	case .Freetype
	// }
}
