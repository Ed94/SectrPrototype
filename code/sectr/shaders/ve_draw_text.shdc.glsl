@module ve_draw_text

@header package sectr
@header import sg "thirdparty:sokol/gfx"

@vs ve_draw_text_vs
in  vec2 v_position;
in  vec2 v_texture;
out vec2 uv;

void main()
{
	uv          = vec2( v_texture.x, 1 - v_texture.y );
	gl_Position = vec4( v_position * 2.0f - 1.0f, 0.0f, 1.0f );
}
@end

@fs ve_draw_text_fs
in  vec2 uv;
out vec4 frag_color;

layout(binding = 0) uniform texture2D ve_draw_text_src_texture;
layout(binding = 0) uniform sampler   ve_draw_text_src_sampler;

layout(binding = 0) uniform ve_draw_text_fs_params {
	int  down_sample;
	vec4 colour;
};

void main()
{
	float alpha = texture(sampler2D( ve_draw_text_src_texture, ve_draw_text_src_sampler ), uv ).x;
	if ( down_sample == 1 )
	{
		// TODO(Ed): The original author made these consts, I want to instead expose as uniforms...
		const vec2 texture_size = 1.0f / vec2( 2048.0f, 512.0f ); // VEFontCache.Context.buffer_width/buffer_height
		alpha =
			(texture(sampler2D( ve_draw_text_src_texture, ve_draw_text_src_sampler), uv + vec2( -0.5f, -0.5f) * texture_size ).x * 0.25f)
		+	(texture(sampler2D( ve_draw_text_src_texture, ve_draw_text_src_sampler), uv + vec2( -0.5f,  0.5f) * texture_size ).x * 0.25f)
		+	(texture(sampler2D( ve_draw_text_src_texture, ve_draw_text_src_sampler), uv + vec2(  0.5f, -0.5f) * texture_size ).x * 0.25f)
		+	(texture(sampler2D( ve_draw_text_src_texture, ve_draw_text_src_sampler), uv + vec2(  0.5f,  0.5f) * texture_size ).x * 0.25f);
	}
	frag_color = vec4( colour.xyz, colour.a * alpha );
}
@end

@program ve_draw_text ve_draw_text_vs ve_draw_text_fs
