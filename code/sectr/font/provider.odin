package sectr

import "core:os"
import "core:strings"
import "core:unicode"
import sokol_gfx "thirdparty:sokol/gfx"
import "thirdparty:freetype"

Font_Provider_Use_Freetype :: true

Font_Largest_Px_Size :: 32

Font_Size_Interval :: 2

// Font_Default :: ""
Font_Default            :: FontID { 0, "" }
Font_Default_Point_Size :: 18.0

Font_TTF_Default_Chars_Padding :: 4

Font_Load_Use_Default_Size :: -1
Font_Load_Gen_ID           :: ""

Font_Atlas_Packing_Method :: enum u32 {
	Raylib_Basic  = 0, // Basic packing algo
	Skyeline_Rect = 1, // stb_pack_rect
}

FontID  :: struct {
	key   : u64,
	label : string,
}
FontTag :: struct {
	key        : FontID,
	point_size : f32
}

when Font_Provider_Use_Freetype
{
	FontParserFontData :: struct {
		using face : freetype.Face,
	}
	FontParserData :: struct {
		lib : freetype.Library,
	}
}

FontGlyph :: struct {
	size       : Vec2i,
	bearing    : Vec2i,
	advance    : u32,
	texture    : sokol_gfx.Image,
	bindings   : sokol_gfx.Bindings,
}

FontDef :: struct {
	path_file   : string,
	parser_info : FontParserFontData,
	glyphs      : [256]FontGlyph,
}

FontProviderData :: struct {
	font_cache   : HMapChainedPtr(FontDef),
	parser       : FontParserData,
	gfx_bindings : sokol_gfx.Bindings,
	gfx_pipeline : sokol_gfx.Pipeline,
	gfx_vbuffer  : sokol_gfx.Buffer,
	gfx_sampler  : sokol_gfx.Sampler,
}

Font_Provider_Ggfx_Buffer_Size :: 6 * 4 * size_of(f32) * Kilobyte * 32

