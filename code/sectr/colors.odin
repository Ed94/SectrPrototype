package sectr

RGBA8 :: struct { r, g, b, a : u8 }
RGBAN :: [4]f32

normalize_rgba8 :: #force_inline proc( color : RGBA8 ) -> RGBAN {
	quotient : f32 = 1.0 / 255

	result := RGBAN {
		f32(color.r) * quotient,
		f32(color.g) * quotient,
		f32(color.b) * quotient,
		f32(color.a) * quotient,
	}
	return result
}

Color_Blue  :: RGBA8 {  90,  90, 230, 255 }
Color_Red   :: RGBA8 { 230,  90,  90, 255 }
Color_White :: RGBA8 { 255, 255, 255, 255 }

Color_Transparent          :: RGBA8 {   0,   0,   0,   0 }
Color_BG                   :: RGBA8 {  55,  55,  60, 255 }
Color_BG_TextBox           :: RGBA8 {  32,  32,  32, 180 }
Color_BG_Panel             :: RGBA8 {  32,  32,  32, 255 }
Color_BG_Panel_Translucent :: RGBA8 {  32,  32,  32, 220 }
Color_BG_TextBox_Green     :: RGBA8 { 102, 102, 110, 255 }
Color_Frame_Disabled       :: RGBA8 {  22,  22,  22, 120 }
Color_Frame_Hover          :: RGBA8 { 122, 122, 125, 200 }
Color_Frame_Select         :: RGBA8 { 188, 188, 188, 220 }
Color_GreyRed              :: RGBA8 { 220, 100, 100,  50 }
Color_White_A125           :: RGBA8 { 255, 255, 255, 165 }
Color_Black                :: RGBA8 {   0,   0,   0, 255 }
Color_Green                :: RGBA8 {   0, 180,   0, 255 }
Color_ResizeHandle         :: RGBA8 {  80,  80,  90, 180 }

RGBA8_3D_BG :: RGBA8 { 188, 182 , 170, 255 }

RGBA8_Debug_UI_Padding_Bounds :: RGBA8 {  40, 195, 170, 160 }
RGBA8_Debug_UI_Content_Bounds :: RGBA8 { 170, 120, 240, 160 }

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

	table_even_bg,
	table_odd_bg,

	text_default,
	text_hot,
	text_active,

	translucent_panel,

	window_bar_border,
	window_bar_bg,
	window_btn_close_bg_hot,

	window_panel_bg,
	window_panel_border \
	: RGBA8
}

App_Thm_Dark :: AppColorTheme {
	light_limit = RGBA8 {185, 185, 185, 255},
	dark_limit  = RGBA8 { 6, 6, 6, 255},

	bg = RGBA8 {16, 16, 16, 255},

	border_default = RGBA8 { 54, 54, 54, 255},

	btn_bg_default = RGBA8 {  32,  32,  32, 255},
	btn_bg_hot     = RGBA8 {  80,  80, 100, 255},
	btn_bg_active  = RGBA8 { 100, 130, 180, 255},

	input_box_bg        = RGBA8 { 20, 20, 20, 255},
	input_box_bg_hot    = RGBA8 { 25, 25, 25, 255},
	input_box_bg_active = RGBA8 { 15, 15, 15, 255},

	resize_hndl_default = Color_Transparent,
	resize_hndl_hot     = RGBA8 { 72, 72, 72, 90},
	resize_hndl_active  = RGBA8 { 88, 88, 88, 90},

	table_even_bg = RGBA8 { 35, 35, 35, 255},
	table_odd_bg  = RGBA8 { 30, 30, 30, 255},

	text_default = RGBA8 {140, 137, 135, 255},
	text_hot     = RGBA8 {210, 210, 210, 255},
	text_active  = RGBA8 {255, 255, 255, 255},

	translucent_panel = RGBA8 { 30, 30, 30, 50},

	window_bar_border       = RGBA8{74, 74, 74, 255},
	window_bar_bg           = RGBA8{32, 32, 32, 255},
	window_btn_close_bg_hot = RGBA8{65, 45, 45, 255},

	window_panel_bg     = RGBA8{ 20, 20, 20, 50},
	window_panel_border = RGBA8{ 84, 84, 84, 255},
}

