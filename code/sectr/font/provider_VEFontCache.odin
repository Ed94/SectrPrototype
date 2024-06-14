package sectr

import "core:os"
import ve         "codebase:font/VEFontCache"
import sokol_gfx  "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"


Font_Provider_Use_Freetype :: false
Font_Largest_Px_Size       :: 72
Font_Size_Interval         :: 2

Font_Default            :: FontID { 0, "" }
Font_Default_Point_Size :: 18.0

Font_Load_Use_Default_Size :: -1
Font_Load_Gen_ID           :: ""

FontID  :: struct {
	key   : u64,
	label : string,
}

FontDef :: struct {
	path_file : string,
	ve_id     : ve.FontID,
}

FontProviderData :: struct
{
	ve_font_cache : ve.Context,
	font_cache    : HMapChained(FontDef),

	gfx_sampler : sokol_gfx.Sampler,

	draw_list_vbuf : sokol_gfx.Buffer,
	draw_list_ibuf : sokol_gfx.Buffer,

	glyph_shader  : sokol_gfx.Shader,
	atlas_shader  : sokol_gfx.Shader,
	screen_shader : sokol_gfx.Shader,

	// 2k x 512, R8
	glyph_rt_color   : sokol_gfx.Image,
	glyph_rt_depth   : sokol_gfx.Image,
	// glyph_rt_resolve : sokol_gfx.Image,

	// 4k x 2k, R8
	atlas_rt_color   : sokol_gfx.Image,
	atlas_rt_depth   : sokol_gfx.Image,
	// atlas_rt_resolve : sokol_gfx.Image,

	glyph_pipeline  : sokol_gfx.Pipeline,
	atlas_pipeline  : sokol_gfx.Pipeline,
	screen_pipeline : sokol_gfx.Pipeline,

	glyph_pass  : sokol_gfx.Pass,
	atlas_pass  : sokol_gfx.Pass,
	screen_pass : sokol_gfx.Pass,
}

