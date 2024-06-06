in  vec2 v_position;
in  vec2 v_texture;
out vec2 uv;

void main()
{
	uv          = v_texture;
	gl_Position = vec4( v_position.xy, 0.0, 1.0 );
}