App_Thm_Dusk :: AppColorTheme {
	light_limit = RGBA8 {125, 125, 125, 255},
	dark_limit  = RGBA8 { 10, 10, 10, 255},

	bg = RGBA8 {33, 33, 33, 255},

	border_default = RGBA8 { 64, 64, 64, 255},

	btn_bg_default = RGBA8 { 40,  40,  40, 255},
	btn_bg_hot     = RGBA8 { 60,  60,  70, 255},
	btn_bg_active  = RGBA8 { 90, 100, 130, 255},

	input_box_bg        = RGBA8 { 20, 20, 20, 255},
	input_box_bg_hot    = RGBA8 { 25, 25, 25, 255},
	input_box_bg_active = RGBA8 { 15, 15, 15, 255},

	resize_hndl_default = Color_Transparent,
	resize_hndl_hot     = RGBA8 { 72, 72, 72, 90},
	resize_hndl_active  = RGBA8 { 88, 88, 88, 90},

	table_even_bg = RGBA8 { 35, 35, 35, 255},
	table_odd_bg  = RGBA8 { 30, 30, 30, 255},

	text_default = RGBA8 {120, 117, 115, 255},
	text_hot     = RGBA8 {180, 180, 180, 255},
	text_active  = RGBA8 {240, 240, 240, 255},

	translucent_panel = RGBA8 { 10, 10, 10, 50},

	window_bar_border       = RGBA8 { 64, 64, 64, 255}, // border_default
	window_bar_bg           = RGBA8{35, 35, 35, 255},
	window_btn_close_bg_hot = RGBA8{45, 35, 35, 255},

	window_panel_bg     = RGBA8 { 10, 10, 10, 50}, // translucent_panel
	window_panel_border = RGBA8{24, 24, 24, 255},
}

App_Thm_Light :: AppColorTheme {
	light_limit = RGBA8 {195, 195, 195, 255},
	dark_limit  = RGBA8 { 60,  60,  60, 255},

	bg = RGBA8 {135, 135, 135, 255},

	border_default = RGBA8 { 174, 174, 174, 255},

	btn_bg_default = RGBA8 { 160, 160, 160, 255},
	btn_bg_hot     = RGBA8 { 145, 145, 155, 255},
	btn_bg_active  = RGBA8 { 124, 124, 136, 255},

	input_box_bg        = RGBA8 {115, 115, 115, 255},
	input_box_bg_hot    = RGBA8 {125, 125, 125, 255},
	input_box_bg_active = RGBA8 {105, 105, 105, 255},

	resize_hndl_default = Color_Transparent,
	resize_hndl_hot     = RGBA8 { 95, 95, 95, 90},
	resize_hndl_active  = RGBA8 { 80, 80, 80, 90},

	table_even_bg = RGBA8 {150, 150, 150, 255},
	table_odd_bg  = RGBA8 {160, 160, 160, 255},

	text_default = RGBA8 { 55,  55,  55, 255},
	text_hot     = RGBA8 { 85,  85,  85, 255},
	text_active  = RGBA8 { 45,  45,  49, 255},

	translucent_panel = RGBA8 { 110, 110, 110, 50},

	window_bar_border       = RGBA8{ 174, 174, 174, 255}, // border_default
	window_bar_bg           = RGBA8{ 155, 155, 155, 255},
	window_btn_close_bg_hot = RGBA8{ 145, 135, 135, 255},

	window_panel_bg     = RGBA8 {135, 135, 135, 50}, // translucent_panel
	window_panel_border = RGBA8{184, 184, 184, 255},
}
