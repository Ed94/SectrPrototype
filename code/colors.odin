package sectr

import rl "vendor:raylib"

Color       :: rl.Color
Color_Blue  :: rl.BLUE
// Color_Green :: rl.GREEN
Color_Red   :: rl.RED
Color_White :: rl.WHITE

Color_Transparent          :: Color {   0,   0,   0,   0 }
Color_BG                   :: Color {  61,  61,  64, 255 }
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
Color_ResizeHandle         :: Color { 90, 90, 100, 255 }

Color_3D_BG :: Color { 188, 182 , 170, 255 }

Color_Debug_UI_Padding_Bounds :: Color {  40, 195, 170, 160 }
Color_Debug_UI_Content_Bounds :: Color { 170, 120, 240, 160 }
