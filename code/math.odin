package sectr

Axis2 :: enum i32 {
	Invalid = -1,
	X       = 0,
	Y       = 1,
	Count,
}

is_power_of_two_u32 :: #force_inline proc "contextless" ( value : u32 ) -> b32
{
	return value != 0 && ( value & ( value - 1 )) == 0
}

mov_avg_exp_f32 := #force_inline proc "contextless" ( alpha, delta_interval, last_value : f32 ) -> f32
{
	result := (delta_interval * alpha) + (delta_interval * (1.0 - alpha))
	return result
}

mov_avg_exp_f64 := #force_inline proc "contextless" ( alpha, delta_interval, last_value : f64 ) -> f64
{
	result := (delta_interval * alpha) + (delta_interval * (1.0 - alpha))
	return result
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

range2 :: #force_inline proc "contextless" ( a, b : Vec2 ) -> Range2 {
	result := Range2 { pts = { a, b } }
	return result
}

add_range2 :: #force_inline proc "contextless" ( a, b : Range2 ) -> Range2 {
	result := Range2 { pts = {
		a.p0 + b.p0,
		a.p1 + b.p1,
	}}
	return result
}

equal_range2 :: #force_inline proc "contextless" ( a, b : Range2 ) -> b32 {
	result := a.p0 == b.p0 && a.p1 == b.p1
	return b32(result)
}

size_range2 :: #force_inline proc "contextless" ( value : Range2 ) -> Vec2 {
	return { value.p1.x - value.p0.x, value.p0.y - value.p1.y }
}
