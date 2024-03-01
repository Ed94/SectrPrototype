package sectr

is_power_of_two_u32 :: proc( value : u32 ) -> b32
{
	return value != 0 && ( value & ( value - 1 )) == 0
}

import "core:math/linalg"

Vec2 :: linalg.Vector2f32
Vec3 :: linalg.Vector3f32

Vec2i :: [2]i32
Vec3i :: [3]i32
