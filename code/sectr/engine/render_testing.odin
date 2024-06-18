package sectr

import "core:math"
import "core:time"

import ve         "codebase:font/VEFontCache"
import sokol_app  "thirdparty:sokol/app"
import sokol_gfx  "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"
import sokol_gp   "thirdparty:sokol/gp"

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

	time.sleep(10000)

	// The below are most likely limited to a "depth layer" and so
	// different depth layers need different draw pass combos (of the 3 constructive passes)
	// Will need to profile how expensive it is for batching with the UI box rendering
	// since the the text is correlated with the box rendering

	font_provider := & state.font_provider_data
	using font_provider
	// ve_ctx := & font_provider.ve_font_cache

	// Triangle Demo
	if false
	{
		using debug.gfx_tri_demo_state
		sokol_gfx.begin_pass(sokol_gfx.Pass { action = pass_action, swapchain = sokol_glue.swapchain() })
		sokol_gfx.apply_pipeline( pipeline )
		sokol_gfx.apply_bindings( bindings )

		sokol_gfx.draw( 0, 3, 1 )

		sokol_gfx.end_pass()
	}

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

	width  := app_window.extent.x * 2
	height := app_window.extent.y * 2

	profile_begin("sokol_gp demo pass")
	// Hello Sokol GP Demo
	{
		screen_ratio := width * (1.0 / height)

		sokol_gp.begin(i32(width), i32(height))

		sokol_gp.viewport(0, 0, i32(width), i32(height))
		sokol_gp.project(-screen_ratio, screen_ratio, 1.0, -1.0)

		sokol_gp.set_color(0.1, 0.1, 0.1, 1.0)
		sokol_gp.clear()

		// Draw animated rectangle box that rotates and changes colors
		time := f32(f64(sokol_app.frame_count()) * sokol_app.frame_duration())

		red   := math.sin(time) * 0.5 + 0.5
		green := math.cos(time) * 0.5 + 0.5

		sokol_gp.set_color(red, green, 0.3, 1.0)
		sokol_gp.rotate_at(time, 0.0, 0.0)
		sokol_gp.draw_filled_rect(-0.5, -0.5, 1.0, 1.0)
	}

	// Process sokol gp render depth pass
	{
		sokol_gfx.begin_pass( sokol_gfx.Pass { action = {}, swapchain = sokol_glue.swapchain() })

		sokol_gp.flush()
		sokol_gp.end()

		sokol_gfx.end_pass()
	}
	profile_end()

	// "Draw text" using immediate mode api
	{
		@static index : i32
		text_test_str := str_fmt("frametime  : %0.6f\nframe id   : %d\nsokol_frame: %d", frametime_avg_ms, frame, sokol_app.frame_count() )
		// log(text_test_str)
		// text_test_str := str_fmt("HELLO VE FONT CACHE!")
		// text_test_str := str_fmt("C")

		// font_provider := & state.font_provider_data
		fdef := hmap_chained_get( font_cache, default_font.key )


		ve.set_colour( & ve_font_cache,  { 1.0, 1.0, 1.0, 1.0 } )
		ve.configure_snap( & ve_font_cache, u32(state.app_window.extent.x * 2.0), u32(state.app_window.extent.y * 2.0) )

		ve.draw_text( & ve_font_cache, fdef.ve_id, text_test_str, {0.0, 0.975}, Vec2{1 / width, 1 / height} )
	}


	// sokol_gfx.begin_pass(sokol_gfx.Pass { action = pass_actions.bg_clear_black, swapchain = sokol_glue.swapchain() })
	// sokol_gfx.end_pass();

	// Process the draw calls for drawing text
	if true
	{
		profile("VEFontCache: render frame")

		ve.optimize_draw_list( & ve_font_cache )
		draw_list := ve.get_draw_list( & ve_font_cache )

		draw_list_vert_slice  := array_to_slice(draw_list.vertices)
		draw_list_index_slice := array_to_slice(draw_list.indices)

		sokol_gfx.update_buffer( draw_list_vbuf, Range{ draw_list.vertices.data, draw_list.vertices.num * size_of(ve.Vertex) })
		sokol_gfx.update_buffer( draw_list_ibuf, Range{ draw_list.indices.data,  draw_list.indices.num  * size_of(u32)  })

		draw_list_call_slice := array_to_slice(draw_list.calls)
		for & draw_call in array_to_slice(draw_list.calls)
		{
			watch := draw_call
			// profile("VEFontCache: draw call")

			switch draw_call.pass
			{
				// 1. Do the glyph rendering pass
				// Glyphs are first rendered to an intermediate 2k x 512px R8 texture
				case .Glyph:
					// profile("VEFontCache: draw call: glyph")
					if (draw_call.end_index - draw_call.start_index) == 0 && ! draw_call.clear_before_draw {
						continue
					}

					width  := ve_font_cache.atlas.buffer_width
					height := ve_font_cache.atlas.buffer_height

					pass := glyph_pass
					if draw_call.clear_before_draw {
						pass.action.colors[0].load_action   = .CLEAR
						pass.action.colors[0].clear_value.a = 1.0
					}
					sokol_gfx.begin_pass( pass )

					// sokol_gfx.apply_viewport( 0,0, width, height, origin_top_left = true )
					// sokol_gfx.apply_scissor_rect( 0,0, width, height, origin_top_left = true )

					sokol_gfx.apply_pipeline( glyph_pipeline )

					bindings := Bindings {
						vertex_buffers = {
							0 = draw_list_vbuf,
						},
						vertex_buffer_offsets = {
							0 = 0,
						},
						index_buffer        = draw_list_ibuf,
						index_buffer_offset = 0,//i32(draw_call.start_index) * size_of(u32),
						fs = {},
					}
					sokol_gfx.apply_bindings( bindings )

				// 2. Do the atlas rendering pass
				// A simple 16-tap box downsample shader is then used to blit from this intermediate texture to the final atlas location
				case .Atlas:
					// profile("VEFontCache: draw call: atlas")
					if (draw_call.end_index - draw_call.start_index) == 0 && ! draw_call.clear_before_draw {
						continue
					}

					width  := ve_font_cache.atlas.width
					height := ve_font_cache.atlas.height

					pass := atlas_pass
					if draw_call.clear_before_draw {
						pass.action.colors[0].load_action   = .CLEAR
						pass.action.colors[0].clear_value.a = 1.0
					}
					sokol_gfx.begin_pass( pass )

					// sokol_gfx.apply_viewport( 0, 0, width, height, origin_top_left = true )
					// sokol_gfx.apply_scissor_rect( 0, 0, width, height, origin_top_left = true )

					sokol_gfx.apply_pipeline( atlas_pipeline )

					fs_uniform := Ve_Blit_Atlas_Fs_Params { region = cast(i32) draw_call.region }
					sokol_gfx.apply_uniforms( ShaderStage.FS, SLOT_ve_blit_atlas_fs_params, Range { & fs_uniform, size_of(Ve_Blit_Atlas_Fs_Params) })

					sokol_gfx.apply_bindings(Bindings {
						vertex_buffers = {
							0 = draw_list_vbuf,
						},
						vertex_buffer_offsets = {
							0 = 0,
						},
						index_buffer        = draw_list_ibuf,
						index_buffer_offset = 0,//i32(draw_call.start_index) * size_of(u32),
						fs = {
							images   = { SLOT_ve_blit_atlas_src_texture = glyph_rt_color, },
							samplers = { SLOT_ve_blit_atlas_src_sampler = glyph_rt_sampler, },
						},
					})

				// 3. Use the atlas to then render the text.
				case .None: fallthrough
				case .Target: fallthrough
				case .Target_Uncached:
					if (draw_call.end_index - draw_call.start_index) == 0 && ! draw_call.clear_before_draw {
						continue
					}

					// profile("VEFontCache: draw call: target")
					width  := u32(app_window.extent.x * 2)
					height := u32(app_window.extent.y * 2)

					pass := screen_pass
					pass.swapchain = sokol_glue.swapchain()
					sokol_gfx.begin_pass( pass )

					// sokol_gfx.apply_viewport( 0, 0, width, height, origin_top_left = true )
					// sokol_gfx.apply_scissor_rect( 0, 0, width, height, origin_top_left = true )

					sokol_gfx.apply_pipeline( screen_pipeline )

					src_rt      := atlas_rt_color
					src_sampler := atlas_rt_sampler

					fs_target_uniform := Ve_Draw_Text_Fs_Params {
						down_sample = 0,
						colour = {1.0, 1.0, 1.0, 1},
					}

					if draw_call.pass == .Target_Uncached {
						fs_target_uniform.down_sample = 1
						src_rt      = glyph_rt_color
						src_sampler = glyph_rt_sampler
					}
					sokol_gfx.apply_uniforms( ShaderStage.FS, SLOT_ve_draw_text_fs_params, Range { & fs_target_uniform, size_of(Ve_Draw_Text_Fs_Params) })

					sokol_gfx.apply_bindings(Bindings {
						vertex_buffers = {
							0 = draw_list_vbuf,
						},
						vertex_buffer_offsets = {
							0 = 0,
						},
						index_buffer        = draw_list_ibuf,
						index_buffer_offset = 0,//i32(draw_call.start_index) * size_of(u32),
						fs = {
							images   = { SLOT_ve_draw_text_src_texture = src_rt, },
							samplers = { SLOT_ve_draw_text_src_sampler = src_sampler, },
						},
					})
			}

			if (draw_call.end_index - draw_call.start_index) != 0 {
				num_indices := draw_call.end_index - draw_call.start_index
				sokol_gfx.draw( draw_call.start_index, num_indices, 1 )
			}

			sokol_gfx.end_pass()
		}

		sokol_gfx.commit()
		ve.flush_draw_list( & ve_font_cache )
	}
}
