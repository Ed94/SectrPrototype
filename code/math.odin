package sectr

// TODO(Ed) : Evaluate if this is needed

vec3 :: vec3_f32
vec3_f32 :: struct #raw_union {
	basis : [3] f32,
	using components : struct {
		x, y, z : f32
	}
}







