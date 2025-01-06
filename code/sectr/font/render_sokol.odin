package sectr

import ve         "codebase:font/VEFontCache"
import sokol_gfx  "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"

VE_RenderData :: struct {
	draw_list_vbuf : sokol_gfx.Buffer,
	draw_list_ibuf : sokol_gfx.Buffer,

	glyph_shader  : sokol_gfx.Shader,
	atlas_shader  : sokol_gfx.Shader,
	screen_shader : sokol_gfx.Shader,

	// 2k x 512, R8
	glyph_rt_color   : sokol_gfx.Image,
	glyph_rt_depth   : sokol_gfx.Image,
	// glyph_rt_resolve : sokol_gfx.Image,
	glyph_rt_sampler : sokol_gfx.Sampler,

	// 4k x 2k, R8
	atlas_rt_color   : sokol_gfx.Image,
	atlas_rt_depth   : sokol_gfx.Image,
	// atlas_rt_resolve : sokol_gfx.Image,
	atlas_rt_sampler : sokol_gfx.Sampler,

	glyph_pipeline  : sokol_gfx.Pipeline,
	atlas_pipeline  : sokol_gfx.Pipeline,
	screen_pipeline : sokol_gfx.Pipeline,

	glyph_pass  : sokol_gfx.Pass,
	atlas_pass  : sokol_gfx.Pass,
	screen_pass : sokol_gfx.Pass,
}

