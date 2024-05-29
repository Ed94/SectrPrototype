#version 330 core
in  vec2 TexCoords;
out vec4 color;

uniform sampler2D glyph_bitmap;
uniform vec3      glyph_color;

void main()
{
    vec4 sampled = vec4(1.0, 1.0, 1.0, texture(glyph_bitmap, TexCoords).r);
         color   = vec4(glyph_color, 1.0) * sampled;
}
