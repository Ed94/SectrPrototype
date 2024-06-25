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
	state := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack

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
		render_mode_2d_workspace()
		render_mode_screenspace()
	}
	gp.end()
	gfx.commit()
	ve.flush_draw_list( & font_provider_data.ve_font_cache )
	font_provider_data.vbuf_layer_offset  = 0
	font_provider_data.ibuf_layer_offset  = 0
	font_provider_data.calls_layer_offset = 0
}

// TODO(Ed): Eventually this needs to become a 'viewport within a UI'
// This would allow the user to have more than one workspace open at the same time
render_mode_2d_workspace :: proc()
{
	profile(#procedure)
	state  := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack
	cam    := project.workspace.cam

	screen_extent := app_window.extent
	screen_size   := app_window.extent * 2
	screen_ratio  := screen_size.x * ( 1.0 / screen_size.y )

	cam_zoom_ratio := 1.0 / cam.zoom

	// TODO(Ed): Eventually will be the viewport extents
	ve.configure_snap( & font_provider_data.ve_font_cache, u32(state.app_window.extent.x * 2.0), u32(state.app_window.extent.y * 2.0) )

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
	when true
	{
		render_set_view_space(screen_extent)
		// render_set_camera(cam)

		view_bounds := view_get_bounds()
		view_bounds.min *= 0.9
		view_bounds.max *= 0.9
		draw_rect( view_bounds, { 0, 0, 180, 30 } )

		render_flush_gp()
	}

	render_set_view_space(screen_extent)
	render_set_camera(cam)

	ui := & project.workspace.ui
	ui_context = & project.workspace.ui

	when UI_Render_Method == .Layers {
		render_list := array_to_slice( ui.render_list )
		render_ui_via_box_list( render_list, & cam )
	}
	when UI_Render_Method == .Depth_First
	{
		render_ui_via_box_tree( ui.root, & cam )
	}

	ui_context = nil
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
		profile("render_reference_dots (screen)")
		render_set_view_space(screen_extent)

		render_set_color(Color_Screen_Center_Dot)
		draw_filled_circle(0, 0, 2, 24)

		Mouse_Position:
		{
			mouse_pos := input.mouse.pos
			render_set_color( Color_White_A125 )
			draw_filled_circle( mouse_pos.x, mouse_pos.y, 4, 24 )
		}

		render_flush_gp()
	}

	debug.debug_text_vis = true
	if debug.debug_text_vis
	{
		debug_draw_text :: proc( content : string, pos : Vec2, size : f32, color := Color_White, font : FontID = Font_Default )
		{
			state := get_state(); using state
			if len( content ) == 0 do return

			font := font
			if font.key == Font_Default.key do font = default_font
			draw_text_string_pos_extent( content, font, size, pos, color )
		}

		debug_text :: proc( format : string, args : ..any )
		{
			state := get_state(); using state
			if debug.draw_debug_text_y > 800 do debug.draw_debug_text_y = 0

			cam            := & project.workspace.cam
			screen_corners := screen_get_corners()

			position   := screen_corners.top_left
			position.x += 2
			position.y -= debug.draw_debug_text_y

			content := str_fmt( format, ..args )
			text_size := measure_text_size( content, default_font, 14.0, 0.0 )
			debug_draw_text( content, position, 14.0 )
			debug.draw_debug_text_y += text_size.y + 3
		}

		profile("debug_text_vis")
		fps_size : f32 = 14.0
		fps_msg       := str_fmt( "FPS: %0.2f", fps_avg)
		fps_msg_size  := measure_text_size( fps_msg, default_font, fps_size, 0.0 )
		fps_msg_pos   := screen_get_corners().top_right - { fps_msg_size.x, fps_msg_size.y }
		debug_draw_text( fps_msg, fps_msg_pos, fps_size, color = Color_Red )

		debug_text( "Screen Width : %v", screen_size.x )
		debug_text( "Screen Height: %v", screen_size.y )
		debug_text( "frametime_target_ms       : %f ms", frametime_target_ms )
		debug_text( "frametime (work)          : %0.3f ms", frametime_delta_ms )
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

		if true
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

		if true {
			state.config.font_size_canvas_scalar = 1.0
			zoom_adjust_size := 16 * state.project.workspace.cam.zoom
			over_sample      := zoom_adjust_size < 12 ? 1.0 : f32(state.config.font_size_canvas_scalar)
			debug_text("font_size_canvas_scalar: %v", config.font_size_canvas_scalar)
			ve_id, resolved_size := font_provider_resolve_draw_id( default_font, zoom_adjust_size * over_sample )
			debug_text("font_size resolved: %v px", resolved_size)
		}

		render_text_layer()
	}

	debug.draw_debug_text_y = 14
}

