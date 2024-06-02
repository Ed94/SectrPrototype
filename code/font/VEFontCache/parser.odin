package VEFontCache

import stbtt    "vendor:stb/truetype"
import freetype "thirdparty:freetype"

ParserKind :: enum u32 {
	stb_true_type,
	freetype,
}

ParserInfo :: struct #raw_union {
		stbtt_info    : stbtt.fontinfo,
		freetype_info : freetype.Face
}

ParserContext :: struct {
	ft_library : freetype.Library
}

