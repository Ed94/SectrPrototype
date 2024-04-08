// General mathematical constructions used for the prototype

package sectr

import "core:math"

Axis2 :: enum i32 {
	Invalid = -1,
	X       = 0,
	Y       = 1,
	Count,
}

f32_Infinity :: 0x7F800000
f32_Min      :: 0x00800000

// Note(Ed) : I don't see an intrinsict available anywhere for this. So I'll be using the Terathon non-sse impl
// Inverse Square Root
// C++ Source https://github.com/EricLengyel/Terathon-Math-Library/blob/main/TSMath.cpp#L191
inverse_sqrt_f32 :: proc "contextless" ( value : f32 ) -> f32
{
	if ( value < f32_Min) {
		return f32_Infinity
	}

	value_u32 := transmute(u32) value

	initial_approx := 0x5F375A86 - (value_u32 >> 1)
	refined_approx := transmute(f32) initial_approx

	// Newton–Raphson method for getting better approximations of square roots
	// Done twice for greater accuracy.
	refined_approx  = refined_approx * (1.5 - value * 0.5 * refined_approx * refined_approx )
	refined_approx  = refined_approx * (1.5 - value * 0.5 * refined_approx * refined_approx )
	// refined_approx = (0.5 * refined_approx) * (3.0 - value * refined_approx * refined_approx)
	// refined_approx = (0.5 * refined_approx) * (3.0 - value * refined_approx * refined_approx)
	return refined_approx
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

Quat128 :: quaternion128
Matrix2 :: matrix [2, 2] f32
Vec2i   :: [2]i32
Vec3i   :: [3]i32

vec2i_to_vec2 :: #force_inline proc "contextless" (v : Vec2i) -> Vec2 {return transmute(Vec2) v}
vec3i_to_vec3 :: #force_inline proc "contextless" (v : Vec3i) -> Vec3 {return transmute(Vec3) v}

//region Range2

Range2 :: struct #raw_union {
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

	// TODO(Ed) : Test these
	array : [4]f32,
	mat   : matrix[2, 2] f32,
}

UnitRange2 :: distinct Range2

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

sub_range2 :: #force_inline proc "contextless" ( a, b : Range2 ) -> Range2 {
	// result := Range2 { array = a.array - b.array }
	result := Range2 { mat = a.mat - b.mat }
	return result
}

equal_range2 :: #force_inline proc "contextless" ( a, b : Range2 ) -> b32 {
	result := a.p0 == b.p0 && a.p1 == b.p1
	return b32(result)
}

size_range2 :: #force_inline proc "contextless" ( value : Range2 ) -> Vec2 {
	return { value.p1.x - value.p0.x, value.p0.y - value.p1.y }
}

//endregion Range2