font_provider_setup_sokol_gfx_objects :: proc( ctx : ^VE_RenderData, ve_ctx : ve.Context )
{
	using ctx
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

	backend := sokol_gfx.query_backend()
	app_env := sokol_glue.environment()

	glyph_shader  = sokol_gfx.make_shader(ve_render_glyph_shader_desc(backend) )
	atlas_shader  = sokol_gfx.make_shader(ve_blit_atlas_shader_desc(backend) )
	screen_shader = sokol_gfx.make_shader(ve_draw_text_shader_desc(backend) )

	draw_list_vbuf = sokol_gfx.make_buffer( BufferDesciption {
		size  = size_of([4]f32) * 2 * Mega,
		usage = BufferUsage.STREAM,
		type  = BufferType.VERTEXBUFFER,
	})
	verify( sokol_gfx.query_buffer_state( draw_list_vbuf) < ResourceState.FAILED, "Failed to make draw_list_vbuf" )

	draw_list_ibuf = sokol_gfx.make_buffer( BufferDesciption {
		size  = size_of(u32) * 1 * Mega,
		usage = BufferUsage.STREAM,
		type  = BufferType.INDEXBUFFER,
	})
	verify( sokol_gfx.query_buffer_state( draw_list_ibuf) < ResourceState.FAILED, "Failed to make draw_list_iubuf" )

	Image_Filter := Filter.LINEAR

	// glyph_pipeline
	{
		vs_layout : VertexLayoutState
		{
			using vs_layout
			attrs[ATTR_ve_render_glyph_v_position] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = 0,
				buffer_index = 0,
			}
			attrs[ATTR_ve_render_glyph_v_texture] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = size_of(Vec2),
				buffer_index = 0,
			}
			buffers[0] = VertexBufferLayoutState {
				stride    = size_of([4]f32),
				step_func = VertexStep.PER_VERTEX
			}
		}

		color_target := ColorTargetState {
			pixel_format = .R8,
			write_mask   = .RGBA,
			blend = BlendState {
				enabled          = true,
				src_factor_rgb   = .ONE_MINUS_DST_COLOR,
				dst_factor_rgb   = .ONE_MINUS_SRC_COLOR,
				op_rgb           = BlendOp.ADD,
				src_factor_alpha = .ONE_MINUS_DST_ALPHA,
				dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
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
				pixel_format  = .DEPTH,
				compare       = .ALWAYS,
				write_enabled = false,
			},
			cull_mode    = .NONE,
			sample_count = 1,
			// label =
		})
		verify( sokol_gfx.query_pipeline_state(glyph_pipeline) < ResourceState.FAILED, "Failed to make glyph_pipeline" )
	}

	// glyph_pass
	{
		glyph_rt_color = sokol_gfx.make_image( ImageDesc {
			type          = ._2D,
			render_target = true,
			width         = i32(ve_ctx.glyph_buffer.width),
			height        = i32(ve_ctx.glyph_buffer.height),
			num_slices    = 1,
			num_mipmaps   = 1,
			usage         = .IMMUTABLE,
			pixel_format  = .R8,
			sample_count  = 1,
			// TODO(Ed): Setup labels for debug tracing/logging
			// label         = 
		})
		verify( sokol_gfx.query_image_state(glyph_rt_color) < ResourceState.FAILED, "Failed to make glyph_pipeline" )

		glyph_rt_depth = sokol_gfx.make_image( ImageDesc {
			type          = ._2D,
			render_target = true,
			width         = i32(ve_ctx.glyph_buffer.width),
			height        = i32(ve_ctx.glyph_buffer.height),
			num_slices    = 1,
			num_mipmaps   = 1,
			usage         = .IMMUTABLE,
			pixel_format  = .DEPTH,
			sample_count  = 1,
		})

		glyph_rt_sampler = sokol_gfx.make_sampler( SamplerDescription {
			min_filter     = Image_Filter,
			mag_filter     = Image_Filter,
			mipmap_filter  = Filter.NEAREST,
			wrap_u         = .CLAMP_TO_EDGE,
			wrap_v         = .CLAMP_TO_EDGE,
			min_lod        = -1.0,
			max_lod        =  1.0,
			border_color   = BorderColor.OPAQUE_BLACK,
			compare        = .NEVER,
			max_anisotropy = 1,
		})
		verify( sokol_gfx.query_sampler_state( glyph_rt_sampler) < ResourceState.FAILED, "Failed to make atlas_rt_sampler" )

		color_attach := AttachmentDesc {
			image = glyph_rt_color,
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
					load_action  = .LOAD,
					store_action = .STORE,
					clear_value  = {0.00, 0.00, 0.00, 1.00},
				}
			},
			depth = {
				load_action  = .DONTCARE,
				store_action = .DONTCARE,
				clear_value  = 0.0,
			},
			stencil = {
				load_action  = .DONTCARE,
				store_action = .DONTCARE,
				clear_value  = 0,
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
			attrs[ATTR_ve_blit_atlas_v_position] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = 0,
				buffer_index = 0,
			}
			attrs[ATTR_ve_blit_atlas_v_texture] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = size_of(Vec2),
				buffer_index = 0,
			}
			buffers[0] = VertexBufferLayoutState {
				stride    = size_of([4]f32),
				step_func = VertexStep.PER_VERTEX
			}
		}

		color_target := ColorTargetState {
			pixel_format = .R8,
			write_mask   = .RGBA,
			blend = BlendState {
				enabled          = true,
				src_factor_rgb   = .SRC_ALPHA,
				dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
				op_rgb           = BlendOp.ADD,
				src_factor_alpha = .SRC_ALPHA,
				dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
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
				pixel_format  = .DEPTH,
				compare       = .ALWAYS,
				write_enabled = false,
			},
			cull_mode    = .NONE,
			sample_count = 1,
		})
	}

	// atlas_pass
	{
		atlas_rt_color = sokol_gfx.make_image( ImageDesc {
			type          = ._2D,
			render_target = true,
			width         = i32(ve_ctx.atlas.width),
			height        = i32(ve_ctx.atlas.height),
			num_slices    = 1,
			num_mipmaps   = 1,
			usage         = .IMMUTABLE,
			pixel_format  = .R8,
			sample_count  = 1,
			// TODO(Ed): Setup labels for debug tracing/logging
			// label         = 
		})
		verify( sokol_gfx.query_image_state(atlas_rt_color) < ResourceState.FAILED, "Failed to make atlas_rt_color")

		atlas_rt_depth = sokol_gfx.make_image( ImageDesc {
			type          = ._2D,
			render_target = true,
			width         = i32(ve_ctx.atlas.width),
			height        = i32(ve_ctx.atlas.height),
			num_slices    = 1,
			num_mipmaps   = 1,
			usage         = .IMMUTABLE,
			pixel_format  = .DEPTH,
			sample_count  = 1,
		})
		verify( sokol_gfx.query_image_state(atlas_rt_depth) < ResourceState.FAILED, "Failed to make atlas_rt_depth")

		atlas_rt_sampler = sokol_gfx.make_sampler( SamplerDescription {
			min_filter     = Image_Filter,
			mag_filter     = Image_Filter,
			mipmap_filter  = Filter.NEAREST,
			wrap_u         = .CLAMP_TO_EDGE,
			wrap_v         = .CLAMP_TO_EDGE,
			min_lod        = -1.0,
			max_lod        =  1.0,
			border_color   = BorderColor.OPAQUE_BLACK,
			compare        = .NEVER,
			max_anisotropy = 1,
		})
		verify( sokol_gfx.query_sampler_state( atlas_rt_sampler) < ResourceState.FAILED, "Failed to make atlas_rt_sampler" )

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
					clear_value  = {0.00, 0.00, 0.00, 1.0},
				}
			},
			depth = {
				load_action = .DONTCARE,
				store_action = .DONTCARE,
				clear_value = 0.0,
			},
			stencil = {
				load_action = .DONTCARE,
				store_action = .DONTCARE,
				clear_value = 0,
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
			attrs[ATTR_ve_draw_text_v_position] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = 0,
				buffer_index = 0,
			}
			attrs[ATTR_ve_draw_text_v_texture] = VertexAttributeState {
				format       = VertexFormat.FLOAT2,
				offset       = size_of(Vec2),
				buffer_index = 0,
			}
			buffers[0] = VertexBufferLayoutState {
				stride    = size_of([4]f32),
				step_func = VertexStep.PER_VERTEX
			}
		}

		color_target := ColorTargetState {
			pixel_format = app_env.defaults.color_format,
			write_mask   = .RGBA,
			blend = BlendState {
				enabled = true,
				src_factor_rgb   = .SRC_ALPHA,
				dst_factor_rgb   = .ONE_MINUS_SRC_ALPHA,
				op_rgb           = BlendOp.ADD,
				src_factor_alpha = .SRC_ALPHA,
				dst_factor_alpha = .ONE_MINUS_SRC_ALPHA,
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
			depth = {
				pixel_format  = app_env.defaults.depth_format,
				compare       = .ALWAYS,
				write_enabled = false,
			},
			cull_mode = .NONE,
		})
		verify( sokol_gfx.query_pipeline_state(screen_pipeline) < ResourceState.FAILED, "Failed to make screen_pipeline" )
	}

	// screen_pass
	{
		screen_action := PassAction {
			colors = {
				0 = {
					load_action  = .LOAD,
					store_action = .STORE,
					clear_value  = {0.00, 0.00, 0.00, 0.0},
				},
				1 = {
					load_action  = .LOAD,
					store_action = .STORE,
					clear_value  = {0.00, 0.00, 0.00, 0.0},
				},
				2 = {
					load_action  = .LOAD,
					store_action = .STORE,
					clear_value  = {0.00, 0.00, 0.00, 0.0},
				}
			},
			depth = {
				load_action  = .DONTCARE,
				store_action = .DONTCARE,
				clear_value  = 0.0,
			},
			stencil = {
				load_action  = .DONTCARE,
				store_action = .DONTCARE,
				clear_value  = 0,
			}
		}

		screen_pass = sokol_gfx.Pass {
			action = screen_action,
			// label =
		}
	}
}
