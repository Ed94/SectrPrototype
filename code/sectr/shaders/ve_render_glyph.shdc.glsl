@module ve_render_glyph

@header package sectr
@header import sg "thirdparty:sokol/gfx"

@vs ve_render_glyph_vs
@include ./ve_source_shared.shdc.glsl
@end

@fs ve_render_glyph_fs
in  vec2 uv;
out vec4 frag_color;

void main()
{
	frag_color = vec4( 1.0, 1.0, 1.0, 1.0 );
}
@end

@program ve_render_glyph ve_render_glyph_vs ve_render_glyph_fs
