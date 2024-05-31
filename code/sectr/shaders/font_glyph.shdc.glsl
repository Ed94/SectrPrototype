@vs font_glyph_vs
in vec2 vertex;
in vec2 texture_coord;

out vec2 uv;

uniform font_glyph_vs_params {
	mat4 projection;
};

void main()
{
	gl_Position = projection * vec4(vertex, 0.0, 1.00);
	uv          = texture_coord;
}
@end

@fs font_glyph_fs
in  vec2 uv;
out vec4 color;

uniform texture2D glyph_bitmap;
uniform sampler   glyph_bitmap_sampler;

uniform font_glyph_fs_params {
	vec3 glyph_color;
};

void main()
{
    float alpha = texture(sampler2D(glyph_bitmap, glyph_bitmap_sampler), uv).r;
    color = vec4(glyph_color, alpha);
}
@end

@program font_glyph font_glyph_vs font_glyph_fs
