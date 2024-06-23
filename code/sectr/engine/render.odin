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
	empty_action   : gfx.Pass_Action,
}

RenderState :: struct {
	pass_actions : PassActions,
}

gp_set_color :: #force_inline proc( color : RGBA8 ) {
	color := normalize_rgba8(color);
	gp.set_color( color.r, color.g, color.b, color.a )
}

draw_filled_circle :: proc(x, y, radius: f32, edges: int) {
	if edges < 3 do return // Need at least 3 edges to form a shape

	triangles := make([]gp.Triangle, edges)
	// defer delete(triangles)

	center := gp.Point{x, y}

	for i in 0..<edges {
			angle1 := 2 * math.PI * f32(i) / f32(edges)
			angle2 := 2 * math.PI * f32(i+1) / f32(edges)

			p1 := gp.Point{
					x + radius * math.cos(angle1),
					y + radius * math.sin(angle1),
			}
			p2 := gp.Point{
					x + radius * math.cos(angle2),
					y + radius * math.sin(angle2),
			}

			triangles[i] = gp.Triangle{center, p1, p2}
	}

	gp.draw_filled_triangles(raw_data(triangles), u32(len(triangles)))
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

	clear_pass := gfx.Pass { action = render_data.pass_actions.bg_clear_black, swapchain = sokol_glue.swapchain() }
	clear_pass.action.colors[0].clear_value = transmute(gfx.Color) normalize_rgba8( config.color_theme.bg )

	// TODO(Ed): Eventually we want to only update when state is dirty/user has done an action
	gfx.begin_pass(clear_pass)
	gfx.end_pass();

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

	screen_extent := app_window.extent
	screen_size   := app_window.extent * 2
	screen_ratio  := screen_size.x * ( 1.0 / screen_size.y )

	cam_zoom_ratio := 1.0 / cam.zoom

	gp.begin( i32(screen_size.x), i32(screen_size.y) )
	gp.viewport(0, 0, i32(screen_size.x), i32(screen_size.y))
	gp.project( -screen_extent.x, screen_extent.x, screen_extent.y, -screen_extent.y )

	gp.translate( cam.position.x * cam.zoom, cam.position.y * cam.zoom )
	gp.scale( cam.zoom, cam.zoom )

	gp_set_color(Color_White)
	draw_filled_circle(0, 0, 4, 24)

	// Enqueue gp pass to sokol gfx
	gfx.begin_pass( gfx.Pass { action = render_data.pass_actions.empty_action, swapchain = sokol_glue.swapchain() })
	gp.flush()
	gp.end()
	gfx.end_pass()
}

render_mode_screenspace :: proc()
{
	profile(#procedure)
	state := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack
	replay := & Memory_App.replay
	cam    := & project.workspace.cam
	win_extent := state.app_window.extent

	screen_extent := app_window.extent
	screen_size   := app_window.extent * 2
	screen_ratio  := screen_size.x * ( 1.0 / screen_size.y )

	ve.configure_snap( & font_provider_data.ve_font_cache, u32(state.app_window.extent.x * 2.0), u32(state.app_window.extent.y * 2.0) )

	render_screen_ui()

	Render_Reference_Dots:
	{
		gp.begin( i32(screen_size.x), i32(screen_size.y) )
		gp.viewport(0, 0, i32(screen_size.x), i32(screen_size.y))
		gp.project( -screen_extent.x, screen_extent.x, screen_extent.y, -screen_extent.y )

		gp_set_color(Color_Screen_Center_Dot)
		draw_filled_circle(0, 0, 2, 24)

		Mouse_Position:
		{
			mouse_pos := input.mouse.pos
			gp_set_color({ 180, 180, 180, 20})
			draw_filled_circle( mouse_pos.x, mouse_pos.y, 4, 24 )
		}

		gfx.begin_pass( gfx.Pass { action = render_data.pass_actions.empty_action, swapchain = sokol_glue.swapchain() })
		gp.flush()
		gp.end()
		gfx.end_pass()
	}


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

		position   := screen_corners.top_left
		position.x = 0
		position.y -= debug.draw_debug_text_y

		content := str_fmt_buffer( draw_text_scratch[:], format, ..args )
		debug_draw_text( content, position, 12.0 )

		debug.draw_debug_text_y += 12
	}

	debug.debug_text_vis = true
	if debug.debug_text_vis
	{
		fps_msg       := str_fmt( "FPS: %0.2f", fps_avg)
		fps_msg_width := measure_text_size( fps_msg, default_font, 12.0, 0.0 ).x
		fps_msg_pos   := screen_get_corners().top_right - { fps_msg_width, 0 } - { 5, 5 }
		debug_draw_text( fps_msg, fps_msg_pos, 38.0, color = Color_Red )

		debug_text( "Screen Width : %v", screen_size.x )
		debug_text( "Screen Height: %v", screen_size.y )
		debug_text( "frametime_target_ms       : %f ms", frametime_target_ms )
		debug_text( "frametime                 : %0.3f ms", frametime_delta32() )
		debug_text( "frametime_last_elapsed_ms : %f ms", frametime_elapsed_ms )
		if replay.mode == ReplayMode.Record {
			debug_text( "Recording Input")
		}
		if replay.mode == ReplayMode.Playback {
			debug_text( "Replaying Input")
		}
		debug_text("Zoom Target: %v", project.workspace.zoom_target)

		if true
		{
			using input_events

			id := 0
			iter_obj  := iterator( & mouse_events ); iter := & iter_obj
			for event := next( iter ); event != nil; event = next( iter )
			{
				if id >= 4 do break
				id += 1

				debug_text("Mouse Event: %v", event )
			}
		}

		if debug.mouse_vis {
			debug_text("Mouse scroll: %v", input.mouse.scroll )
			debug_text("Mouse Delta                    : %v", input.mouse.delta )
			debug_text("Mouse Position (Render)        : %v", input.mouse.raw_pos )
			debug_text("Mouse Position (Screen)        : %v", input.mouse.pos )
			debug_text("Mouse Position (Workspace View): %v", screen_to_ws_view_pos(input.mouse.pos) )
			// rl.DrawCircleV( input.mouse.raw_pos,                    10, Color_White_A125 )
			// rl.DrawCircleV( screen_to_render_pos(input.mouse.pos),  2, Color_BG )
		}

		if false
		{
			ui := & project.workspace.ui

			debug_text("Box Count (Workspace): %v", ui.built_box_count )

			hot_box    := ui_box_from_key( ui.curr_cache, ui.hot )
			active_box := ui_box_from_key( ui.curr_cache, ui.active )
			if hot_box != nil {
				debug_text("Worksapce Hot    Box   : %v", hot_box.label.str )
				debug_text("Workspace Hot    Range2: %v", hot_box.computed.bounds.pts)
			}
			if active_box != nil{
				debug_text("Workspace Active Box: %v", active_box.label.str )
			}
		}

		if false
		{
			ui := & screen_ui

			debug_text("Box Count: %v", ui.built_box_count )

			hot_box    := ui_box_from_key( ui.curr_cache, ui.hot )
			active_box := ui_box_from_key( ui.curr_cache, ui.active )
			if hot_box != nil {
				debug_text("Hot    Box   : %v", hot_box.label.str )
				debug_text("Hot    Range2: %v", hot_box.computed.bounds.pts)
			}
			if active_box != nil{
				debug_text("Active Box: %v", active_box.label.str )
			}
		}

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
					colour = draw_call.colour,
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
