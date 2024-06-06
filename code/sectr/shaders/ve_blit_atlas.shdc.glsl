@module vefc_blit_atlas

@header package sectr
@header import sg "thirdparty:sokol/gfx"

@vs vefc_blit_atlas_vs
@include ./ve_source_shared.shdc.glsl
@end

@fs vefc_blit_atlas_fs
in  vec2 uv;
out vec4 frag_color;

uniform texture2D vefc_blit_atlas_src_texture;
uniform sampler   vefc_blit_atlas_src_sampler;

uniform vefc_blit_atlas_fs_params {
	int region;
};

float down_sample( vec2 uv, vec2 texture_size )
{
	float value =
		texture(sampler2D( vefc_blit_atlas_src_texture, vefc_blit_atlas_src_sampler ), uv + vec2( 0.0, 0.0 ) * texture_size ).x * 0.25
	+	texture(sampler2D( vefc_blit_atlas_src_texture, vefc_blit_atlas_src_sampler ), uv + vec2( 0.0, 1.0 ) * texture_size ).x * 0.25
	+	texture(sampler2D( vefc_blit_atlas_src_texture, vefc_blit_atlas_src_sampler ), uv + vec2( 1.0, 0.0 ) * texture_size ).x * 0.25
	+	texture(sampler2D( vefc_blit_atlas_src_texture, vefc_blit_atlas_src_sampler ), uv + vec2( 1.0, 1.0 ) * texture_size ).x * 0.25;
	return value;
}

void main()
{
	// TODO(Ed): The original author made these consts, I want to instead expose as uniforms...
	const vec2 texture_size = 1.0 / vec2( 2048, 512 ); // VEFontCache.Context.buffer_width/buffer_height
	if ( region == 0u || region == 1u || region == 2u )
	{
		float alpha =
			down_sample( uv + vec2( -1.0, -1.5 ) * texture_size, texture_size ) * 0.25
		+	down_sample( uv + vec2(  0.5, -1.5 ) * texture_size, texture_size ) * 0.25
		+	down_sample( uv + vec2( -1.5,  0.5 ) * texture_size, texture_size ) * 0.25
		+	down_sample( uv + vec2(  0.5,  0.5 ) * texture_size, texture_size ) * 0.25;
		frag_color = vec4( 1.0, 1.0, 1.0, alpha );
	}
	else
	{
		frag_color = vec4( 0, 0, 0, 1.0 );
	}
}
@end

@program vefc_blit_atlas vefc_blit_atlas_vs vefc_blit_atlas_fs
