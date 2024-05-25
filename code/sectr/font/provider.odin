package sectr

Font_Largest_Px_Size :: 32

Font_Size_Interval :: 2

// Font_Default :: ""
Font_Default            :: FontID { 0, "" }
Font_Default_Point_Size :: 18.0

Font_TTF_Default_Chars_Padding :: 4

Font_Load_Use_Default_Size :: -1
Font_Load_Gen_ID           :: ""

Font_Atlas_Packing_Method :: enum u32 {
	Raylib_Basic  = 0, // Basic packing algo
	Skyeline_Rect = 1, // stb_pack_rect
}

FontID  :: struct {
	key   : u64,
	label : string,
}
FontTag :: struct {
	key        : FontID,
	point_size : f32
}

FontDef :: struct {
	placeholder : int,
}

FontProviderData :: struct {
	font_cache : HMapChainedPtr(FontDef),
}

font_provider_startup :: proc()
{

}

font_provider_shutdown :: proc()
{

}

font_load :: proc(ath_file : string,
	default_size : f32    = Font_Load_Use_Default_Size,
	desired_id   : string = Font_Load_Gen_ID
) -> FontID
{
	profile(#procedure)

	return {}
}
