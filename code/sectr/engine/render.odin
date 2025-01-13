package sectr

import "core:math"
import lalg "core:math/linalg"
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

render :: proc()
{
	profile(#procedure)
	state := get_state(); using state // TODO(Ed): Remove mutable access to to entire state.

	screen_extent := app_window.extent
	screen_size   := app_window.extent * 2
	screen_ratio  := screen_size.x * ( 1.0 / screen_size.y )

	gp.begin( i32(screen_size.x), i32(screen_size.y) )
	gp.set_blend_mode( .BLEND )

	// Clear the gp surface
	{
		render_set_view_space(screen_extent)
		render_set_color(config.color_theme.bg)
		gp.clear()
		render_flush_gp()
	}
	// Workspace and screen rendering passes
	{
		render_mode_2d_workspace( screen_extent, project.workspace.cam, input^, & project.workspace.ui, & font_provider_ctx.ve_ctx, font_provider_ctx.render )
		render_mode_screenspace( app_window.extent, & screen_ui, & font_provider_ctx.ve_ctx, font_provider_ctx.render, config, & debug )
	}
	gp.end()
	gfx.commit()
	ve.flush_draw_list( & font_provider_ctx.ve_ctx )
}

// TODO(Ed): Eventually this needs to become a 'viewport within a UI'
// This would allow the user to have more than one workspace open at the same time
render_mode_2d_workspace :: proc( screen_extent : Vec2, cam : Camera, input : InputState, ui : ^UI_State, ve_ctx : ^ve.Context, ve_render : VE_RenderData )
{
	profile(#procedure)
	cam_zoom_ratio := 1.0 / cam.zoom
	screen_size    := screen_extent * 2

	font_provider_set_px_scalar( app_config().text_size_canvas_scalar )

	Render_Debug:
	{
		profile("render_reference_dots (workspace)")
		render_set_view_space(screen_extent)
		render_set_camera(cam)

		render_set_color(Color_White)
		draw_filled_circle(0, 0, 2 * cam_zoom_ratio, 24)

		// Blend test
		if false
		{
			gp.set_color( 1.0, 0, 0, 0.25 )
			gp.draw_filled_rect(100, 100, 100, 100 )

			gp.set_color( 0.0, 1.0, 0, 0.25 )
			gp.draw_filled_rect(50, 50, 100, 100 )
		}

		mouse_pos := input.mouse.pos * cam_zoom_ratio - cam.position
		render_set_color( Color_GreyRed )
		draw_filled_circle( mouse_pos.x, mouse_pos.y, 4, 24 )

		render_flush_gp()
	}

	// Visualize view bounds
	when false
	{
    render_set_view_space(screen_extent)
    render_set_camera(cam)  // This should apply the necessary transformation

    view_bounds := view_get_bounds()

    // Draw the view bounds (should now appear as a rectangle covering the whole screen)
    draw_rect(view_bounds, {0, 0, 180, 30})

    render_flush_gp()
		gp.reset_transform()
}

	render_set_view_space(screen_extent)
	render_set_camera(cam)

	cam := cam
	when UI_Render_Method == .Layers {
		render_list_box  := array_to_slice( ui.render_list_box )
		render_list_text := array_to_slice( ui.render_list_text )
		render_ui_via_box_list( render_list_box, render_list_text, screen_extent, ve_ctx, ve_render, & cam )
	}
	when UI_Render_Method == .Depth_First
	{
		render_ui_via_box_tree( ui, screen_extent, ve_ctx, ve_render, & cam )
	}
}

render_mode_screenspace :: proc( screen_extent : Extents2, screen_ui : ^UI_State, ve_ctx : ^ve.Context, ve_render : VE_RenderData, config : AppConfig, debug : ^ScratchData )
{
	profile(#procedure)
	screen_size   := screen_extent * 2
	screen_ratio  := screen_size.x * ( 1.0 / screen_size.y )

	font_provider_set_px_scalar( app_config().text_size_screen_scalar )

	render_screen_ui( screen_extent, screen_ui, ve_ctx, ve_render )

	Render_Reference_Dots:
	{
		profile("render_reference_dots (screen)")
		render_set_view_space(screen_extent)

		render_set_color(Color_Screen_Center_Dot)
		draw_filled_circle(0, 0, 2, 24)

		Mouse_Position:
		{
			mouse_pos := get_state().input.mouse.pos
			render_set_color( Color_White_A125 )
			draw_filled_circle( mouse_pos.x, mouse_pos.y, 4, 24 )
		}

		render_flush_gp()
	}

	debug.debug_text_vis = true
	if debug.debug_text_vis
	{
		state := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack
		replay := & Memory_App.replay
		cam    := & project.workspace.cam

		debug_draw_text :: proc( content : string, pos : Vec2, size : f32, color := Color_White, font : FontID = Font_Default )
		{
			state := get_state(); using state // TODO(Ed): Remove this state getter. Get default font properly.
			if len( content ) == 0 do return

			font := font
			if font.key == Font_Default.key do font = default_font
			shape := shape_text_cached( content, font, size )
			ve.draw_shape_view_space(& get_state().font_provider_ctx.ve_ctx, normalize_rgba8(color), get_screen_extent() * 2, screen_to_render_pos(pos), 1.0, 1.0, shape)
		}

		debug_text :: proc( format : string, args : ..any )
		{
			state := get_state(); using state
			if debug.draw_debug_text_y > 800 do debug.draw_debug_text_y = 0

			cam            := & project.workspace.cam
			screen_corners := screen_get_corners()

			position   := screen_corners.top_left
			position.y -= debug.draw_debug_text_y

			content := str_fmt( format, ..args )
			text_size := measure_text_size( content, default_font, 12.0, 0.0 )
			debug_draw_text( content, position, 12.0 )
			debug.draw_debug_text_y += text_size.y
		}

		profile("debug_text_vis")
		if true {
			fps_size : f32 = 20.0
			fps_msg       := str_fmt( "FPS: %0.2f", fps_avg)
			fps_msg_size  := measure_text_size( fps_msg, default_font, fps_size, 0.0 )
			fps_msg_pos   := screen_get_corners().top_right - { fps_msg_size.x, fps_msg_size.y }
			debug_draw_text( fps_msg, fps_msg_pos, fps_size, color = Color_Red )
		}

		if true {
			frametime := get_frametime()
			debug_text( "Screen Width : %v", screen_size.x )
			debug_text( "Screen Height: %v", screen_size.y )
			debug_text( "frametime_target_ms       : %f ms",    frametime.target_ms )
			debug_text( "frametime (work)          : %0.3f ms", frametime.delta_ms )
			debug_text( "frametime_last_elapsed_ms : %f ms",    frametime.elapsed_ms )
		}
		if replay.mode == ReplayMode.Record {
			debug_text( "Recording Input")
		}
		if replay.mode == ReplayMode.Playback {
			debug_text( "Replaying Input")
		}

		if false
		{
			using input_events

			id := 0
			iter_obj  := iterator( & mouse_events ); iter := & iter_obj
			for event := next( iter ); event != nil; event = next( iter )
			{
				if id >= 2 do break
				id += 1

				debug_text("Mouse Event: %v", event )
			}
		}

		if debug.mouse_vis {
			debug_text("Mouse scroll: %v", input.mouse.scroll )
			debug_text("Mouse Delta                    : %0.2f", input.mouse.delta )
			debug_text("Mouse Position (Render)        : %0.2f", input.mouse.raw_pos )
			debug_text("Mouse Position (Screen)        : %0.2f", input.mouse.pos )
			debug_text("Mouse Position (Workspace View): %0.2f", screen_to_ws_view_pos(input.mouse.pos) )
		}

		if true
		{
			ui := & project.workspace.ui

			debug_text("Workspace Cam : %v", project.workspace.cam)
			debug_text("Zoom Target   : %v", project.workspace.zoom_target)

			debug_text("Box Count (Workspace): %v", ui.built_box_count )

			hot_box    := ui_box_from_key( ui.curr_cache, ui.hot )
			active_box := ui_box_from_key( ui.curr_cache, ui.active )
			if hot_box != nil {
				debug_text("Worksapce Hot    Box   : %v", hot_box.label )
				debug_text("Workspace Hot    Range2: %v", hot_box.computed.bounds.pts)
			}
			if active_box != nil{
				debug_text("Workspace Active Box: %v", active_box.label )
			}
		}

		if true
		{
			ui := & screen_ui

			debug_text("Box Count: %v", ui.built_box_count )

			hot_box    := ui_box_from_key( ui.curr_cache, ui.hot )
			active_box := ui_box_from_key( ui.curr_cache, ui.active )
			if hot_box != nil {
				debug_text("Hot    Box   : %v", hot_box.label )
				debug_text("Hot    Range2: %v", hot_box.computed.bounds.pts)
			}
			if active_box != nil{
				debug_text("Active Box: %v", active_box.label )
			}
		}

		render_text_layer( screen_extent, ve_ctx, ve_render )
	}

	debug.draw_debug_text_y = 14
}

render_screen_ui :: proc( screen_extent : Extents2, ui : ^UI_State, ve_ctx : ^ve.Context, ve_render : VE_RenderData )
{
	profile(#procedure)
	render_set_view_space(screen_extent)

	when UI_Render_Method == .Layers {
		render_list_box  := array_to_slice( ui.render_list_box )
		render_list_text := array_to_slice( ui.render_list_text )
		render_ui_via_box_list( render_list_box, render_list_text, screen_extent, ve_ctx, ve_render )
	}
	when UI_Render_Method == .Depth_First
	{
		render_ui_via_box_tree( ui, screen_extent, ve_ctx, ve_render )
	}
}

when false {
render_ui_via_box_tree :: proc( ui : ^UI_State, screen_extent : Vec2, ve_ctx : ^ve.Context, ve_render : VE_RenderData, cam : ^Camera = nil )
{
	// TODO(Ed): Make a debug getter.
	debug        := get_state().debug
	default_font := get_state().default_font

	cam_zoom_ratio := cam != nil ? 1.0 / cam.zoom : 1.0
	circle_radius  := cam != nil ? cam_zoom_ratio * 3 : 3

	text_enqueued  : b32 = false
	shape_enqueued : b32 = false

	render_set_view_space(screen_extent)
	if cam != nil {
			// gp.reset_transform()
			// render_set_camera(cam^)  // This should apply the necessary transformation
	}

	previous_layer : i32 = 0
	for box := ui_box_tranverse_next_depth_first( ui.root, bypass_intersection_test = true, ctx = ui ); box != nil; 
	    box  = ui_box_tranverse_next_depth_first( box,     bypass_intersection_test = true, ctx = ui )
	{
		if box.ancestors != previous_layer {
			if shape_enqueued do render_flush_gp()
			if text_enqueued  do render_text_layer( screen_extent, ve_ctx, ve_render )
			shape_enqueued = false
			text_enqueued  = false
		}

		if ! intersects_range2(ui_view_bounds(ui), box.computed.bounds) {
			continue
		}

		border_width := box.layout.border_width
		computed     := box.computed
		font_size    := box.layout.font_size
		style        := box.style
		text         := box.text

		using computed

		// profile("enqueue box")

		GP_Render:
		{
			corner_radii_total : f32 = 0
			for radius in style.corner_radii do corner_radii_total += radius

			// profile("draw_shapes")
			if style.bg_color.a != 0
			{
				render_set_color( style.bg_color )
				if corner_radii_total > 0 do draw_rect_rounded( bounds, style.corner_radii, 16 )
				else                      do draw_rect( bounds)
				shape_enqueued = true
			}

			if style.border_color.a != 0 && border_width > 0 {
				render_set_color( style.border_color )

				if corner_radii_total > 0 do draw_rect_rounded_border( bounds, style.corner_radii, border_width, 16 )
				else                      do draw_rect_border( bounds, border_width )
				shape_enqueued = true
			}

			line_thickness := 1 * cam_zoom_ratio

			if debug.draw_ui_padding_bounds && equal_range2( computed.content, computed.padding )
			{
				render_set_color( RGBA8_Debug_UI_Padding_Bounds )
				draw_rect_border( computed.padding, line_thickness )
				shape_enqueued = true
			}
			else if debug.draw_ui_content_bounds {
				render_set_color( RGBA8_Debug_UI_Content_Bounds )
				draw_rect_border( computed.content, line_thickness )
				shape_enqueued = true
			}

			if debug.draw_ui_box_bounds_points
			{
				render_set_color(Color_Red)
				draw_filled_circle(bounds.min.x, bounds.min.y, circle_radius, 24)

				render_set_color(Color_Blue)
				draw_filled_circle(bounds.max.x, bounds.max.y, circle_radius, 24)
				shape_enqueued = true
			}
		}

		if len(text.str) > 0 && style.font.key != 0 {
			if cam != nil {
				// draw_text_string_pos_extent_zoomed( text.str, default_font, font_size, computed.text_pos, cam^, style.text_color )
			}
			else {
				draw_text_string_pos_extent( text.str, default_font, font_size, computed.text_pos, style.text_color )
			}
			text_enqueued = true
		}

		previous_layer = box.ancestors
	}

	if shape_enqueued do render_flush_gp()
	if text_enqueued  do render_text_layer( screen_extent, ve_ctx, ve_render )
}
}

render_ui_via_box_list :: proc( box_list : []UI_RenderBoxInfo, text_list : []UI_RenderTextInfo, screen_extent : Vec2, ve_ctx : ^ve.Context, ve_render : VE_RenderData, cam : ^Camera = nil )
{
	profile(#procedure)
	debug        := get_state().debug
	default_font := get_state().default_font

	cam_zoom_ratio := cam != nil ? 1.0 / cam.zoom     : 1.0
	circle_radius  := cam != nil ? cam_zoom_ratio * 3 : 3

	box_id  : i32 = 0
	text_id : i32 = 0

	cam_offset := Vec2 {
		cam != nil ? cam.position.x : 0,
		cam != nil ? cam.position.y : 0,
	}

	screen_size := screen_extent * 2

	layer_left : b32 = true
	for layer_left
	{
		profile("layer")
		shape_enqueued : b32 = false
		box_layer_done : b32 = false
		for box_id < cast(i32) len(box_list) && ! box_layer_done
		{
			// profile("GP_Render")
			box_layer_done = b32(box_id > 0) && box_list[ box_id - 1 ].layer_signal

			entry := box_list[box_id]

			corner_radii_total : f32 = 0
			for radius in entry.corner_radii do corner_radii_total += radius

			if entry.bg_color.a != 0
			{
				render_set_color( entry.bg_color )
				if corner_radii_total > 0 do draw_rect_rounded( entry.bounds, entry.corner_radii, 16 )
				else                      do draw_rect( entry.bounds)
				shape_enqueued = true
			}

			if entry.border_color.a != 0 && entry.border_width > 0
			{
				render_set_color( entry.border_color )

				if corner_radii_total > 0 do draw_rect_rounded_border( entry.bounds, entry.corner_radii, entry.border_width, 16 )
				else                      do draw_rect_border( entry.bounds, entry.border_width )
				shape_enqueued = true
			}

			if debug.draw_ui_box_bounds_points
			{
				render_set_color(Color_Red)
				draw_filled_circle(entry.bounds.min.x, entry.bounds.min.y, circle_radius, 24)

				render_set_color(Color_Blue)
				draw_filled_circle(entry.bounds.max.x, entry.bounds.max.y, circle_radius, 24)
				shape_enqueued = true
			}

			box_id += 1
		}

		if shape_enqueued {
			// profile("render ui box_layer")
			render_flush_gp()
			shape_enqueued = false
		}
	
		text_enqueued   : b32 = false
		text_layer_done : b32 = false
		for text_id < cast(i32) len(text_list) && ! text_layer_done
		{
			// profile("Text_Render")
			entry := text_list[text_id]
			font  := entry.font.key != 0 ? entry.font : default_font

			text_layer_done = b32(text_id > 0) && text_list[ text_id - 1 ].layer_signal
			text_id        += 1

			if len(entry.text) == 0 do continue
			text_enqueued   = true

			ve_id := font_provider_font_def(entry.font)
			color := normalize_rgba8(entry.color)

			if cam != nil {
				canvas_position := ws_view_to_render_pos(entry.position)
				ve.draw_text_view_space(ve_ctx, ve_id, entry.font_size, color, screen_size, canvas_position, 1.0, cam.zoom, entry.text )
			}
			else {
				screen_position := screen_to_render_pos(entry.position)
				ve.draw_text_view_space(ve_ctx, ve_id, entry.font_size, color, screen_size, screen_position, 1.0, 1.0, entry.text)
			}
		}

		if text_enqueued {
			profile("render ui text layer")
			if text_enqueued do render_text_layer( screen_extent, ve_ctx, ve_render )
			text_enqueued  = false
		}

		layer_left = box_id < cast(i32) len(box_list) || text_id < cast(i32) len(text_list)
	}
}

render_text_layer :: proc( screen_extent : Vec2, ve_ctx : ^ve.Context, render : VE_RenderData )
{
	profile("VEFontCache: render text layer")
	using render

	Bindings    :: gfx.Bindings
	Range       :: gfx.Range
	ShaderStage :: gfx.Shader_Stage

	vbuf_layer_slice, ibuf_layer_slice, calls_layer_slice := ve.get_draw_list_layer( ve_ctx )

	vbuf_ve_range := Range{ raw_data(vbuf_layer_slice), cast(uint) len(vbuf_layer_slice) * size_of(ve.Vertex) }
	ibuf_ve_range := Range{ raw_data(ibuf_layer_slice), cast(uint) len(ibuf_layer_slice) * size_of(u32)       }

	gfx.append_buffer( draw_list_vbuf, vbuf_ve_range )
	gfx.append_buffer( draw_list_ibuf, ibuf_ve_range )

	ve.flush_draw_list_layer( ve_ctx )

	screen_width  := u32(screen_extent.x * 2)
	screen_height := u32(screen_extent.y * 2)

	atlas        := & ve_ctx.atlas
	glyph_buffer := & ve_ctx.glyph_buffer

	atlas_size     : Vec2 = vec2(atlas.size)
	glyph_buf_size : Vec2 = vec2(glyph_buffer.size)

	for & draw_call in calls_layer_slice
	{
		watch := draw_call
		// profile("VEFontCache: draw call")

		num_indices := draw_call.end_index - draw_call.start_index

		switch draw_call.pass
		{
			// 1. Do the glyph rendering pass
			// Glyphs are first rendered to an intermediate 2k x 512px R8 texture
			case .Glyph:
				// profile("VEFontCache: draw call: glyph")
				if num_indices == 0 && ! draw_call.clear_before_draw {
					continue
				}

				width  := ve_ctx.glyph_buffer.size.x
				height := ve_ctx.glyph_buffer.size.y

				pass := glyph_pass
				if draw_call.clear_before_draw {
					pass.action.colors[0].load_action   = .CLEAR
					pass.action.colors[0].clear_value.a = 1.0
				}
				gfx.begin_pass( pass )

				gfx.apply_viewport    ( 0,0, width, height, origin_top_left = true )
				gfx.apply_scissor_rect( 0,0, width, height, origin_top_left = true )

				gfx.apply_pipeline( glyph_pipeline )

				bindings := Bindings {
					vertex_buffers = {
						0 = draw_list_vbuf,
					},
					vertex_buffer_offsets = {
						0 = 0,
					},
					index_buffer        = draw_list_ibuf,
					index_buffer_offset = 0,
				}
				gfx.apply_bindings( bindings )

			// 2. Do the atlas rendering pass
			// A simple 16-tap box downsample shader is then used to blit from this intermediate texture to the final atlas location
			case .Atlas:
				// profile("VEFontCache: draw call: atlas")
				if num_indices == 0 && ! draw_call.clear_before_draw {
					continue
				}

				width  := ve_ctx.atlas.size.x
				height := ve_ctx.atlas.size.y

				pass := atlas_pass
				if draw_call.clear_before_draw {
					pass.action.colors[0].load_action   = .CLEAR
					pass.action.colors[0].clear_value.a = 1.0
				}
				gfx.begin_pass( pass )

				gfx.apply_viewport    ( 0, 0, width, height, origin_top_left = true )
				gfx.apply_scissor_rect( 0, 0, width, height, origin_top_left = true )

				gfx.apply_pipeline( atlas_pipeline )

				fs_uniform := Ve_Blit_Atlas_Fs_Params {
					glyph_buffer_size = glyph_buf_size,
					over_sample       = glyph_buffer.over_sample.x,
					region            = cast(i32) draw_call.region,
				}
				gfx.apply_uniforms( UB_ve_blit_atlas_fs_params, Range { & fs_uniform, size_of(Ve_Blit_Atlas_Fs_Params) })

				gfx.apply_bindings(Bindings {
					vertex_buffers = {
						0 = draw_list_vbuf,
					},
					vertex_buffer_offsets = {
						0 = 0,
					},
					index_buffer        = draw_list_ibuf,
					index_buffer_offset = 0,
					images              = { IMG_ve_blit_atlas_src_texture = glyph_rt_color,   },
					samplers            = { SMP_ve_blit_atlas_src_sampler = glyph_rt_sampler, },
				})

			// 3. Use the atlas to then render the text.
			case .None, .Target, .Target_Uncached:
				if num_indices == 0 && ! draw_call.clear_before_draw {
					continue
				}

				// profile("VEFontCache: draw call: target")

				pass := screen_pass
				pass.swapchain = sokol_glue.swapchain()
				gfx.begin_pass( pass )

				gfx.apply_viewport    ( 0, 0, screen_width, screen_height, origin_top_left = true )
				gfx.apply_scissor_rect( 0, 0, screen_width, screen_height, origin_top_left = true )

				gfx.apply_pipeline( screen_pipeline )

				src_rt      := atlas_rt_color
				src_sampler := atlas_rt_sampler

				fs_target_uniform := Ve_Draw_Text_Fs_Params {
					// glyph_buffer_size = glyph_buf_size,
					over_sample       = glyph_buffer.over_sample.x,
					colour            = draw_call.colour,
				}

				if draw_call.pass == .Target_Uncached {
					// fs_target_uniform.over_sample = 1.0
					src_rt      = glyph_rt_color
					src_sampler = glyph_rt_sampler
				}
				gfx.apply_uniforms( UB_ve_draw_text_fs_params, Range { & fs_target_uniform, size_of(Ve_Draw_Text_Fs_Params) })

				gfx.apply_bindings(Bindings {
					vertex_buffers = {
						0 = draw_list_vbuf,
					},
					vertex_buffer_offsets = {
						0 = 0,
					},
					index_buffer        = draw_list_ibuf,
					index_buffer_offset = 0,
					images              = { IMG_ve_draw_text_src_texture = src_rt, },
					samplers            = { SMP_ve_draw_text_src_sampler = src_sampler, },
				})
		}

		if num_indices != 0 {
			gfx.draw( draw_call.start_index, num_indices, 1 )
		}

		gfx.end_pass()
	}
}

#region("Helpers")

draw_shape :: proc(color : RGBAN, screen_size, position, scale : Vec2, zoom : f32, shape : ShapedText)
{
	ve_ctx := & get_state().font_provider_ctx.ve_ctx
	ve.draw_shape_view_space(ve_ctx, color, screen_size, position, scale, zoom, shape )
}

draw_text :: proc(font : FontID, px_size : f32, color : RGBAN, screen_size, position, scale : Vec2, zoom : f32, text : string)
{
	ve_ctx := & get_state().font_provider_ctx.ve_ctx
	ve_id  := font_provider_font_def(font)
	ve.draw_text_view_space(ve_ctx, ve_id, px_size, color, screen_size, position, scale, zoom, text )
}

draw_filled_circle :: proc(x, y, radius: f32, edges: int)
{
	if edges < 3 do return // Need at least 3 edges to form a shape

	triangles     := make([]gp.Triangle, edges)
	center        := gp.Point{x, y}
	edge_quotient := 1 / f32(edges)
	angle_factor  := 2 * math.PI * edge_quotient
	for edge_id in 0..< edges
	{
			angle1 := f32(edge_id   ) * angle_factor
			angle2 := f32(edge_id +1) * angle_factor

			p1 := gp.Point{
					x + radius * math.cos(angle1),
					y + radius * math.sin(angle1),
			}
			p2 := gp.Point{
					x + radius * math.cos(angle2),
					y + radius * math.sin(angle2),
			}
			triangles[edge_id] = gp.Triangle{center, p1, p2}
	}

	gp.draw_filled_triangles(raw_data(triangles), u32(len(triangles)))
}

draw_rect :: proc( rect : Range2 ) {
	using rect
	size     := max - min
	position := min
	gp.draw_filled_rect( position.x, position.y, size.x, size.y )
}

// Note(Ed): This is an inefficint solution to rendering rounded rectangles
// Eventually when sokoL_gp is ported to Odin it would be best to implement these using a custom shader
// Uses triangulation from the center. (UVs are problably weird but wont matter for my use case)
draw_rect_rounded :: proc(rect: Range2, radii: [4]f32, segments: u32)
{
	segments := i32(segments)
	width  := rect.max.x - rect.min.x
	height := rect.max.y - rect.min.y

	using Corner

	max_radius := min(width, height) * 0.5
	corner_radii := [4]f32{
		min(radii[ Top_Left    ], max_radius),
		min(radii[ Top_Right   ], max_radius),
		min(radii[ Bottom_Right], max_radius),
		min(radii[ Bottom_Left ], max_radius),
	}
	top_left     := corner_radii[ Top_Left     ]
	top_right    := corner_radii[ Top_Right    ]
	bottom_left  := corner_radii[ Bottom_Left  ]
	bottom_right := corner_radii[ Bottom_Right ]

	total_vertices  := (segments + 1) * 4
	total_triangles := total_vertices

	vertices  := make( []gp.Point,    total_vertices )
	triangles := make( []gp.Triangle, total_triangles)

	add_corner_vertices :: proc(vertices : []gp.Point, offset : i32, cx, cy, radius : f32, start_angle : f32, segments : i32)
	{
		half_pi :: math.PI / 2
		for segment in i32(0) ..= segments {
			angle := start_angle + half_pi * (f32(segment) / f32(segments))
			x     := cx + radius * math.cos(angle)
			y     := cy + radius * math.sin(angle)
			vertices[ offset + segment ] = gp.Point{x, y}
		}
	}

	half_pi :: math.PI / 2

	// Add vertices for each corner
	add_corner_vertices( vertices, 0 * (segments + 1), rect.min.x + top_left,     rect.min.y + top_left,     top_left,         math.PI, segments )
	add_corner_vertices( vertices, 1 * (segments + 1), rect.max.x - top_right,    rect.min.y + top_right,    top_right,    3 * half_pi, segments )
	add_corner_vertices( vertices, 2 * (segments + 1), rect.max.x - bottom_left,  rect.max.y - bottom_left,  bottom_left,            0, segments )
	add_corner_vertices( vertices, 3 * (segments + 1), rect.min.x + bottom_right, rect.max.y - bottom_right, bottom_right,     half_pi, segments )

	// Create triangles using fan triangulation
	center := gp.Point{ (rect.min.x + rect.max.x) * 0.5, (rect.min.y + rect.max.y) * 0.5 }
	for vertex in 0 ..< total_vertices {
			next             := (vertex + 1) % total_vertices
			triangles[vertex] = gp.Triangle { center, vertices[vertex], vertices[next] }
	}

	// Draw the filled triangles
	gp.draw_filled_triangles(raw_data(triangles), cast(u32)len(triangles))
}

draw_rect_border :: proc( rect : Range2, border_width: f32)
{
	rect_size    := rect.max - rect.min
	border_width := lalg.min(border_width, min(rect_size.x, rect_size.y) * 0.5)

	top    := gp.Rect{ rect.min.x,                rect.min.y,                rect_size.x,                    border_width }
	bottom := gp.Rect{ rect.min.x,                rect.max.y - border_width, rect_size.x,                    border_width }
	left   := gp.Rect{ rect.min.x,                rect.min.y + border_width, border_width, rect_size.y - 2 * border_width }
	right  := gp.Rect{ rect.max.x - border_width, rect.min.y + border_width, border_width, rect_size.y - 2 * border_width }

	borders := []gp.Rect{ top, bottom, left, right }
	gp.draw_filled_rects( raw_data(borders), u32(len(borders)) )
}

draw_rect_rounded_border :: proc(rect: Range2, radii: [4]f32, border_width: f32, segments: u32)
{
	width  := rect.max.x - rect.min.x
	height := rect.max.y - rect.min.y

	using Corner

	// Ensure radii are not too large
	max_radius := min(width, height) * 0.5
	corner_radii := [4]f32{
		min(radii[0], max_radius),
		min(radii[1], max_radius),
		min(radii[2], max_radius),
		min(radii[3], max_radius),
	}
	top_left     := corner_radii[ Top_Left     ]
	top_right    := corner_radii[ Top_Right    ]
	bottom_left  := corner_radii[ Bottom_Left  ]
	bottom_right := corner_radii[ Bottom_Right ]

	// Ensure border width is not too large
	border_width := min(border_width, max_radius)

	// Calculate the extents of the border rectangles
	left   := rect.min.x + max(top_left,    bottom_left)
	right  := rect.max.x - max(top_right,   bottom_right)
	top    := rect.min.y + max(top_left,    top_right)
	bottom := rect.max.y - max(bottom_left, bottom_right)

	// Draw border rectangles
	gp.draw_filled_rect(left,                      rect.min.y,                right - left, border_width)	// Top
	gp.draw_filled_rect(left,                      rect.max.y - border_width, right - left, border_width)	// Bottom
	gp.draw_filled_rect(rect.min.x,                top,                       border_width, bottom - top) // Left
	gp.draw_filled_rect(rect.max.x - border_width, top,                       border_width, bottom - top) // Right

	draw_corner_border :: proc( x, y : f32, outer_radius, inner_radius : f32, start_angle : f32, segments : u32 )
	{
		if outer_radius <= inner_radius do return
		triangles := make( []gp.Triangle, int(segments) * 2 )

		half_pi     :: math.PI / 2
		segment_quo := 1.0 / f32(segments)
		for segment in 0 ..< segments
		{
				angle1 := start_angle + half_pi * f32(segment)     * segment_quo
				angle2 := start_angle + half_pi * f32(segment + 1) * segment_quo

				outer1 := gp.Vec2{x + outer_radius * math.cos(angle1), y + outer_radius * math.sin(angle1)}
				outer2 := gp.Vec2{x + outer_radius * math.cos(angle2), y + outer_radius * math.sin(angle2)}
				inner1 := gp.Vec2{x + inner_radius * math.cos(angle1), y + inner_radius * math.sin(angle1)}
				inner2 := gp.Vec2{x + inner_radius * math.cos(angle2), y + inner_radius * math.sin(angle2)}

				triangles[segment * 2    ] = gp.Triangle { outer1, outer2, inner1 }
				triangles[segment * 2 + 1] = gp.Triangle { inner1, outer2, inner2 }
		}

		gp.draw_filled_triangles(raw_data(triangles), u32(len(triangles)))
	}

	half_pi :: math.PI / 2

	// Draw corner borders
	draw_corner_border(rect.min.x + top_left,     rect.min.y + top_left,     top_left,     max(top_left     - border_width, 0),     math.PI, segments)
	draw_corner_border(rect.max.x - top_right,    rect.min.y + top_right,    top_right,    max(top_right    - border_width, 0), 3 * half_pi, segments)
	draw_corner_border(rect.min.x + bottom_left,  rect.max.y - bottom_left,  bottom_left,  max(bottom_left  - border_width, 0),     half_pi, segments)
	draw_corner_border(rect.max.x - bottom_right, rect.max.y - bottom_right, bottom_right, max(bottom_right - border_width, 0),           0, segments)
}

// TODO(Ed): Eventually the workspace will need a viewport for drawing text

render_flush_gp :: #force_inline proc()
{
	profile(#procedure)
	// TODO(Ed): Perfer a non-mutable get to the pass.
	gfx.begin_pass( gfx.Pass { action = get_state().render_data.pass_actions.empty_action, swapchain = sokol_glue.swapchain() })
	gp.flush()
	gfx.end_pass()
}

@(deferred_none=gp.reset_transform)
render_set_camera :: #force_inline proc( cam : Camera )
{
	gp.translate( cam.position.x * cam.zoom, cam.position.y * cam.zoom )
	gp.scale( cam.zoom, cam.zoom )
}

render_set_color :: #force_inline proc( color : RGBA8 ) {
	color := normalize_rgba8(color);
	gp.set_color( color.r, color.g, color.b, color.a )
}

render_set_view_space :: #force_inline proc( extent : Extents2 )
{
	size := extent * 2
	gp.viewport(0, 0, i32(size.x), i32(size.y))
	gp.project( -extent.x, extent.x, extent.y, -extent.y )
}

#endregion("Helpers")
