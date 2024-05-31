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
}

FontDef :: struct {
	path_file   : string,
	parser_info : FontParserFontData,
	glyphs      : [256]FontGlyph,
}

FontProviderData :: struct {
	font_cache    : HMapChained(FontDef),
	parser        : FontParserData,
	glyph_shader  : sokol_gfx.Shader,
	gfx_bindings  : sokol_gfx.Bindings,
	gfx_pipeline  : sokol_gfx.Pipeline,
	gfx_v_buffer  : sokol_gfx.Buffer,
	gfx_uv_buffer : sokol_gfx.Buffer,
	gfx_sampler   : sokol_gfx.Sampler,
}

Font_Quad_Vert_Size            :: size_of(Vec2) * 6
Font_Provider_Gfx_vBuffer_Size :: Font_Quad_Vert_Size * Kilo * 64

font_provider_startup :: proc()
{
	profile(#procedure)
	state := get_state()
	font_provider_data := & get_state().font_provider_data; using font_provider_data

	font_cache_alloc_error : AllocatorError
	font_cache, font_cache_alloc_error = make( HMapChained(FontDef), hmap_closest_prime(1 * Kilo), persistent_allocator() /*dbg_name = "font_cache"*/ )
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
		BlendFactor             :: sokol_gfx.Blend_Factor
		BlendOp                 :: sokol_gfx.Blend_Op
		BlendState              :: sokol_gfx.Blend_State
		BorderColor             :: sokol_gfx.Border_Color
		BufferDesciption        :: sokol_gfx.Buffer_Desc
		BufferUsage             :: sokol_gfx.Usage
		BufferType              :: sokol_gfx.Buffer_Type
		ColorTargetState        :: sokol_gfx.Color_Target_State
		Filter                  :: sokol_gfx.Filter
		Range                   :: sokol_gfx.Range
		SamplerDescription      :: sokol_gfx.Sampler_Desc
		Wrap                    :: sokol_gfx.Wrap
		VertexAttributeState    :: sokol_gfx.Vertex_Attr_State
		VertexBufferLayoutState :: sokol_gfx.Vertex_Buffer_Layout_State
		VertexIndexType         :: sokol_gfx.Index_Type
		VertexFormat            :: sokol_gfx.Vertex_Format
		VertexLayoutState       :: sokol_gfx.Vertex_Layout_State
		VertexStep              :: sokol_gfx.Vertex_Step

		using font_provider_data
		backend := sokol_gfx.query_backend()

		glyph_shader = sokol_gfx.make_shader(font_glyph_shader_desc(backend))

		// Glyphs append to a large vertex buffer that must be able to hold all verts per frame, the budget is fixed.
		// TODO(Ed): Add a way to relase and remake the buffer when an overflow is detected for a frame.
		gfx_v_buffer = sokol_gfx.make_buffer( BufferDesciption {
			size  = Font_Provider_Gfx_vBuffer_Size,
			usage = BufferUsage.DYNAMIC,
			type  = BufferType.VERTEXBUFFER,
		})
		verify( sokol_gfx.query_buffer_state(gfx_v_buffer) != sokol_gfx.Resource_State.INVALID,
			"Failed to make font provider's gfx_v_buffer" )

		uv_coords : [6]Vec2 = {
			0 = { 0.0, 0.0 },
			1 = { 0.0, 1.0 },
			2 = { 1.0, 1.0 },

			3 = { 0.0, 0.0 },
			4 = { 1.0, 1.0 },
			5 = { 1.0, 0.0 },
		}

		// All quads will use the same vertex buffer for texture coordinates.
		gfx_uv_buffer = sokol_gfx.make_buffer( BufferDesciption {
			size  = 0,
			usage = BufferUsage.IMMUTABLE,
			type  = BufferType.VERTEXBUFFER,
			data  = Range { & uv_coords[0], size_of(uv_coords) },
		})
		verify( sokol_gfx.query_buffer_state(gfx_uv_buffer) != sokol_gfx.Resource_State.INVALID,
			"Failed to make font provider's gfx_uv_buffer" )


		gfx_sampler = sokol_gfx.make_sampler( SamplerDescription {
			min_filter    = Filter.NEAREST,
			mag_filter    = Filter.NEAREST,
			mipmap_filter = Filter.NONE,
			wrap_u        = Wrap.CLAMP_TO_EDGE,
			wrap_v        = Wrap.CLAMP_TO_EDGE,
			border_color  = BorderColor.OPAQUE_BLACK,
		})

		glyph_vs_layout : VertexLayoutState
		{
			using glyph_vs_layout
			attrs[ATTR_font_glyph_vs_vertex] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = 0,
				buffer_index = ATTR_font_glyph_vs_vertex,
			}
			buffers[ATTR_font_glyph_vs_vertex] = VertexBufferLayoutState {
				stride    = size_of(Vec2),
				step_func = VertexStep.PER_VERTEX,
			}

			attrs[ATTR_font_glyph_vs_texture_coord] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = 0,
				buffer_index = ATTR_font_glyph_vs_texture_coord,
			}
			buffers[ATTR_font_glyph_vs_texture_coord] = VertexBufferLayoutState {
				stride    = size_of(Vec2),
				step_func = VertexStep.PER_VERTEX,
			}
		}

		gfx_pipeline = sokol_gfx.make_pipeline(
		{
			shader     = glyph_shader,
			layout     = glyph_vs_layout,
			index_type = VertexIndexType.NONE,
			colors = {
				0 = ColorTargetState \
				{
					blend = BlendState {
						enabled = true,
						src_factor_rgb   = BlendFactor.SRC_ALPHA,
						dst_factor_rgb   = BlendFactor.ONE_MINUS_SRC_ALPHA,
						op_rgb           = BlendOp.ADD,
						src_factor_alpha = BlendFactor.ONE,
						dst_factor_alpha = BlendFactor.ZERO,
						op_alpha         = BlendOp.ADD,
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

		// TODO(Ed): Free entry resources.
	}
}

when Font_Provider_Use_Freetype
{
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

		key            := cast(u64) crc32( transmute([]byte) desired_id )
		def, set_error := hmap_chained_set(font_cache, key, FontDef{})
		verify( set_error == AllocatorError.None, "Failed to add new font entry to cache" )

		def.path_file = path_file

		face_index :: 0
		freetype.new_memory_face( font_provider_data.parser.lib, raw_data(font_data), font_data_size, face_index, & def.parser_info.face )

		// Hardcoding to 24 pt for testing (until we have a proper cached atlas)
		freetype.set_pixel_sizes( def.parser_info.face, 0, 72 )

		for ascii_code in 0 ..< 128
		{
			load_error := freetype.load_char(def.parser_info.face, u32(ascii_code), {freetype.Load_Flag.Render})
			verify( load_error == .Ok, "Failed to load character using freetype" )

			// using def.parser_info
			using def
			// glyph  := parser_info.face.glyph
			// bitmap := & glyph.bitmap
			using parser_info.face.glyph

			codepoint := rune(ascii_code)
			if ! unicode.is_print(codepoint) || bitmap.width <= 0 do continue

			ImageDescription :: sokol_gfx.Image_Desc
			ImageUsage       :: sokol_gfx.Usage
			Range            :: sokol_gfx.Range
			PixelFormat      :: sokol_gfx.Pixel_Format

			glyph_data : sokol_gfx.Image_Data
			glyph_data.subimage[0][0] = Range { bitmap.buffer, u64(bitmap.width * bitmap.rows)	}

			desc := sokol_gfx.Image_Desc {
				type          = sokol_gfx.Image_Type._2D,
				render_target = false,
				width         = i32(bitmap.width),
				height        = i32(bitmap.rows),
				num_slices    = 1,
				num_mipmaps   = 1,
				usage         = ImageUsage.IMMUTABLE,
				pixel_format  = PixelFormat.R8,
				sample_count  = 0,
				data          = glyph_data,
				label         = strings.clone_to_cstring(str_fmt("font_ascii %v", ascii_code))
			}

			// width := i32(bitmap.width)
			// rows  := i32(bitmap.rows)
			// logf("font_ascii      : %v", ascii_code )
			// logf("font_ascii glyph: %v", rune(ascii_code) )

			sokol_img := sokol_gfx.make_image( desc )
			verify( sokol_gfx.query_image_state(sokol_img) != sokol_gfx.Resource_State.INVALID,
				"Failed to create image on sokol gfx" );

			def.glyphs[ascii_code] = FontGlyph {
				size     = { i32(bitmap.width), i32(bitmap.rows) },
				bearing  = { bitmap_left,  bitmap_top },
				texture  = sokol_img,
				advance  = u32(advance.x),
			}
		}

		freetype.done_face( def.parser_info.face )

		fid := FontID { key, desired_id }
		return fid
	}
}
