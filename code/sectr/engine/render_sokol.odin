package sectr

import sokol_gfx "thirdparty:sokol/gfx"
import sokol_glue "thirdparty:sokol/glue"

render :: proc()
{
	state := get_state(); using state

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


	// Batching Enqueue Boxes
	// Mixed with the batching enqueue for text


	//Begin
	// Flush boxs
	// flush text
	// End
}
