package sectr

import "core:math/linalg"

Vec2 :: linalg.Vector2f32
Vec3 :: linalg.Vector3f32





when false {
// TODO(Ed) : Evaluate if this is needed

Vec2 :: Vec2_f32
Vec2_f32 :: struct #raw_union {
	basis : [2] f32,
	using components : struct {
		x, y : f32
	}
}

// make_vec2 :: proc ( x, y : f32 ) {

// }

Vec3 :: Vec3_f32
Vec3_f32 :: struct #raw_union {
	basis : [3] f32,
	using components : struct {
		x, y, z : f32
	}
}
}




