package sectr

Axis2 :: enum i32 {
	Invalid = -1,
	X       = 0,
	Y       = 1,
	Count,
}

is_power_of_two_u32 :: proc( value : u32 ) -> b32
{
	return value != 0 && ( value & ( value - 1 )) == 0
}

import "core:math/linalg"

Vec2 :: linalg.Vector2f32
Vec3 :: linalg.Vector3f32

Vec2i :: [2]i32
Vec3i :: [3]i32

Range2 :: struct #raw_union{
	using min_max : struct {
		min, max : Vec2
	},
	using pts : struct {
		p0, p1 : Vec2
	},
	using xy : struct {
		x0, y0 : f32,
		x1, y1 : f32,
	},
}

Rect :: struct {
	top_left, bottom_right : Vec2
}
