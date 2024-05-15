package sectr

import "core:fmt"

import rl "vendor:raylib"

draw_rectangle :: #force_inline proc "contextless" ( rect : rl.Rectangle, box : ^UI_RenderBoxInfo ) {
	using box
	if style.corner_radii[0] > 0 {
		rl.DrawRectangleRounded( rect, style.corner_radii[0], 9, style.bg_color )
	}
	else {
		rl.DrawRectangleRec( rect, style.bg_color )
	}
}

draw_rectangle_lines :: #force_inline proc "contextless" ( rect : rl.Rectangle, box : ^UI_RenderBoxInfo, color : Color, thickness : f32 ) {
	using box
	if style.corner_radii[0] > 0 {
		rl.DrawRectangleRoundedLines( rect, style.corner_radii[0], 9, thickness, color )
	}
	else {
		rl.DrawRectangleLinesEx( rect, thickness, color )
	}
}

render :: proc()
{
	profile(#procedure)
	state  := get_state(); using state

	render_mode_3d()

	rl.BeginDrawing()
	rl.ClearBackground( Color_ThmDark_BG )

	render_mode_2d_workspace()
	render_mode_screenspace()

	rl.EndDrawing()
}

// Experimental 3d viewport, not really the focus of this prototype
// Until we can have a native or interpreted program render to it its not very useful.
// Note(Ed): Other usecase could be 3d vis notes & math/graphical debug
render_mode_3d :: proc()
{
	profile(#procedure)

	state := get_state(); using state

	rl.BeginDrawing()
	rl.BeginTextureMode( debug.viewport_rt )
	rl.BeginMode3D( debug.cam_vp )
	rl.ClearBackground( Color_3D_BG )

	rl.EndMode3D()
	rl.EndTextureMode()
	rl.EndDrawing()
}

// TODO(Ed): Eventually this needs to become a 'viewport within a UI'
// This would allow the user to have more than one workspace open at the same time
render_mode_2d_workspace :: proc()
{
	profile(#procedure)
	state  := get_state(); using state
	cam    := & project.workspace.cam

	win_extent := state.app_window.extent

	rl.BeginMode2D( project.workspace.cam )

	// Draw 3D Viewport
	when false
	{
		viewport_size := Vec2 { 1280.0, 720.0 }
		vp_half_size := viewport_size * 0.5
		viewport_box := range2( -vp_half_size, vp_half_size )
		viewport_render := range2(
			ws_view_to_render_pos( viewport_box.min),
			ws_view_to_render_pos( viewport_box.max),
		)
		viewport_rect := range2_to_rl_rect( viewport_render )
		rl.DrawTextureRec( debug.viewport_rt.texture, viewport_rect, -vp_half_size, Color_White )
	}

	// draw_text( "This is text in world space", { 0, 200 }, 16.0  )

	cam_zoom_ratio := 1.0 / cam.zoom

	view_bounds := view_get_bounds()
	when false
	{
		render_view := Range2 { pts = {
			ws_view_to_render_pos( view_bounds.min),
			ws_view_to_render_pos( view_bounds.max),
		}}
		view_rect := rl.Rectangle {
			render_view.min.x,
			render_view.max.y,
			abs(render_view.max.x - render_view.min.x),
			abs(render_view.max.y - render_view.min.y),
		}
		rl.DrawRectangleRounded( view_rect, 0.3, 9, { 255, 0, 0, 20 } )
	}

	ImguiRender:
	{
		profile("Imgui Render")
		ui   := & state.project.workspace.ui
		root := ui.root
		if root == nil || root.num_children == 0 {
			break ImguiRender
		}
		state.ui_context = ui

		current := root.first
		for & current in array_to_slice(ui.render_queue)
		{
			profile("Box")
			style    := current.style
			computed := current.computed

			if ! intersects_range2( view_bounds, computed.bounds ) {
				continue
			}

			profile_begin("render space calc")
			render_bounds := range2(
				ws_view_to_render_pos(computed.bounds.min),
				ws_view_to_render_pos(computed.bounds.max),
			)
			render_padding := range2(
				ws_view_to_render_pos(computed.padding.min),
				ws_view_to_render_pos(computed.padding.max),
			)
			render_content := range2(
				ws_view_to_render_pos(computed.content.min),
				ws_view_to_render_pos(computed.content.max),
			)

			rect_bounds  := range2_to_rl_rect( render_bounds )
			rect_padding := range2_to_rl_rect( render_padding )
			rect_content := range2_to_rl_rect( render_content )
			profile_end()

			profile_begin("raylib drawing")
			if style.bg_color.a != 0
			{
				draw_rectangle( rect_bounds, & current )
			}
			if current.border_width > 0 {
				draw_rectangle_lines( rect_bounds, & current, style.border_color, current.border_width )
			}

			line_thickness := 1 * cam_zoom_ratio
			if debug.draw_UI_padding_bounds && equal_range2(computed.content, computed.padding) {
				draw_rectangle_lines( rect_padding, & current, Color_Debug_UI_Padding_Bounds, line_thickness )
			}
			else if debug.draw_ui_content_bounds {
				draw_rectangle_lines( rect_content, & current, Color_Debug_UI_Content_Bounds, line_thickness )
			}

			point_radius := 3 * cam_zoom_ratio

			// profile_begin("circles")
			if debug.draw_ui_box_bounds_points
			{
				computed_size := computed.bounds.p1 - computed.bounds.p0
				// center := Vec2 {
				// 	render_bounds.p0.x + computed_size.x * 0.5,
				// 	render_bounds.p0.y - computed_size.y * 0.5,
				// }
				// rl.DrawCircleV( center, point_radius, Color_White )

				rl.DrawCircleV( render_bounds.p0, point_radius, Color_Red )
				rl.DrawCircleV( render_bounds.p1, point_radius, Color_Blue )
			}
			// profile_end()

			profile_end()

			if len(current.text.str) > 0 {
				ws_view_draw_text( current.text, ws_view_to_render_pos(computed.text_pos * {1, -1}), current.font_size, style.text_color )
			}
		}
	}
	//endregion Imgui Render


	if debug.mouse_vis {
		cursor_world_pos := screen_to_ws_view_pos(input.mouse.pos)
		rl.DrawCircleV( ws_view_to_render_pos(cursor_world_pos), 5, Color_GreyRed )
	}

	rl.DrawCircleV( { 0, 0 }, 1 * cam_zoom_ratio, Color_White )

	rl.EndMode2D()
}

render_mode_screenspace :: proc ()
{
	profile("Render Screenspace")

	state := get_state(); using state
	replay := & Memory_App.replay
	cam    := & project.workspace.cam
	win_extent := state.app_window.extent

	render_screen_ui()

	fps_msg       := str_fmt_tmp( "FPS: %f", fps_avg)
	fps_msg_width := measure_text_size( fps_msg, default_font, 16.0, 0.0 ).x
	fps_msg_pos   := screen_get_corners().top_right - { fps_msg_width, 0 } - { 5, 5 }
	debug_draw_text( fps_msg, fps_msg_pos, 16.0, color = rl.GREEN )

	debug_text :: proc( format : string, args : ..any )
	{
		@static draw_text_scratch : [Kilobyte * 64]u8

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
		debug_draw_text( content, position, 14.0 )

		debug.draw_debug_text_y += 14
	}

	// Debug Text
	{
		// debug_text( "Screen Width : %v", rl.GetScreenWidth () )
		// debug_text( "Screen Height: %v", rl.GetScreenHeight() )
		debug_text( "frametime_target_ms       : %f ms", frametime_target_ms )
		debug_text( "frametime                 : %f ms", frametime_delta_ms )
		// debug_text( "frametime_last_elapsed_ms : %f ms", frametime_elapsed_ms )
		if replay.mode == ReplayMode.Record {
			debug_text( "Recording Input")
		}
		if replay.mode == ReplayMode.Playback {
			debug_text( "Replaying Input")
		}
	}

	debug_text("Zoom Target: %v", project.workspace.zoom_target)

	if debug.mouse_vis {
		debug_text("Mouse Vertical Wheel: %v", input.mouse.vertical_wheel )
		debug_text("Mouse Delta                    : %v", input.mouse.delta )
		debug_text("Mouse Position (Render)        : %v", input.mouse.raw_pos )
		debug_text("Mouse Position (Screen)        : %v", input.mouse.pos )
		debug_text("Mouse Position (Workspace View): %v", screen_to_ws_view_pos(input.mouse.pos) )
		rl.DrawCircleV( input.mouse.raw_pos,                    10, Color_White_A125 )
		rl.DrawCircleV( screen_to_render_pos(input.mouse.pos),  2, Color_BG )
	}

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

	ui = & screen_ui

	debug_text("Box Count: %v", ui.built_box_count )

	hot_box    = ui_box_from_key( ui.curr_cache, ui.hot )
	active_box = ui_box_from_key( ui.curr_cache, ui.active )
	if hot_box != nil {
		debug_text("Hot    Box   : %v", hot_box.label.str )
		debug_text("Hot    Range2: %v", hot_box.computed.bounds.pts)
	}
	if active_box != nil{
		debug_text("Active Box: %v", active_box.label.str )
	}

	view := view_get_bounds()
	// debug_text("View Bounds (World): %v", view.pts )

	debug.draw_debug_text_y = 14

	 // Define the triangle vertices and colors
	 vertices := []f32{
			// Positions        // Colors (RGBA)
			-0.5, -0.5, 0.0,    1.0, 0.0, 0.0, 1.0,  // Vertex 1: Red
			0.5, -0.5, 0.0,    0.0, 1.0, 0.0, 1.0,  // Vertex 2: Green
			0.0,  0.5, 0.0,    0.0, 0.0, 1.0, 1.0   // Vertex 3: Blue
	}

	// Begin using the shader to draw
	// rl.BeginShaderMode(debug.proto_text_shader)
	// rl.EndShaderMode()
}

// A non-zoomable static-view for ui
// Only a scalar factor may be applied to the size of widgets & fonts
// 'Window tiled' panels reside here
render_screen_ui :: proc()
{
	profile(#procedure)

	using state := get_state()

	//region App UI
	Render_App_UI:
	{
		profile("App UI")
		ui := & state.screen_ui
		state.ui_context = ui
		root := ui.root
		if root.num_children == 0 {
			break Render_App_UI
		}

		for & current in array_to_slice(ui.render_queue)
		{
			profile("Box")

			style    := current.style
			computed := & current.computed

			profile_begin("Coordinate space conversion")
			render_bounds := range2(
				screen_to_render_pos(computed.bounds.min),
				screen_to_render_pos(computed.bounds.max),
			)
			render_padding := range2(
				screen_to_render_pos(computed.padding.min),
				screen_to_render_pos(computed.padding.max),
			)
			render_content := range2(
				screen_to_render_pos(computed.content.min),
				screen_to_render_pos(computed.content.max),
			)
			rect_bounds  := range2_to_rl_rect( render_bounds )
			rect_padding := range2_to_rl_rect( render_padding )
			rect_content := range2_to_rl_rect( render_content )
			profile_end()

			profile_begin("raylib drawing")
			if style.bg_color.a != 0
			{
				draw_rectangle( rect_bounds, & current )
			}
			if current.border_width > 0 {
				draw_rectangle_lines( rect_bounds, & current, style.border_color, current.border_width )
			}

			line_thickness : f32 = 1

			// profile_begin("rl.DrawRectangleRoundedLines: padding & content")
			if debug.draw_UI_padding_bounds && equal_range2(computed.content, computed.padding) {
				draw_rectangle_lines( rect_padding, & current, Color_Debug_UI_Padding_Bounds, line_thickness )
			}
			else if debug.draw_ui_content_bounds {
				draw_rectangle_lines( rect_content, & current, Color_Debug_UI_Content_Bounds, line_thickness )
			}

			point_radius : f32 = 3

			// profile_begin("circles")
			if debug.draw_ui_box_bounds_points
			{
				computed_size := computed.bounds.p1 - computed.bounds.p0
				// center := Vec2 {
				// 	render_bounds.p0.x + computed_size.x * 0.5,
				// 	render_bounds.p0.y - computed_size.y * 0.5,
				// }
				// rl.DrawCircleV( center, point_radius, Color_White )

				rl.DrawCircleV( render_bounds.p0, point_radius, Color_Red )
				rl.DrawCircleV( render_bounds.p1, point_radius, Color_Blue )
			}

			if len(current.text.str) > 0 && style.font.key != 0 {
				draw_text_screenspace( current.text, screen_to_render_pos(computed.text_pos), current.font_size, style.text_color )
			}
			profile_end()
		}
	}
	//endregion App UI
}
