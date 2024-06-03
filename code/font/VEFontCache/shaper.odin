package VEFontCache

import "core:c"
import "thirdparty:harfbuzz"

ShaperKind :: enum {
	Naive    = 0,
	Harfbuzz = 1,
}

ShaperContext :: struct {
	hb_buffer : harfbuzz.Buffer,

	infos : HMapChained(ShaperInfo),
}

ShaperInfo :: struct {
	blob : harfbuzz.Blob,
	face : harfbuzz.Face,
	font : harfbuzz.Font,
}

shaper_init :: proc( ctx : ^ShaperContext )
{
	ctx.hb_buffer = harfbuzz.buffer_create()
}

shaper_shutdown :: proc( ctx : ^ShaperContext )
{
	if ctx.hb_buffer != nil {
		harfbuzz.buffer_destory( ctx.hb_buffer )
	}
}

shaper_load_font :: proc( ctx : ^ShaperContext, label : string, data : []byte, user_data : rawptr ) -> (info : ^ShaperInfo)
{
	key := font_key_from_label( label )
	info = get( ctx.infos, key )
	if info != nil do return

	error : AllocatorError
	info, error = set( ctx.infos, key, ShaperInfo {} )
	assert( error != .None, "VEFontCache.parser_load_font: Failed to set a new shaper info" )

	using info
	blob = harfbuzz.blob_create( raw_data(data), cast(c.uint) len(data), harfbuzz.Memory_Mode.READONLY, user_data, nil )
	face = harfbuzz.face_create( blob, 0 )
	font = harfbuzz.font_create( face )
	return
}

shaper_unload_font :: proc( ctx : ^ShaperInfo )
{
	using ctx
	if blob != nil do harfbuzz.font_destroy( font )
	if face != nil do harfbuzz.face_destroy( face )
	if blob != nil do harfbuzz.blob_destroy( blob )
}
