@module vefc_draw_text

@header package sectr
@header import sg "thirdparty:sokol/gfx"

@vs vefc_draw_text_vs
in  vec2 v_position;
in  vec2 v_texture;
out vec2 uv;

void main()
{
	uv          = v_texture;
	gl_Position = vec4( v_position.xy * 2.0 - 1.0, 0.0, 1.0 );
}
@end

@fs vefc_draw_text_fs

in  vec2 uv;
out vec4 frag_color;

uniform texture2D vefc_draw_text_src_texture;
uniform sampler   vefc_draw_text_src_sampler;

uniform vefc_draw_text_fs_params {
	int  down_sample;
	vec4 colour;
};

void main()
{
	float alpha = texture(sampler2D( vefc_draw_text_src_texture, vefc_draw_text_src_sampler ), uv ).x;
	if ( down_sample == 1u )
	{
		// TODO(Ed): The original author made these consts, I want to instead expose as uniforms...
		const vec2 texture_size = 1.0 / vec2( 2048.0, 512.0 ); // VEFontCache.Context.buffer_width/buffer_height
		alpha =
			texture(sampler2D( vefc_draw_text_src_texture, vefc_draw_text_src_sampler), uv + vec2( -0.5, -0.5) * texture_size ).x * 0.25
		+	texture(sampler2D( vefc_draw_text_src_texture, vefc_draw_text_src_sampler), uv + vec2( -0.5,  0.5) * texture_size ).x * 0.25
		+	texture(sampler2D( vefc_draw_text_src_texture, vefc_draw_text_src_sampler), uv + vec2(  0.5, -0.5) * texture_size ).x * 0.25
		+	texture(sampler2D( vefc_draw_text_src_texture, vefc_draw_text_src_sampler), uv + vec2(  0.5,  0.5) * texture_size ).x * 0.25;
	}
	frag_color = vec4( colour.xyz, colour.a * alpha );
}
@end

@program vefc_draw_text vefc_draw_text_vs vefc_draw_text_fs
