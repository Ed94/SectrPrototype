@vs glyph_vs
in vec4 vertex; // <vec2 pos, vec2 tex>

out vec2 uv;

uniform vs_params {
	mat4 projection;
};

void main()
{
	gl_Position = projection * vec4(vertex.xy, 0.0, 1.00);
	uv          = vertex.zw;
}
@end

@fs glyph_fs
in  vec2 uv;
out vec4 color;

uniform texture2D glyph_bitmap;
uniform sampler   glyph_bitmap_sampler;

uniform fs_params {
	vec3 glyph_color;
};

void main()
{
    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(sampler2D(glyph_bitmap, glyph_bitmap_sampler), uv).r);
    color = vec4(glyph_color, 1.0) * sampled;

    // float alpha = texture( sampler2D(glyph_bitmap, glyph_bitmap_sampler), uv).r;
    	  // color = vec4(glyph_color, alpha);
}
@end

@program learngl_font_glyph glyph_vs glyph_fs