render_screen_ui :: proc()
{
	profile(#procedure)
	state  := get_state(); using state // TODO(Ed): Prefer passing static context to through the callstack

	screen_extent := app_window.extent
	screen_size   := app_window.extent * 2
	screen_ratio  := screen_size.x * ( 1.0 / screen_size.y )
	render_set_view_space(screen_extent)

	ui := & screen_ui
	state.ui_context = & screen_ui

	text_enqueued  : b32 = false
	shape_enqueued : b32 = false

	when UI_Render_Method == .Layers {
		render_list := array_to_slice( ui.render_list )
		render_ui_via_box_list( render_list )
	}
	when UI_Render_Method == .Depth_First
	{
		render_ui_via_box_tree( ui.root )
	}

	state.ui_context = nil
}

render_text_layer :: proc()
{
	profile("VEFontCache: render text layer")

	Bindings    :: gfx.Bindings
	Range       :: gfx.Range
	ShaderStage :: gfx.Shader_Stage

	state := get_state(); using state
	font_provider := & state.font_provider_data
	using font_provider

	// TODO(Ed): All this functionality for being able to segregate rendering of the drawlist incrementally should be lifted to the library itself (VEFontCache)

	ve.optimize_draw_list( & ve_font_cache.draw_list, calls_layer_offset )
	draw_list := ve.get_draw_list( & ve_font_cache )

	draw_list_vert_slice  := array_to_slice(draw_list.vertices)
	draw_list_index_slice := array_to_slice(draw_list.indices)
	draw_list_calls_slice := array_to_slice(draw_list.calls)

	vbuf_layer_slice  := draw_list_vert_slice [ vbuf_layer_offset  : ]
	ibuf_layer_slice  := draw_list_index_slice[ ibuf_layer_offset  : ]
	calls_layer_slice := draw_list_calls_slice[ calls_layer_offset : ]

	vbuf_ve_range := Range{ raw_data(vbuf_layer_slice), cast(u64) len(vbuf_layer_slice) * size_of(ve.Vertex) }
	ibuf_ve_range := Range{ raw_data(ibuf_layer_slice), cast(u64) len(ibuf_layer_slice) * size_of(u32)       }

	gfx.append_buffer( draw_list_vbuf, vbuf_ve_range )
	gfx.append_buffer( draw_list_ibuf, ibuf_ve_range )

	vbuf_layer_offset  = cast(u64) len(draw_list_vert_slice)
	ibuf_layer_offset  = cast(u64) len(draw_list_index_slice)
	calls_layer_offset = cast(u64) len(draw_list_calls_slice)

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
				profile("VEFontCache: draw call: glyph")
				if num_indices == 0 && ! draw_call.clear_before_draw {
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
				profile("VEFontCache: draw call: atlas")
				if num_indices == 0 && ! draw_call.clear_before_draw {
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
				if num_indices == 0 && ! draw_call.clear_before_draw {
					continue
				}

				profile("VEFontCache: draw call: target")
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

		if num_indices != 0 {
			gfx.draw( draw_call.start_index, num_indices, 1 )
		}

		gfx.end_pass()
	}
}

render_ui_via_box_tree :: proc( root : ^UI_Box, cam : ^Camera = nil )
{
	debug        := get_state().debug
	default_font := get_state().default_font

	cam_zoom_ratio := cam != nil ? 1.0 / cam.zoom : 1.0
	circle_radius  := cam != nil ? cam_zoom_ratio * 3 : 3

	text_enqueued  : b32 = false
	shape_enqueued : b32 = false

	previous_layer : i32 = 0
	for box := root.first; box != nil; box = ui_box_tranverse_next_depth_based( box )
	{
		if box.ancestors != previous_layer {
			if shape_enqueued do render_flush_gp()
			if text_enqueued  do render_text_layer()
			shape_enqueued = false
			text_enqueued  = false
		}

		border_width := box.layout.border_width
		computed     := box.computed
		font_size    := box.layout.font_size
		style        := box.style
		text         := box.text

		using computed

		profile("enqueue box")

		GP_Render:
		{
			profile("draw_shapes")
			if style.bg_color.a != 0
			{
				draw_rect( bounds, style.bg_color )
				shape_enqueued = true
			}

			if style.border_color.a != 0 && border_width > 0 {
				render_set_color( style.border_color )
				draw_rect_border( bounds, border_width )
				shape_enqueued = true
			}

			line_thickness := 1 * cam_zoom_ratio

			if debug.draw_ui_padding_bounds && equal_range2( computed.content, computed.padding )
			{
				render_set_color( RGBA8_Debug_UI_Padding_Bounds )
				draw_rect_border( computed.padding, line_thickness )
			}
			else if debug.draw_ui_content_bounds {
				render_set_color( RGBA8_Debug_UI_Content_Bounds )
				draw_rect_border( computed.content, line_thickness )
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
				draw_text_string_pos_extent_zoomed( text.str, default_font, font_size, computed.text_pos, cam^, style.text_color )
			}
			else {
				draw_text_string_pos_extent( text.str, default_font, font_size, computed.text_pos, style.text_color )
			}
			text_enqueued = true
		}

		previous_layer = box.ancestors
	}

	if shape_enqueued do render_flush_gp()
	if text_enqueued  do render_text_layer()
}

render_ui_via_box_list :: proc( render_list : []UI_RenderBoxInfo, cam : ^Camera = nil )
{
	debug        := get_state().debug
	default_font := get_state().default_font

	text_enqueued  : b32 = false
	shape_enqueued : b32 = false

	for entry, id in render_list
	{
		already_passed_signal := id > 0 && render_list[ id - 1 ].layer_signal
		if !already_passed_signal && entry.layer_signal
		{
			profile("render ui layer")
			render_flush_gp()
			if text_enqueued do render_text_layer()
			continue
		}
		using entry

		profile("enqueue box")

		GP_Render:
		{
			// profile("draw_shapes")
			if style.bg_color.a != 0
			{
				draw_rect( bounds, style.bg_color )
				shape_enqueued = true
			}

			if style.border_color.a != 0 && border_width > 0 {
				render_set_color( style.border_color )
				draw_rect_border( bounds, border_width )
				shape_enqueued = true
			}

			if debug.draw_ui_box_bounds_points
			{
				render_set_color(Color_Red)
				draw_filled_circle(bounds.min.x, bounds.min.y, 3, 24)

				render_set_color(Color_Blue)
				draw_filled_circle(bounds.max.x, bounds.max.y, 3, 24)
				shape_enqueued = true
			}
		}

		if len(text.str) > 0 && style.font.key != 0 {
			if cam != nil {
				draw_text_string_pos_extent_zoomed( text.str, default_font, font_size, computed.text_pos, cam^, style.text_color )
			}
			else {
				draw_text_string_pos_extent( text.str, default_font, font_size, computed.text_pos, style.text_color )
			}
			text_enqueued = true
		}
	}

	if shape_enqueued do render_flush_gp()
	if text_enqueued  do render_text_layer()
}

#region("Helpers")

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

draw_rect :: proc( rect : Range2, color : RGBA8 ) {
	using rect
	render_set_color( color )

	size     := max - min
	position := min
	gp.draw_filled_rect( position.x, position.y, size.x, size.y )
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

// Draw text using a string and normalized render coordinates
draw_text_string_pos_norm :: proc( content : string, id : FontID, size : f32, pos : Vec2, color := Color_White, scale : f32 = 1.0 )
{
	state := get_state(); using state
	width  := app_window.extent.x * 2
	height := app_window.extent.y * 2

	ve_id, resolved_size := font_provider_resolve_draw_id( id, size )
	color_norm           := normalize_rgba8(color)

	ve.set_colour( & font_provider_data.ve_font_cache, color_norm )
	ve.draw_text( & font_provider_data.ve_font_cache, ve_id, content, pos, Vec2{1 / width, 1 / height} * scale )
	return
}

// Draw text using a string and extent-based screen coordinates
draw_text_string_pos_extent :: proc( content : string, id : FontID, size : f32, pos : Vec2, color := Color_White )
{
	profile(#procedure)
	state          := get_state(); using state
	screen_size    := app_window.extent * 2
	render_pos     := screen_to_render_pos(pos)
	normalized_pos := render_pos * (1.0 / screen_size)
	draw_text_string_pos_norm( content, id, size, normalized_pos, color )
}

draw_text_string_pos_extent_zoomed :: proc( content : string, id : FontID, size : f32, pos : Vec2, cam : Camera, color := Color_White )
{
	profile(#procedure)
	state := get_state(); using state

	cam_offset := Vec2 {
		cam.position.x,
		cam.position.y,
	}

	pos_offset     := (pos + cam_offset)
	cam_zoom_ratio := 1 / cam.zoom

	screen_size    := app_window.extent * 2
	screen_scale   := (1.0 / screen_size)
	render_pos     := ws_view_to_render_pos(pos)
	normalized_pos := render_pos * screen_scale

	zoom_adjust_size := size * cam.zoom

	// Over-sample font-size for any render under a camera
	over_sample : f32 = zoom_adjust_size < 12 ? 1.0 : f32(state.config.font_size_canvas_scalar)
	zoom_adjust_size *= over_sample

	ve_id, resolved_size := font_provider_resolve_draw_id( id, zoom_adjust_size	)

	text_scale : Vec2 = screen_scale
	// if config.cam_zoom_mode == .Smooth
	{
		f32_resolved_size := f32(resolved_size)
		diff_scalar       := 1 + (zoom_adjust_size - f32_resolved_size) / f32_resolved_size
		text_scale         =  diff_scalar * screen_scale
		text_scale.x       = clamp( text_scale.x, 0, screen_size.x )
		text_scale.y       = clamp( text_scale.y, 0, screen_size.y )
	}

	// Down-sample back
	text_scale  /= over_sample

	color_norm := normalize_rgba8(color)
	ve.set_colour( & font_provider_data.ve_font_cache, color_norm )
	ve.draw_text( & font_provider_data.ve_font_cache, ve_id, content, normalized_pos, text_scale )
}

// TODO(Ed): Eventually the workspace will need a viewport for drawing text

render_flush_gp :: #force_inline proc()
{
	profile(#procedure)
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
