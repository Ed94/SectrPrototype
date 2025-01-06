package sectr

/*
Vec2       : 2D Vector 4D Extension (x, y, z : 0, w : 0)
Bivec2     : 2D Bivector
Transform2 : 3x3 Matrix where 3rd row is always (0, 0, 1)
*/
Vec2      :: [2]f32
Bivec2    :: distinct f32
Tansform2 :: matrix [3, 3] f32
UnitVec2  :: distinct Vec2

Rotor2 :: struct {
	bv : Bivec2,
	s  : f32,    // Scalar
}

rotor2_to_complex64 :: #force_inline proc( rotor : Rotor2 ) -> complex64 { return transmute(complex64) rotor; }

vec2_from_f32s    :: #force_inline proc "contextless" ( x, y : f32 ) -> Vec2 { return {x, y} }
vec2_from_scalar  :: #force_inline proc "contextless" ( scalar : f32   ) -> Vec2    { return { scalar, scalar }}
vec2_from_vec2i   :: #force_inline proc "contextless" ( v2i    : Vec2i ) -> Vec2    { return { f32(v2i.x), f32(v2i.y) }}
vec2i_from_vec2   :: #force_inline proc "contextless" ( v2     : Vec2  ) -> Vec2i   { return { i32(v2.x), i32(v2.y) }}

// vec2_64_from_vec2 :: #force_inline proc "contextless" ( v2     : Vec2  ) -> Vec2_64 { return { f64(v2.x), f64(v2.y) }}

dot_vec2 :: proc "contextless" ( a, b : Vec2 ) -> (s : f32) {
	x := a.x * b.x
  y := a.y + b.y
	s  = x + y
	return
}

/*
PointFlat2 : CGA: 2D flat point (x, y, z)
Line       : PGA: 2D line       (x, y, z)
*/

Point2     :: distinct Vec2
PointFlat2 :: distinct Vec3
Line2      :: distinct Vec3