font_provider_startup :: proc()
{
	profile(#procedure)
	state := get_state()
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_cache_alloc_error : AllocatorError
	font_cache, font_cache_alloc_error = hmap_chained_init(FontDef, hmap_closest_prime(1 * Kilo), persistent_allocator(), dbg_name = "font_cache" )
	verify( font_cache_alloc_error == AllocatorError.None, "Failed to allocate font_cache" )

	log("font_cache created")

	when Font_Provider_Use_Freetype
	{
		result := freetype.init_free_type( & font_provider_data.parser.lib )
		if result != freetype.Error.Ok {
			fatal( "font_provider_setup: Failed to initialize freetype" )
		}
	}

	// Setup Graphics Pipeline
	{
		using font_provider_data
		backend := sokol_gfx.query_backend()
		learngl_font_glyph_shader := sokol_gfx.make_shader(learngl_font_glyph_shader_desc(backend))

		gfx_vbuffer = sokol_gfx.make_buffer( sokol_gfx.Buffer_Desc {
			size  = Font_Provider_Ggfx_Buffer_Size, // (6 verts, 4 f32 each) * 32 kilos
			usage = sokol_gfx.Usage.DYNAMIC,
			type  = sokol_gfx.Buffer_Type.VERTEXBUFFER,
		})

		gfx_sampler = sokol_gfx.make_sampler( sokol_gfx.Sampler_Desc {
			min_filter    = sokol_gfx.Filter.LINEAR,
			mag_filter    = sokol_gfx.Filter.LINEAR,
			mipmap_filter = sokol_gfx.Filter.NONE,
			wrap_u        = sokol_gfx.Wrap.CLAMP_TO_EDGE,
			wrap_v        = sokol_gfx.Wrap.CLAMP_TO_EDGE,
			// min_lod       = 1.0,
			// max_lod       = 1.0,
			border_color  = sokol_gfx.Border_Color.OPAQUE_BLACK,
		})

		glyph_vs_layout : sokol_gfx.Vertex_Layout_State
		glyph_vs_layout.attrs[ATTR_glyph_vs_vertex] = sokol_gfx.Vertex_Attr_State {
			format = sokol_gfx.Vertex_Format.FLOAT4,
			offset = 0,
		}
		glyph_vs_layout.buffers[0] = sokol_gfx.Vertex_Buffer_Layout_State {
			stride = size_of(f32) * 4, // Total stride ( pos2 + tex2 )
			step_func = sokol_gfx.Vertex_Step.PER_VERTEX,
		}

		gfx_pipeline = sokol_gfx.make_pipeline(
		{
			shader = learngl_font_glyph_shader,
			layout = glyph_vs_layout,
			colors ={
				0 = sokol_gfx.Color_Target_State \
				{
					// pixel_format = sokol_gfx.Pixel_Format.R8,
					// write_mask   = sokol_gfx.Color_Mask.R,
					blend = sokol_gfx.Blend_State {
						enabled = true,
						src_factor_rgb   = sokol_gfx.Blend_Factor.SRC_ALPHA,
						dst_factor_rgb   = sokol_gfx.Blend_Factor.ONE_MINUS_SRC_ALPHA,
						// op_rgb           = sokol_gfx.Blend_Op.ADD,

						src_factor_alpha= sokol_gfx.Blend_Factor.ONE,
						dst_factor_alpha = sokol_gfx.Blend_Factor.ZERO,
						// src_factor_alpha = sokol_gfx.Blend_Factor.ONE,
						// dst_factor_alpha = sokol_gfx.Blend_Factor.ZERO,
						// op_alpha         = sokol_gfx.Blend_Op.DEFAULT,
					}
				},
			},
			color_count  = 1,
			sample_count = 1,
		})
	}

	log("font_provider initialized")
}

font_provider_shutdown :: proc()
{
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	for & entry in font_cache.lookup
	{
		if entry == nil do continue

		def := entry.value
		// for & px_render in def.size_table {
		// 	using px_render
			// rl.UnloadFontData( glyphs, count )
			// rl.UnloadTexture ( texture )
			// rl.MemFree( recs )
		// }
	}
}

font_load :: proc(path_file : string,
	default_size : f32    = Font_Load_Use_Default_Size,
	desired_id   : string = Font_Load_Gen_ID
) -> FontID
{
	profile(#procedure)

	logf("Loading font: %v", path_file)
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_data, read_succeded : = os.read_entire_file( path_file )
	verify( b32(read_succeded), str_fmt("Failed to read font file for: %v", path_file) )
	font_data_size := cast(i32) len(font_data)

	desired_id := desired_id
	// Use file name as key
	if len(desired_id) == 0 {
		// NOTE(Ed): This should never be used except for laziness so I'll be throwing a warning everytime.
		log("desired_key not provided, using file name. Give it a proper name!", LogLevel.Warning)
		// desired_id = cast(FontID) file_name_from_path(path_file)
		desired_id = file_name_from_path(path_file)
	}

	// default_size := default_size
	// if default_size == Font_Load_Use_Default_Size {
	// 	default_size = Font_Default_Point_Size
	// }

	key            := cast(u64) crc32( transmute([]byte) desired_id )
	def, set_error := hmap_chained_set(font_cache, key, FontDef{})
	verify( set_error == AllocatorError.None, "Failed to add new font entry to cache" )

	def.path_file = path_file
	// def.default_size = i32(points_to_pixels(default_size))

	face_index :: 0
	freetype.new_memory_face( font_provider_data.parser.lib, raw_data(font_data), cast(i32) len(font_data), face_index, & def.parser_info.face )

	// Hardcoding to 24 pt for testing (until we have a proper cached atlas)
	freetype.set_pixel_sizes( def.parser_info.face, 0, 72 )

	for ascii_code in 0 ..< 128 {
		load_error := freetype.load_char(def.parser_info.face, u32(ascii_code), {freetype.Load_Flag.Render})
		verify( load_error == .Ok, "Failed to load character using freetype" )

		using def.parser_info

		codepoint := rune(ascii_code)

		if ! unicode.is_print(codepoint) || face.glyph.bitmap.width <= 0 {
			continue;
		}

		glyph_data : sokol_gfx.Image_Data
		glyph_data.subimage[0][0] = sokol_gfx.Range {
			face.glyph.bitmap.buffer,
			u64(face.glyph.bitmap.width * face.glyph.bitmap.rows)
		}
		desc := sokol_gfx.Image_Desc {
			type          = sokol_gfx.Image_Type._2D,
			render_target = false,
			width         = i32(face.glyph.bitmap.width),
			height        = i32(face.glyph.bitmap.rows),
			num_slices    = 1,
			num_mipmaps   = 1,
			usage         = sokol_gfx.Usage.IMMUTABLE,
			pixel_format  = sokol_gfx.Pixel_Format.R8,
			sample_count  = 0,
			data          = glyph_data,
			label         = strings.clone_to_cstring(str_fmt("font_ascii %v", ascii_code))
		}
		width := i32(face.glyph.bitmap.width)
		rows  := i32(face.glyph.bitmap.rows)
		logf("font_ascii      : %v", ascii_code )
		logf("font_ascii glyph: %v", rune(ascii_code) )
		rhi_img := sokol_gfx.make_image( desc )
		verify( sokol_gfx.query_image_state(rhi_img) != sokol_gfx.Resource_State.INVALID,
			"Failed to create image on sokol gfx" );

		def_bindings := sokol_gfx.Bindings {
			vertex_buffers = { ATTR_glyph_vs_vertex = gfx_vbuffer, },
			fs             = {
				images   = { SLOT_glyph_bitmap         = rhi_img, },
				samplers = { SLOT_glyph_bitmap_sampler = gfx_sampler }
			},
		}

		def.glyphs[ascii_code] = FontGlyph {
			size     = { i32(face.glyph.bitmap.width), i32(face.glyph.bitmap.rows) },
			bearing  = { face.glyph.bitmap_left,  face.glyph.bitmap_top },
			texture  = rhi_img,
			bindings = def_bindings,
			advance  = u32(face.glyph.advance.x),
		}
	}

	fid := FontID { key, desired_id }
	return fid
}
