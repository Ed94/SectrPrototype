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

// Dark Theme

// Brightest value limited to (text is the only exception):
Color_ThmDark_BrightLimit :: Color {230, 230, 230, 255}
// Darkness value limited to (text is the only exception):
Color_ThmDark_DarkLimit   :: Color {10, 10, 10, 255}


Color_ThmDark_BG :: Color {33, 33, 33, 255}

Color_ThmDark_Translucent_Panel :: Color { 0, 0, 0, 60}

Color_ThmDark_ResizeHandle_Default :: Color_Transparent
Color_ThmDark_ResizeHandle_Hot     :: Color { 72, 72, 72, 90}
Color_ThmDark_ResizeHandle_Active  :: Color { 88, 88, 88, 90}

Color_ThmDark_Border_Default :: Color { 64, 64, 64, 255}

Color_ThmDark_Btn_BG_Default :: Color { 40,  40,  40, 255}
Color_ThmDark_Btn_BG_Hot     :: Color { 60,  60,  70, 255}
Color_ThmDark_Btn_BG_Active  :: Color { 90, 100, 130, 255}

Color_ThmDark_Text_Default :: Color {120, 117, 115, 255}
Color_ThmDark_Text_Hot     :: Color {180, 180, 180, 255}
Color_ThmDark_Text_Active  :: Color {240, 240, 240, 255}

// Light Theme

// LightTheme_BG :: Color { 120, 120, 120, 255 }
