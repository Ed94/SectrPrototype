package sectr

import "core:math"
import "core:time"

import ve         "codebase:font/VEFontCache"
import sokol_app  "thirdparty:sokol/app"
import gfx        "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"
import gp         "thirdparty:sokol/gp"

PassActions :: struct {
	bg_clear_black : gfx.Pass_Action,

}

RenderState :: struct {
	pass_actions : PassActions,
}

// Draw text using a string and normalized screen coordinates
draw_text_string_pos_norm :: proc( content : string, id : FontID, size : f32, pos : Vec2, color := Color_White )
{
	state := get_state(); using state
	width  := app_window.extent.x * 2
	height := app_window.extent.y * 2

	ve_id      := font_provider_resolve_draw_id( id )
	color_norm := normalize_rgba8(color)

	ve.set_colour( & font_provider_data.ve_font_cache, color_norm )
	ve.draw_text( & font_provider_data.ve_font_cache, ve_id, content, pos, Vec2{1 / width, 1 / height} )
	return
}

// Draw text using a string and extent-based screen coordinates
draw_text_string_pos_extent :: proc( content : string, id : FontID, size : f32, pos : Vec2, color := Color_White )
{
	state := get_state(); using state
	extent := app_window.extent

	normalized_pos := pos / extent
	draw_text_string_pos_norm( content, id, size, normalized_pos, color )
}