font_provider_startup :: proc()
{
	profile(#procedure)
	state := get_state()

	provider_data := & state.font_provider_data; using provider_data

	error : AllocatorError
	font_cache, error = make( HMapChained(FontDef), hmap_closest_prime(1 * Kilo), persistent_allocator() /*dbg_name = "font_cache"*/ )
	verify( error == AllocatorError.None, "Failed to allocate font_cache" )

	ve.init( & provider_data.ve_font_cache, .STB_TrueType, allocator = persistent_slab_allocator() )
	log("VEFontCached initialized")

	ve.configure_snap( & provider_data.ve_font_cache, u32(state.app_window.extent.x * 2.0), u32(state.app_window.extent.y * 2.0) )

	provider_data.ve_font_cache.debug_print = true
	provider_data.ve_font_cache.debug_print_verbose = true

	
	// TODO(Ed): Setup sokol hookup for VEFontCache
	{
		AttachmentDesc          :: sokol_gfx.Attachment_Desc
		BlendFactor             :: sokol_gfx.Blend_Factor
		BlendOp                 :: sokol_gfx.Blend_Op
		BlendState              :: sokol_gfx.Blend_State
		BorderColor             :: sokol_gfx.Border_Color
		BufferDesciption        :: sokol_gfx.Buffer_Desc
		BufferUsage             :: sokol_gfx.Usage
		BufferType              :: sokol_gfx.Buffer_Type
		ColorTargetState        :: sokol_gfx.Color_Target_State
		Filter                  :: sokol_gfx.Filter
		ImageDesc               :: sokol_gfx.Image_Desc
		PassAction              :: sokol_gfx.Pass_Action
		Range                   :: sokol_gfx.Range
		ResourceState           :: sokol_gfx.Resource_State
		SamplerDescription      :: sokol_gfx.Sampler_Desc
		Wrap                    :: sokol_gfx.Wrap
		VertexAttributeState    :: sokol_gfx.Vertex_Attr_State
		VertexBufferLayoutState :: sokol_gfx.Vertex_Buffer_Layout_State
		VertexIndexType         :: sokol_gfx.Index_Type
		VertexFormat            :: sokol_gfx.Vertex_Format
		VertexLayoutState       :: sokol_gfx.Vertex_Layout_State
		VertexStep              :: sokol_gfx.Vertex_Step

		using provider_data
		backend := sokol_gfx.query_backend()
		app_env := sokol_glue.environment()

		glyph_shader  = sokol_gfx.make_shader(ve_render_glyph_shader_desc(backend) )
		atlas_shader  = sokol_gfx.make_shader(ve_blit_atlas_shader_desc(backend) )
		screen_shader = sokol_gfx.make_shader(ve_draw_text_shader_desc(backend) )

		draw_list_vbuf = sokol_gfx.make_buffer( BufferDesciption {
			size  = size_of([4]f32) * Kilo * 128,
			usage = BufferUsage.STREAM,
			type  = BufferType.VERTEXBUFFER,
		})
		verify( sokol_gfx.query_buffer_state( draw_list_vbuf) < ResourceState.FAILED, "Failed to make draw_list_vbuf" )

		draw_list_ibuf = sokol_gfx.make_buffer( BufferDesciption {
			size  = size_of(u32) * Kilo * 32,
			usage = BufferUsage.STREAM,
			type  = BufferType.INDEXBUFFER,
		})
		verify( sokol_gfx.query_buffer_state( draw_list_ibuf) < ResourceState.FAILED, "Failed to make draw_list_iubuf" )

		gfx_sampler = sokol_gfx.make_sampler( SamplerDescription {
			min_filter    = Filter.NEAREST,
			mag_filter    = Filter.NEAREST,
			mipmap_filter = Filter.NONE,
			wrap_u        = Wrap.CLAMP_TO_EDGE,
			wrap_v        = Wrap.CLAMP_TO_EDGE,
			border_color  = BorderColor.OPAQUE_BLACK,
		})
		verify( sokol_gfx.query_sampler_state( gfx_sampler) < ResourceState.FAILED, "Failed to make gfx_sampler" )

		// glyph_pipeline
		{
			vs_layout : VertexLayoutState
			{
				using vs_layout
				attrs[ATTR_ve_render_glyph_vs_v_position] = VertexAttributeState {
					format       = VertexFormat.FLOAT2,
					offset       = 0,
					buffer_index = 0,
				}
				attrs[ATTR_ve_render_glyph_vs_v_texture] = VertexAttributeState {
					format       = VertexFormat.FLOAT2,
					offset       = size_of(Vec2),
					buffer_index = 0,
				}
				buffers[0] = VertexBufferLayoutState {
					stride    = size_of(Vec2) * 2,
					step_func = VertexStep.PER_VERTEX
				}
			}

			color_target := ColorTargetState {
				pixel_format = .R8,
				// write_mask   =
				blend = BlendState {
					enabled = true,
					src_factor_rgb   = .ONE_MINUS_DST_COLOR,
					dst_factor_rgb   = .ONE_MINUS_SRC_COLOR,
					op_rgb           = BlendOp.ADD,
					src_factor_alpha = BlendFactor.ONE,
					dst_factor_alpha = BlendFactor.ZERO,
					op_alpha         = BlendOp.ADD,
				},
			}

			glyph_pipeline = sokol_gfx.make_pipeline({
				shader       = glyph_shader,
				layout       = vs_layout,
				index_type   = VertexIndexType.UINT32,
				colors       = {
					0 = color_target,
				},
				color_count  = 1,
				depth = {
					pixel_format = .DEPTH,
					// compare = .ALWAYS,
				},
				// sample_count = 1,
				// label =
			})
			verify( sokol_gfx.query_pipeline_state(glyph_pipeline) < ResourceState.FAILED, "Failed to make glyph_pipeline" )
		}

		// glyph_pass
		{
			glyph_rt_color = sokol_gfx.make_image( ImageDesc {
				type          = ._2D,
				render_target = true,
				width         = i32(ve_font_cache.atlas.buffer_width),
				height        = i32(ve_font_cache.atlas.buffer_height),
				num_slices    = 1,
				num_mipmaps   = 1,
				usage         = .IMMUTABLE,
				pixel_format  = .R8,
				sample_count  = app_env.defaults.sample_count,
				// TODO(Ed): Setup labels for debug tracing/logging
				// label         = 
			})
			verify( sokol_gfx.query_image_state(glyph_rt_color) < ResourceState.FAILED, "Failed to make glyph_pipeline" )

			glyph_rt_depth = sokol_gfx.make_image( ImageDesc {
				type          = ._2D,
				render_target = true,
				width         = i32(ve_font_cache.atlas.buffer_width),
				height        = i32(ve_font_cache.atlas.buffer_height),
				num_slices    = 1,
				num_mipmaps   = 1,
				usage         = .IMMUTABLE,
				pixel_format  = .DEPTH,
				sample_count  = app_env.defaults.sample_count,
			})

			color_attach := AttachmentDesc {
				image     = glyph_rt_color,
				// mip_level = 1,
			}

			glyph_attachments := sokol_gfx.make_attachments({
				colors = {
					0 = color_attach,
				},
				depth_stencil = {
					image = glyph_rt_depth,
				},
			})
			verify( sokol_gfx.query_attachments_state(glyph_attachments) < ResourceState.FAILED, "Failed to make glyph_attachments" )

			glyph_action := PassAction {
				colors = {
					0 = {
						load_action  = .CLEAR,
						store_action = .STORE,
						clear_value  = {0.01,0.01,0.01,1},
						// clear_value  = {0.00, 0.00, 0.00, 0.00},
					}
				}
			}

			glyph_pass = sokol_gfx.Pass {
				action      = glyph_action,
				attachments = glyph_attachments,
				// label =
			}
		}

		// atlas_pipeline
		{
			vs_layout : VertexLayoutState
			{
				using vs_layout
				attrs[ATTR_ve_blit_atlas_vs_v_position] = VertexAttributeState {
					format       = VertexFormat.FLOAT2,
					offset       = 0,
					buffer_index = 0,
				}
				attrs[ATTR_ve_blit_atlas_vs_v_texture] = VertexAttributeState {
					format       = VertexFormat.FLOAT2,
					offset       = size_of(Vec2),
					buffer_index = 0,
				}
				buffers[0] = VertexBufferLayoutState {
					stride    = size_of(Vec2) * 2,
					step_func = VertexStep.PER_VERTEX
				}
			}

			color_target := ColorTargetState {
				pixel_format = .R8,
				// write_mask   =
				blend = BlendState {
					enabled = true,
					src_factor_rgb   = .SRC_ALPHA,
					dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
					op_rgb           = BlendOp.ADD,
					src_factor_alpha = BlendFactor.ONE,
					dst_factor_alpha = BlendFactor.ZERO,
					op_alpha         = BlendOp.ADD,
				},
			}

			atlas_pipeline = sokol_gfx.make_pipeline({
				shader     = atlas_shader,
				layout     = vs_layout,
				index_type = VertexIndexType.UINT32,
				colors     = {
					0 = color_target,
				},
				color_count  = 1,
				depth = {
					pixel_format = .DEPTH,
					compare = .ALWAYS,
				},
				// sample_count = 1,
			})
		}

		// atlas_pass
		{
			atlas_rt_color = sokol_gfx.make_image( ImageDesc {
				type          = ._2D,
				render_target = true,
				width         = i32(ve_font_cache.atlas.buffer_width),
				height        = i32(ve_font_cache.atlas.buffer_height),
				num_slices    = 1,
				num_mipmaps   = 1,
				usage         = .IMMUTABLE,
				pixel_format  = .R8,
				sample_count  = app_env.defaults.sample_count,
				// TODO(Ed): Setup labels for debug tracing/logging
				// label         = 
			})
			verify( sokol_gfx.query_image_state(atlas_rt_color) < ResourceState.FAILED, "Failed to make atlas_rt_color")

			atlas_rt_depth = sokol_gfx.make_image( ImageDesc {
				type          = ._2D,
				render_target = true,
				width         = i32(ve_font_cache.atlas.buffer_width),
				height        = i32(ve_font_cache.atlas.buffer_height),
				num_slices    = 1,
				num_mipmaps   = 1,
				usage         = .IMMUTABLE,
				pixel_format  = .DEPTH,
				sample_count  = app_env.defaults.sample_count,
			})
			verify( sokol_gfx.query_image_state(atlas_rt_depth) < ResourceState.FAILED, "Failed to make atlas_rt_depth")

			color_attach := AttachmentDesc {
				image     = atlas_rt_color,
				// mip_level = 1,
			}

			atlas_attachments := sokol_gfx.make_attachments({
				colors = {
					0 = color_attach,
				},
				depth_stencil = {
					image = atlas_rt_depth,
				},
			})
			verify( sokol_gfx.query_attachments_state(atlas_attachments) < ResourceState.FAILED, "Failed to make atlas_attachments")

			atlas_action := PassAction {
				colors = {
					0 = {
						load_action  = .LOAD,
						store_action = .STORE,
						clear_value  = {0,0,0,1.0},
					}
				}
			}

			atlas_pass = sokol_gfx.Pass {
				action      = atlas_action,
				attachments = atlas_attachments,
				// label =
			}
		}

		// screen pipeline
		{
			vs_layout : VertexLayoutState
			{
				using vs_layout
				attrs[ATTR_ve_draw_text_vs_v_position] = VertexAttributeState {
					format       = VertexFormat.FLOAT2,
					offset       = 0,
					buffer_index = 0,
				}
				attrs[ATTR_ve_draw_text_vs_v_texture] = VertexAttributeState {
					format       = VertexFormat.FLOAT2,
					offset       = size_of(Vec2),
					buffer_index = 0,
				}
				buffers[0] = VertexBufferLayoutState {
					stride    = size_of(Vec2) * 2,
					step_func = VertexStep.PER_VERTEX
				}
			}

			color_target := ColorTargetState {
				// pixel_format = .R8,
				// write_mask   =
				blend = BlendState {
					enabled = true,
					src_factor_rgb   = .SRC_ALPHA,
					dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
					op_rgb           = BlendOp.ADD,
					src_factor_alpha = BlendFactor.ONE,
					dst_factor_alpha = BlendFactor.ZERO,
					op_alpha         = BlendOp.ADD,
				},
			}

			screen_pipeline = sokol_gfx.make_pipeline({
				shader     = screen_shader,
				layout     = vs_layout,
				index_type = VertexIndexType.UINT32,
				colors     = {
					0 = color_target,
				},
				color_count  = 1,
				sample_count = 1,
			})
			verify( sokol_gfx.query_pipeline_state(screen_pipeline) < ResourceState.FAILED, "Failed to make screen_pipeline" )
		}

		// screen_pass
		{
			screen_action := PassAction {
				colors = {
					0 = {
						load_action  = .CLEAR,
						store_action = .STORE,
						clear_value  = {1.0,0.0,0.0,1.0},
					}
				}
			}

			screen_pass = sokol_gfx.Pass {
				action = screen_action,
				// label =
			}
		}
	}
}

font_provider_reload :: proc()
{
	state         := get_state()
	provider_data := & state.font_provider_data

	ve.configure_snap( & provider_data.ve_font_cache, u32(state.app_window.extent.x * 2.0), u32(state.app_window.extent.y * 2.0) )
}

font_provider_shutdown :: proc()
{
	state := get_state()
	provider_data := state.font_provider_data; using provider_data

	ve.shutdown( & provider_data.ve_font_cache )
}

font_load :: proc(path_file : string,
	default_size : f32    = Font_Load_Use_Default_Size,
	desired_id   : string = Font_Load_Gen_ID
) -> FontID
{
	profile(#procedure)

	logf("Loading font: %v", path_file)
	provider_data := & get_state().font_provider_data; using provider_data

	font_data, read_succeded : = os.read_entire_file( path_file, persistent_allocator() )
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

	font_cache_watch := provider_data.font_cache

	key            := cast(u64) crc32( transmute([]byte) desired_id )
	def, set_error := hmap_chained_set(font_cache, key, FontDef{})
	verify( set_error == AllocatorError.None, "Failed to add new font entry to cache" )

	def.path_file = path_file

	// TODO(Ed): Load even sizes from 8px to upper bound.
	def.ve_id = ve.load_font( & provider_data.ve_font_cache, desired_id, font_data, 72.0 )

	fid := FontID { key, desired_id }
	return fid
}
