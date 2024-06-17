package sectr

import sokol_gfx "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"

PassActions :: struct {
	bg_clear_black : sokol_gfx.Pass_Action,

}

RenderState :: struct {
	pass_actions : PassActions,
}

// TODO(Ed) : Review this and put into space.odin when ready
ortho :: proc(left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) -> [4][4]f32 {
    result: [4][4]f32
    result[0][0] = 2.0 / (right - left)
    result[1][1] = 2.0 / (top - bottom)
    result[2][2] = -2.0 / (far - near)
    result[3][0] = -(right + left) / (right - left)
    result[3][1] = -(top + bottom) / (top - bottom)
    result[3][2] = -(far + near) / (far - near)
    result[3][3] = 1.0
    return result
}

render :: proc()
{
	Bindings    :: sokol_gfx.Bindings
	Range       :: sokol_gfx.Range
	ShaderStage :: sokol_gfx.Shader_Stage

	state := get_state(); using state
	using render_data

	do_nothing : bool
	do_nothing = false

	// apply_bindings :: sokol_gfx.apply_bindings

	// Clear Demo
	if false
	{
	  green_value := debug.gfx_clear_demo_pass_action.colors[0].clear_value.g + 0.01
	  debug.gfx_clear_demo_pass_action.colors[0].clear_value.g = green_value > 1.0 ? 0.0 : green_value

	  sokol_gfx.begin_pass( sokol_gfx.Pass {
	  	action    = debug.gfx_clear_demo_pass_action,
	  	swapchain = sokol_glue.swapchain()
	  })
	  sokol_gfx.end_pass()
	  sokol_gfx.commit()
	}

	// Triangle Demo
	if false
	{
		using debug.gfx_tri_demo_state
		sokol_gfx.begin_pass(sokol_gfx.Pass { action = pass_action, swapchain = sokol_glue.swapchain() })
		sokol_gfx.apply_pipeline( pipeline )
		sokol_gfx.apply_bindings( bindings )

		sokol_gfx.draw( 0, 3, 1 )

		sokol_gfx.end_pass()
		sokol_gfx.commit()
	}

	// learnopengl.com/In-Practice/Text-Rendering
	when true
	{
		profile("learngl_text_render_pass")
		using font_provider_data

	  // green_value := debug.gfx_clear_demo_pass_action.colors[0].clear_value.g + 0.01
	  // debug.gfx_clear_demo_pass_action.colors[0].clear_value.g = green_value > 1.0 ? 0.0 : green_value
	  // sokol_gfx.begin_pass( sokol_gfx.Pass {
	  // 	action    = debug.gfx_clear_demo_pass_action,
	  // 	swapchain = sokol_glue.swapchain()
	  // })
		sokol_gfx.begin_pass(sokol_gfx.Pass { action = pass_actions.bg_clear_black, swapchain = sokol_glue.swapchain() })
		sokol_gfx.apply_pipeline( gfx_pipeline )
		// sokol_gfx.update_buffer( gfx_vbuffer, sokol_gfx.Range{ , Font_Provider_Ggfx_Buffer_Size } )

		projection := ortho( 0, app_window.extent.x * 2, 0, app_window.extent.y * 2, -1, 1 )
		sokol_gfx.apply_uniforms( ShaderStage.VS, SLOT_font_glyph_vs_params, sokol_gfx.Range{ & projection[0][0] , size_of(projection) })

		text_test_str := str_fmt("frametime: %v", frametime_avg_ms)
		def := hmap_chained_get( font_cache, default_font.key )

		x     : f32 = 0.0
		y     : f32 = 25.0
		scale : f32 = 0.5
		next := 0
		for codepoint, byte_offset in text_test_str
		{
			using def
			glyph := & glyphs[ int(codepoint) ]

			if glyph.size.x == 0 do continue
			// logf("Drawing glyph: %v", codepoint)

			bearing : Vec2 = { f32(glyph.bearing.x), f32(glyph.bearing.y) }
			size    : Vec2 = { f32(glyph.size.x),    f32(glyph.size.y) }

			pos := vec2(
				x + bearing.x            * scale,
				y - (size.y - bearing.y) * scale
			)

			width  := size.x * scale
			height := size.y * scale

			vertices : [6]Vec2 = {
				{ pos.x,         pos.y + height },
				{ pos.x,         pos.y          },
				{ pos.x + width, pos.y          },

				{ pos.x,         pos.y + height },
				{ pos.x + width, pos.y          },
				{ pos.x + width, pos.y + height }
			}

			uv_coords : [6]Vec2 = {
				0 = { 0.0, 0.0 },
				1 = { 0.0, 1.0 },
				2 = { 1.0, 1.0 },

				3 = { 0.0, 0.0 },
				4 = { 1.0, 1.0 },
				5 = { 1.0, 0.0 },
			}

			color : Vec3 = { 1.0, 1.0, 1.0 }
			fs_uniform := Font_Glyph_Fs_Params {
				glyph_color = color
			}
			sokol_gfx.apply_uniforms( sokol_gfx.Shader_Stage.FS, SLOT_font_glyph_fs_params, Range{ & fs_uniform, size_of(fs_uniform) })

			vbuf_offset := sokol_gfx.append_buffer( gfx_v_buffer, { & vertices[0], size_of(vertices) })
			// sokol_gfx.update_buffer( gfx_uv_buffer, { & uv_coords[0], size_of(uv_coords) })

			bindings := Bindings {
				vertex_buffers        = {
					ATTR_font_glyph_vs_vertex        = gfx_v_buffer,
					ATTR_font_glyph_vs_texture_coord = gfx_uv_buffer,
				},
				vertex_buffer_offsets = {
					ATTR_font_glyph_vs_vertex        = vbuf_offset,
					ATTR_font_glyph_vs_texture_coord = 0,
				},
				fs                    = {
					images   = { SLOT_glyph_bitmap         = glyph.texture },
					samplers = { SLOT_glyph_bitmap_sampler = gfx_sampler   }
				},
			}
			sokol_gfx.apply_bindings( bindings )

			sokol_gfx.draw( 0, 6, 1 )
			next += 6

			x += f32(glyph.advance >> 6) * scale
		}

		sokol_gfx.end_pass()
		sokol_gfx.commit()
	}
}
