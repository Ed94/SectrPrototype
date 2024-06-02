package VEFontCache

import "thirdparty:harfbuzz"

ShaperContext :: struct {
	hb_buffer : harfbuzz.Buffer,
}

ShaperInfo :: struct {
	blob : harfbuzz.Blob,
	face : harfbuzz.Face,
	font : harfbuzz.Font,
}

