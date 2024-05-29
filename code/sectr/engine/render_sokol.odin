package sectr

import sokol_gfx "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"

PassActions :: struct {
	bg_clear_black : sokol_gfx.Pass_Action,

}

RenderState :: struct {
	pass_actions : PassActions,
}

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
	if true
	{
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
		sokol_gfx.apply_uniforms( sokol_gfx.Shader_Stage.VS, SLOT_vs_params, sokol_gfx.Range{ & projection[0][0] , size_of(projection) })

		text_test_str := str_fmt("frametime: %v", frametime_avg_ms)
		def := hmap_chained_get( font_cache, default_font.key )

		x     : f32 = 0.0
		y     : f32 = 25.0
		scale : f32 = 1.0
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

			vertices : [6][4]f32 = {
				{ pos.x,         pos.y + height,   0.0, 0.0 },
				{ pos.x,         pos.y,            0.0, 1.0 },
				{ pos.x + width, pos.y,            1.0, 1.0 },

				{ pos.x,         pos.y + height,   0.0, 0.0 },
				{ pos.x + width, pos.y,            1.0, 1.0 },
				{ pos.x + width, pos.y + height,   1.0, 0.0 }
			}

			color : [3]f32 = { 0 = 255, 1 = 255, 2 = 255 }
			fs_uniform := Fs_Params {
				glyph_color = color
			}

			vbuf_offset := sokol_gfx.append_buffer( gfx_vbuffer, { & vertices[0][0], size_of(vertices) })
			// vbuf_offset : i32 = 0

			// bindings                         := glyph.bindings
			bindings := sokol_gfx.Bindings {
				vertex_buffers        = { 0 = gfx_vbuffer, },
				vertex_buffer_offsets = { 0 = vbuf_offset  },
				fs                    = {
					images   = { 0 = glyph.texture },
					samplers = { 0 = gfx_sampler   }
				},
			}
			sokol_gfx.apply_uniforms( sokol_gfx.Shader_Stage.FS, SLOT_fs_params, sokol_gfx.Range{ & fs_uniform, size_of(fs_uniform) })
			sokol_gfx.apply_bindings( bindings )

			sokol_gfx.draw( 0, 6, 1 )
			next += 6

			x += f32(glyph.advance >> 6) * scale
		}

		sokol_gfx.end_pass()
		sokol_gfx.commit()
	}

	// Batching Enqueue Boxes
	// Mixed with the batching enqueue for text

	//Begin
	// Flush boxs
	// flush text
	// End
}