render :: proc()
{
	profile(#procedure)
	state := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack


	// TODO(Ed): Eventually we want to only update when state is dirty/user has done an action
	gfx.begin_pass(gfx.Pass { action = render_data.pass_actions.bg_clear_black, swapchain = sokol_glue.swapchain() })
	gfx.end_pass();

	// render_mode_3d()

	render_mode_2d_workspace()
	render_mode_screenspace()

	gfx.commit()
	ve.flush_draw_list( & font_provider_data.ve_font_cache )
}

// TODO(Ed): Eventually this needs to become a 'viewport within a UI'
// This would allow the user to have more than one workspace open at the same time
render_mode_2d_workspace :: proc()
{
	profile(#procedure)
	state  := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack
	cam    := & project.workspace.cam
}

render_mode_screenspace :: proc()
{
	profile(#procedure)
	state := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack
	replay := & Memory_App.replay
	cam    := & project.workspace.cam
	win_extent := state.app_window.extent

	ve.configure_snap( & font_provider_data.ve_font_cache, u32(state.app_window.extent.x * 2.0), u32(state.app_window.extent.y * 2.0) )

	render_screen_ui()

	debug_draw_text :: proc( content : string, pos : Vec2, size : f32, color := Color_White, font : FontID = Font_Default )
	{
		state := get_state(); using state

		if len( content ) == 0 {
			return
		}

		font := font
		if font.key == Font_Default.key {
			font = default_font
		}
		// pos := screen_to_render_pos(pos)

		draw_text_string_pos_extent( content, font, size, pos, color )
	}

	debug_text :: proc( format : string, args : ..any )
	{
		@static draw_text_scratch : [Kilobyte * 8]u8

		state := get_state(); using state
		if debug.draw_debug_text_y > 800 {
			debug.draw_debug_text_y = 0
		}

		cam            := & project.workspace.cam
		screen_corners := screen_get_corners()

		position   := screen_corners.top_right
		position.x -= app_window.extent.x
		position.y -= debug.draw_debug_text_y

		content := str_fmt_buffer( draw_text_scratch[:], format, ..args )
		debug_draw_text( content, position, 12.0 )

		debug.draw_debug_text_y += 14
	}

	// "Draw text" using immediate mode api
	{
		font_provider := & state.font_provider_data
		using font_provider

		@static index : i32
		text_test_str := str_fmt("frametime       : %0.6f\nframetime(sokol): %0.2f\nframe id   : %d\nsokol_frame: %d", frametime_delta_ms, sokol_app.frame_delta() * S_To_MS, frame, sokol_app.frame_count() )
		// log(text_test_str)
		// text_test_str := str_fmt("HELLO VE FONT CACHE!")
		// text_test_str := str_fmt("C")

		// font_provider := & state.font_provider_data
		// fdef := hmap_chained_get( font_cache, default_font.key )

		width  := app_window.extent.x * 2
		height := app_window.extent.y * 2

		ve.set_colour( & ve_font_cache,  { 1.0, 1.0, 1.0, 1.0 } )
		ve.configure_snap( & ve_font_cache, u32(state.app_window.extent.x * 2.0), u32(state.app_window.extent.y * 2.0) )

		ve.draw_text( & ve_font_cache, font_provider_resolve_draw_id(default_font), text_test_str, {0.0, 0.975}, Vec2{1 / width, 1 / height} )
	}

	debug.debug_text_vis = true
	if debug.debug_text_vis
	{
		fps_msg       := str_fmt( "FPS: %f", fps_avg)
		fps_msg_width := cast(f32) u32(measure_text_size( fps_msg, default_font, 12.0, 0.0 ).x) + 0.5
		fps_msg_pos   := screen_get_corners().top_right - { fps_msg_width, 0 } - { 5, 5 }
		debug_draw_text( fps_msg, fps_msg_pos, 12.0, color = Color_White )
		// debug_draw_text( fps_msg, {}, 12.0, color = Color_White )

		render_text_layer()
	}

	debug.draw_debug_text_y = 14
}

render_screen_ui :: proc()
{
	profile(#procedure)
	state  := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack


}

render_text_layer :: proc()
{
	profile("VEFontCache: render frame")

	Bindings    :: gfx.Bindings
	Range       :: gfx.Range
	ShaderStage :: gfx.Shader_Stage

	state := get_state(); using state
	font_provider := state.font_provider_data
	using font_provider

	ve.optimize_draw_list( & ve_font_cache )
	draw_list := ve.get_draw_list( & ve_font_cache )

	draw_list_vert_slice  := array_to_slice(draw_list.vertices)
	draw_list_index_slice := array_to_slice(draw_list.indices)

	gfx.update_buffer( draw_list_vbuf, Range{ draw_list.vertices.data, draw_list.vertices.num * size_of(ve.Vertex) })
	gfx.update_buffer( draw_list_ibuf, Range{ draw_list.indices.data,  draw_list.indices.num  * size_of(u32)  })

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
				gfx.begin_pass( pass )

				// sokol_gfx.apply_viewport( 0,0, width, height, origin_top_left = true )
				// sokol_gfx.apply_scissor_rect( 0,0, width, height, origin_top_left = true )

				gfx.apply_pipeline( glyph_pipeline )

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
				gfx.apply_bindings( bindings )

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
				gfx.begin_pass( pass )

				// sokol_gfx.apply_viewport( 0, 0, width, height, origin_top_left = true )
				// sokol_gfx.apply_scissor_rect( 0, 0, width, height, origin_top_left = true )

				gfx.apply_pipeline( atlas_pipeline )

				fs_uniform := Ve_Blit_Atlas_Fs_Params { region = cast(i32) draw_call.region }
				gfx.apply_uniforms( ShaderStage.FS, SLOT_ve_blit_atlas_fs_params, Range { & fs_uniform, size_of(Ve_Blit_Atlas_Fs_Params) })

				gfx.apply_bindings(Bindings {
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
				gfx.begin_pass( pass )

				// sokol_gfx.apply_viewport( 0, 0, width, height, origin_top_left = true )
				// sokol_gfx.apply_scissor_rect( 0, 0, width, height, origin_top_left = true )

				gfx.apply_pipeline( screen_pipeline )

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
				gfx.apply_uniforms( ShaderStage.FS, SLOT_ve_draw_text_fs_params, Range { & fs_target_uniform, size_of(Ve_Draw_Text_Fs_Params) })

				gfx.apply_bindings(Bindings {
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
			gfx.draw( draw_call.start_index, num_indices, 1 )
		}

		gfx.end_pass()
	}
}
