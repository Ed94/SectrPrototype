@module ve_blit_atlas

@header package sectr
@header import sg "thirdparty:sokol/gfx"

@vs ve_blit_atlas_vs
@include ./ve_source_shared.shdc.glsl
@end

@fs ve_blit_atlas_fs
in  vec2 uv;
out vec4 frag_color;

layout(binding = 0) uniform texture2D ve_blit_atlas_src_texture;
layout(binding = 0) uniform sampler   ve_blit_atlas_src_sampler;

layout(binding = 0) uniform ve_blit_atlas_fs_params {
	int region;
};

float down_sample( vec2 uv, vec2 texture_size )
{
	float down_sample_scale = 1.0f / 4.0f;

	float value =
		texture(sampler2D( ve_blit_atlas_src_texture, ve_blit_atlas_src_sampler ), uv + vec2( 0.0f, 0.0f ) * texture_size ).x * down_sample_scale
	+	texture(sampler2D( ve_blit_atlas_src_texture, ve_blit_atlas_src_sampler ), uv + vec2( 0.0f, 1.0f ) * texture_size ).x * down_sample_scale
	+	texture(sampler2D( ve_blit_atlas_src_texture, ve_blit_atlas_src_sampler ), uv + vec2( 1.0f, 0.0f ) * texture_size ).x * down_sample_scale
	+	texture(sampler2D( ve_blit_atlas_src_texture, ve_blit_atlas_src_sampler ), uv + vec2( 1.0f, 1.0f ) * texture_size ).x * down_sample_scale;
	return value;
}

void main()
{
	// TODO(Ed): The original author made these consts, I want to instead expose as uniforms...
	const vec2 texture_size = 1.0f / vec2( 2048.0f, 512.0f ); // VEFontCache.Context.buffer_width/buffer_height
	if ( region == 0 || region == 1 || region == 2 )
	{
		float down_sample_scale = 1.0f / 4.0f;

		float alpha =
			down_sample( uv + vec2( -1.0f, -1.5f ) * texture_size, texture_size ) * down_sample_scale
		+	down_sample( uv + vec2(  0.5f, -1.5f ) * texture_size, texture_size ) * down_sample_scale
		+	down_sample( uv + vec2( -1.5f,  0.5f ) * texture_size, texture_size ) * down_sample_scale
		+	down_sample( uv + vec2(  0.5f,  0.5f ) * texture_size, texture_size ) * down_sample_scale;
		frag_color = vec4( 1.0f, 1.0f, 1.0f, alpha );
	}
	else
	{
		frag_color = vec4( 0.0f, 0.0f, 0.0f, 1.0 );
	}
}
@end

@program ve_blit_atlas ve_blit_atlas_vs ve_blit_atlas_fs
