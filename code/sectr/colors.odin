package sectr

import rl "vendor:raylib"

Color       :: rl.Color
Color_Blue  :: rl.BLUE
// Color_Green :: rl.GREEN
Color_Red   :: rl.RED
Color_White :: rl.WHITE

Color_Transparent          :: Color {   0,   0,   0,   0 }
Color_BG                   :: Color {  55,  55,  60, 255 }
Color_BG_TextBox           :: Color {  32,  32,  32, 180 }
Color_BG_Panel             :: Color {  32,  32,  32, 255 }
Color_BG_Panel_Translucent :: Color {  32,  32,  32, 220 }
Color_BG_TextBox_Green     :: Color { 102, 102, 110, 255 }
Color_Frame_Disabled       :: Color {  22,  22,  22, 120 }
Color_Frame_Hover          :: Color { 122, 122, 125, 200 }
Color_Frame_Select         :: Color { 188, 188, 188, 220 }
Color_GreyRed              :: Color { 220, 100, 100, 50 }
Color_White_A125           :: Color { 255, 255, 255, 165 }
Color_Black                :: Color { 0, 0, 0, 255 }
Color_Green                :: Color { 0, 180, 0, 255 }
Color_ResizeHandle         :: Color { 80, 80, 90, 180 }

Color_3D_BG :: Color { 188, 182 , 170, 255 }

Color_Debug_UI_Padding_Bounds :: Color {  40, 195, 170, 160 }
Color_Debug_UI_Content_Bounds :: Color { 170, 120, 240, 160 }

// TODO(Ed): The entire rendering pass should be post-processed by a tone curve configurable for the user
// This is how you properly support any tonality of light or dark themes and not have it be base don the monitors raw output.

AppColorTheme :: struct {
	light_limit,
	dark_limit,

	bg,

	border_default,

	btn_bg_default,
	btn_bg_hot,
	btn_bg_active,

	input_box_bg,
	input_box_bg_hot,
	input_box_bg_active,

	resize_hndl_default,
	resize_hndl_hot,
	resize_hndl_active,

	table_even_bg_color,
	table_odd_bg_color,

	text_default,
	text_hot,
	text_active,

	translucent_panel,

	window_bar_border,
	window_bar_bg,
	window_btn_close_bg_hot,

	window_panel_bg,
	window_panel_border \
	: Color
}

App_Thm_Dusk :: AppColorTheme {
	light_limit = Color {125, 125, 125, 255},
	dark_limit  = Color { 10, 10, 10, 255},

	bg = Color {33, 33, 33, 255},

	border_default = Color { 64, 64, 64, 255},

	btn_bg_default = Color { 40,  40,  40, 255},
	btn_bg_hot     = Color { 60,  60,  70, 255},
	btn_bg_active  = Color { 90, 100, 130, 255},

	input_box_bg        = Color { 20, 20, 20, 255},
	input_box_bg_hot    = Color { 25, 25, 25, 255},
	input_box_bg_active = Color { 15, 15, 15, 255},

	resize_hndl_default = Color_Transparent,
	resize_hndl_hot     = Color { 72, 72, 72, 90},
	resize_hndl_active  = Color { 88, 88, 88, 90},

	table_even_bg_color = Color { 35, 35, 35, 255},
	table_odd_bg_color  = Color { 30, 30, 30, 255},

	text_default = Color {120, 117, 115, 255},
	text_hot     = Color {180, 180, 180, 255},
	text_active  = Color {240, 240, 240, 255},

	translucent_panel = Color { 10, 10, 10, 50},

	window_bar_border       = Color { 64, 64, 64, 255}, // border_default
	window_bar_bg           = Color{35, 35, 35, 255},
	window_btn_close_bg_hot = Color{45, 35, 35, 255},

	window_panel_bg     = Color { 10, 10, 10, 50}, // translucent_panel
	window_panel_border = Color{24, 24, 24, 255},
}

App_Thm_Light :: AppColorTheme {
	light_limit = Color {195, 195, 195, 255},
	dark_limit  = Color { 60,  60,  60, 255},

	bg = Color {135, 135, 135, 255},

	border_default = Color { 174, 174, 174, 255},

	btn_bg_default = Color { 160, 160, 160, 255},
	btn_bg_hot     = Color { 145, 145, 155, 255},
	btn_bg_active  = Color { 124, 124, 136, 255},

	input_box_bg        = Color {115, 115, 115, 255},
	input_box_bg_hot    = Color {125, 125, 125, 255},
	input_box_bg_active = Color {105, 105, 105, 255},

	resize_hndl_default = Color_Transparent,
	resize_hndl_hot     = Color { 95, 95, 95, 90},
	resize_hndl_active  = Color { 80, 80, 80, 90},

	table_even_bg_color = Color {150, 150, 150, 255},
	table_odd_bg_color  = Color {160, 160, 160, 255},

	text_default = Color { 55,  55,  55, 255},
	text_hot     = Color { 85,  85,  85, 255},
	text_active  = Color { 45,  45,  49, 255},

	translucent_panel = Color { 110, 110, 110, 50},

	window_bar_border       = Color{ 174, 174, 174, 255}, // border_default
	window_bar_bg           = Color{ 155, 155, 155, 255},
	window_btn_close_bg_hot = Color{ 145, 135, 135, 255},

	window_panel_bg     = Color {135, 135, 135, 50}, // translucent_panel
	window_panel_border = Color{184, 184, 184, 255},
}
