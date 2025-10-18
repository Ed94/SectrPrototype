package sectr

/*
This is heavy work-in-progress personalized math definitions.

Desire is for the definitions to be from a geo alg / clifford alg lens instead of linear alg.
Want to maximize use of optimal linear alg operations in the defs though already defined by odin's linear alg library.

I apologize if this looks terrible my intuiton for math is very sub-par symbolically.
*/

import     "base:intrinsics"
import     "core:math"
import la  "core:math/linalg"

@private IS_NUMERIC :: intrinsics.type_is_numeric

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
inverse_sqrt_f32 :: proc "contextless" ( value: f32 ) -> f32 {
	if ( value < f32_Min) { return f32_Infinity }
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

is_power_of_two_u32 :: #force_inline proc "contextless" (value: u32) -> b32 { return value != 0 && ( value & ( value - 1 )) == 0 }

mov_avg_exp_f32 := #force_inline proc "contextless" (alpha, delta_interval, last_value: f32) -> f32 { return (delta_interval * alpha) + (delta_interval * (1.0 - alpha)) }
mov_avg_exp_f64 := #force_inline proc "contextless" (alpha, delta_interval, last_value: f64) -> f64 { return (delta_interval * alpha) + (delta_interval * (1.0 - alpha)) }
 
Quat_F4 :: quaternion128
V2_S4   :: [2]i32
V3_S4   :: [3]i32

M2_F4  :: matrix [2, 2] f32        // Column Major
R2_F4  :: struct { p0, p1: V2_F4 } // Column Major (they are equivalnet)
UR2_F4 :: distinct R2_F4

r2f4_zero :: R2_F4 {}

r2f4 :: #force_inline proc "contextless" (a, b: V2_F4) -> R2_F4 { return R2_F4{a, b} }

m2f4_from_r2f4 :: #force_inline proc "contextless" (range: R2_F4) -> M2_F4 { return transmute(M2_F4)range }
r2f4_from_m2f4 :: #force_inline proc "contextless" (m:     M2_F4) -> R2_F4 { return transmute(R2_F4)m }

add_r2f4   :: #force_inline proc "contextless" (a, b: R2_F4) -> R2_F4 { return r2f4_from_m2f4(m2f4_from_r2f4(a) + m2f4_from_r2f4(b)) }
sub_r2f4   :: #force_inline proc "contextless" (a, b: R2_F4) -> R2_F4 { return r2f4_from_m2f4(m2f4_from_r2f4(a) - m2f4_from_r2f4(b)) }
equal_r2f4 :: #force_inline proc "contextless" (a, b: R2_F4) -> b32   { result := a.p0 == b.p0 && a.p1 == b.p1; return b32(result) }

// Will resolve the largest range possible given a & b.
join_r2f4 :: #force_inline proc "contextless" (a, b:  R2_F4) -> (joined : R2_F4) { joined.p0 = min(a.p0, b.p0); joined.p1 = max(a.p1, b.p1); return }
size_r2f4 :: #force_inline proc "contextless" (value: R2_F4) -> V2_F4            { return {abs(value.p1.x - value.p0.x), abs(value.p0.y - value.p1.y) }}

min :: la.min
max :: la.max

sqrt :: la.sqrt

sdot          :: la.scalar_dot
vdot          :: la.vector_dot
qdot_f2       :: la.quaternion64_dot
qdot_f4       :: la.quaternion128_dot
qdot_f8       :: la.quaternion256_dot
inner_product :: dot
outer_product :: intrinsics.outer_product

cross_s  :: la.scalar_cross
cross_v2 :: la.vector_cross2
cross_v3 :: la.vector_cross3

/*
V2_F2:     2D Vector   (4-Byte Float) 4D Extension (x, y, z : 0, w : 0)
BV2_F2:    2D Bivector (4-Byte Float)
T2_F2:     3x3 Matrix  (4-Byte Float) where 3rd row is always (0, 0, 1)
Rotor2_F4: Rotor 2D    (4-Byte Float) s is scalar.
*/
V2_F4     :: [2]f32
BiV2_F4   :: distinct f32
T2_F4     :: matrix [3, 3] f32
UV2_F4    :: distinct V2_F4
Rotor2_F4 :: struct { bv: BiV2_F4, s: f32 } 

rotor2f4_to_complex64 :: #force_inline proc "contextless" (rotor: Rotor2_F4) -> complex64 { return transmute(complex64) rotor; }

v2f4_from_f32s   :: #force_inline proc "contextless" (x, y:   f32  ) -> V2_F4 { return {x, y} }
v2f4_from_scalar :: #force_inline proc "contextless" (scalar: f32  ) -> V2_F4 { return {scalar, scalar}}
v2f4_from_v2s4   :: #force_inline proc "contextless" (v2i:    V2_S4) -> V2_F4 { return {f32(v2i.x), f32(v2i.y)}}
v2s4_from_v2f4   :: #force_inline proc "contextless" (v2:     V2_F4) -> V2_S4 { return {i32(v2.x),  i32(v2.y) }}

/*
PointFlat2 : CGA: 2D flat point (x, y, z)
Line       : PGA: 2D line       (x, y, z)
*/

P2_F4  :: distinct V2_F4
PF2_F4 :: distinct V3_F4
L2_F4  :: distinct V3_F4

/*
V3_F4:    3D Vector    (x, y, z)              (3x1) 4D Expression : (x, y, z, 0)
BiV3_F4:  3D Bivector  (yz, zx, xy)           (3x1)
TriV3_F4: 3D Trivector (xyz)                  (1x1)
Rotor3:   3D Rotation Versor-Transform        (4x1)
Motor3:   3D Rotation & Translation Transform (4x2)
*/

V3_F4 :: [3]f32
V4_F4 :: [4]f32

BiV3_F4 :: struct #raw_union {
	using _   : struct { yz, zx, xy : f32 },
	using xyz : V3_F4,
}

TriV3_F4 :: distinct f32

Rotor3_F4 :: struct {
	using bv: BiV3_F4,
	      s:  f32,     // Scalar
}

Shifter3_F4 :: struct {
	using bv: BiV3_F4,
	      s:  f32,   // Scalar
}

Motor3 :: struct {
	rotor: Rotor3_F4,
	md:    Shifter3_F4,
}

UV3_F4   :: distinct V3_F4
UV4_F4   :: distinct V4_F4
UBiV3_F4 :: distinct BiV3_F4

//region Vec3

v3f4_via_f32s :: #force_inline proc "contextless" (x, y, z: f32) -> V3_F4 { return {x, y, z} }

// complement_vec3 :: #force_inline proc "contextless" ( v : Vec3 ) -> Bivec3 {return transmute(Bivec3) v}

inverse_mag_v3f4 :: #force_inline proc "contextless" (v: V3_F4) -> (result : f32)    { square := pow2_v3f4(v); result = inverse_sqrt_f32( square ); return }
magnitude_v3f4   :: #force_inline proc "contextless" (v: V3_F4) -> (mag:     f32)    { square := pow2_v3f4(v); mag    = sqrt(square);               return }
normalize_v3f4   :: #force_inline proc "contextless" (v: V3_F4) -> (unit_v:  UV3_F4) { unit_v = transmute(UV3_F4) (v * inverse_mag_v3f4(v));        return }

pow2_v3f4 :: #force_inline proc "contextless" (v: V3_F4) -> (s: f32) { return vdot(v, v) }

project_v3f4 :: proc "contextless" (a, b: V3_F4)  -> (a_to_b:   V3_F4) { panic_contextless("not implemented") }
reject_v3f4  :: proc "contextless" (a, b: V3_F4 ) -> (a_from_b: V3_F4) { panic_contextless("not implemented") }

project_v3f4_uv3f4 :: #force_inline proc "contextless" (v: V3_F4,  u: UV3_F4) -> (v_to_u: V3_F4) { inner := vdot(v, v3(u)); v_to_u = v3(u) * inner; return }
project_uv3f4_v3f4 :: #force_inline proc "contextless" (u: UV3_F4, v: V3_F4)  -> (u_to_v: V3_F4) { inner := vdot(v3(u), v); u_to_v = v     * inner; return }

// Anti-wedge of vectors
regress_v3f4 :: #force_inline proc "contextless" (a, b : V3_F4) -> f32 { return a.x * b.y - a.y * b.x }

reject_v3f4_uv3f4 :: #force_inline proc "contextless" (v: V3_F4, u: UV3_F4) -> ( v_from_u: V3_F4) { inner := vdot(v, v3(u)); v_from_u = (v - v3(u)) * inner; return }
reject_uv3f4_v3f4 :: #force_inline proc "contextless" (v: V3_F4, u: UV3_F4) -> ( u_from_v: V3_F4) { inner := vdot(v3(u), v); u_from_v = (v3(u) - v) * inner; return }

// Combines the deimensions that are present in a & b
wedge_v3f4 :: #force_inline proc "contextless" (a, b: V3_F4) -> (bv : BiV3_F4) {
	yzx_zxy := a.yzx * b.zxy
	zxy_yzx := a.zxy * b.yzx
	bv       = transmute(BiV3_F4) (yzx_zxy - zxy_yzx)
	return
}

//endregion Vec3

//region Bivec3
biv3f4_via_f32s :: #force_inline proc "contextless" (yz, zx, xy : f32) -> BiV3_F4 {return { xyz = {yz, zx, xy} }}

complement_biv3f4 :: #force_inline proc "contextless" (b : BiV3_F4) -> BiV3_F4 {return transmute(BiV3_F4) b.xyz} // TODO(Ed): Review this.

//region Operations isomoprhic to vectors
negate_biv3f4      :: #force_inline proc "contextless" (b : BiV3_F4)            -> BiV3_F4  {return transmute(BiV3_F4) -b.xyz}
add_biv3f4         :: #force_inline proc "contextless" (a,          b: BiV3_F4) -> BiV3_F4  {return transmute(BiV3_F4) (a.xyz + b.xyz)}
sub_biv3f4         :: #force_inline proc "contextless" (a,          b: BiV3_F4) -> BiV3_F4  {return transmute(BiV3_F4) (a.xyz - b.xyz)}
mul_biv3f4         :: #force_inline proc "contextless" (a,          b: BiV3_F4) -> BiV3_F4  {return transmute(BiV3_F4) (a.xyz * b.xyz)}
mul_biv3f4_f32     :: #force_inline proc "contextless" (b: BiV3_F4, s: f32)     -> BiV3_F4  {return transmute(BiV3_F4) (b.xyz * s)}
mul_f32_biv3f4     :: #force_inline proc "contextless" (s: f32,     b: BiV3_F4) -> BiV3_F4  {return transmute(BiV3_F4) (s * b.xyz)}
div_biv3f4_f32     :: #force_inline proc "contextless" (b: BiV3_F4, s: f32)     -> BiV3_F4  {return transmute(BiV3_F4) (b.xyz / s)}
inverse_mag_biv3f4 :: #force_inline proc "contextless" (b: BiV3_F4)             -> f32      {return inverse_mag_v3f4(b.xyz)}
magnitude_biv3f4   :: #force_inline proc "contextless" (b: BiV3_F4)             -> f32      {return magnitude_v3f4  (b.xyz)}
normalize_biv3f4   :: #force_inline proc "contextless" (b: BiV3_F4)             -> UBiV3_F4 {return transmute(UBiV3_F4) normalize_v3f4(b.xyz)}
squared_mag_biv3f4 :: #force_inline proc "contextless" (b: BiV3_F4)             -> f32      {return pow2_v3f4(b.xyz)}
//endregion Operations isomoprhic to vectors

// The wedge of a bi-vector in 3D vector space results in a Trivector represented as a scalar.
// This scalar usually resolves to zero with six possible exceptions that lead to the negative volume element.
wedge_biv3f4 :: #force_inline proc "contextless" (a, b: BiV3_F4) -> f32 { s := a.yz + b.yz + a.zx + b.zx + a.xy + b.xy; return s }

// anti-wedge (Combines dimensions that are absent from a & b)
regress_biv3f4      :: #force_inline proc "contextless" (a, b: BiV3_F4)          -> V3_F4 {return wedge_v3f4(v3(a), v3(b))}
regress_biv3f4_v3f4 :: #force_inline proc "contextless" (b: BiV3_F4, v: V3_F4)   -> f32   {return regress_v3f4(b.xyz, v)}
regress_v3_biv3f4   :: #force_inline proc "contextless" (v: V3_F4,   b: BiV3_F4) -> f32   {return regress_v3f4(b.xyz, v)}

//endregion biv3f4

//region Rotor3

rotor3f4_via_comps_f4 :: proc "contextless" (yz, zx, xy, scalar : f32) -> Rotor3_F4 { return Rotor3_F4 {biv3f4_via_f32s(yz, zx, xy), scalar} }

rotor3f4_via_bv_s_f4 :: #force_inline proc "contextless" (bv: BiV3_F4, scalar: f32) -> (rotor : Rotor3_F4) { return Rotor3_F4 {bv, scalar} }
// rotor3f4_via_from_to_v3f4 :: #force_inline proc "contextless" (from, to: V3_F4)          -> (rotor : Rotor3_F4) { rotor.scalar := 1 + dot( from, to ); return }

inverse_mag_rotor3f4 :: #force_inline proc "contextless" (rotor : Rotor3_F4) -> (s : f32)              { panic_contextless("not implemented") }
magnitude_rotor3f4   :: #force_inline proc "contextless" (rotor : Rotor3_F4) -> (s : f32)              { panic_contextless("not implemented") }
squared_mag_f4       :: #force_inline proc "contextless" (rotor : Rotor3_F4) -> (s : f32)              { panic_contextless("not implemented") }
reverse_rotor3_f4    :: #force_inline proc "contextless" (rotor : Rotor3_F4) -> (reversed : Rotor3_F4) { reversed = { negate_biv3f4(rotor.bv), rotor.s }; return }

//endregion Rotor3

//region Flat Projective Geometry

Point3_F4     :: distinct V3_F4
PointFlat3_F4 :: distinct V4_F4
Line3_F4 :: struct {
	weight: V3_F4,
	bulk:   BiV3_F4,
}
Plane3_F4 :: distinct V4_F4 // 4D Anti-vector

// aka: wedge operation for points
join_point3_f4 :: proc "contextless" (p, q : Point3_F4) -> (l : Line3_F4) {
	weight := v3(q) - v3(p)
	bulk   := wedge(v3(p), v3(q))
	l       = {weight, bulk}
	return
}
join_pointflat3_f4 :: proc "contextless" (p, q : PointFlat3_F4) -> (l : Line3_F4) {
	weight := v3f4(
		p.w * q.x - p.x * q.w,
		p.w * q.y - p.y * q.w,
		p.w * q.z - p.z * q.w
	)
	bulk   := wedge(v3(p), v3(q))
	l       = { weight, bulk}
	return
}
sub_point3_f4 :: #force_inline proc "contextless" (a, b : Point3_F4) -> (v : V3_F4) { v = v3f4(a) - v3f4(b); return }

//endregion Flat Projective Geometry

//region Rational Trig

quadrance :: #force_inline proc "contextless" (a, b: Point3_F4) -> (q : f32) { q = pow2_v3f4(v3(a) - v3(b)); return }

// Assumes the weight component is normalized.
spread :: #force_inline proc "contextless" (l, m: Line3_F4) -> (s : f32) { s = vdot(l.weight, m.weight); return }

//endregion Rational Trig

//region Grime
// A dump of equivalent symbol generatioon (because the toolchain can't do it yet)
// Symbol alias tables are in grim.odin

v3f4_to_biv3f4       :: #force_inline proc "contextless" (v:     V3_F4)     -> BiV3_F4 {return transmute(BiV3_F4) v }
biv3f4_to_v3f4       :: #force_inline proc "contextless" (bv:    BiV3_F4)   -> V3_F4   {return transmute(V3_F4)   bv }
quatf4_from_rotor3f4 :: #force_inline proc "contextless" (rotor: Rotor3_F4) -> Quat_F4 {return transmute(Quat_F4) rotor }
uv3f4_to_v3f4        :: #force_inline proc "contextless" (v:     UV3_F4)    -> V3_F4   {return transmute(V3_F4)   v }
uv4f4_to_v4f4        :: #force_inline proc "contextless" (v:     UV4_F4)    -> V4_F4   {return transmute(V4_F4)   v }

// plane_to_v4f4        :: #force_inline proc "contextless" (p : Plane3_F4)     -> V4_F4     {return transmute(V4_F4) p}
point3f4_to_v3f4     :: #force_inline proc "contextless" (p: Point3_F4)     -> V3_F4     {return {p.x, p.y, p.z} }
pointflat3f4_to_v3f4 :: #force_inline proc "contextless" (p: PointFlat3_F4) -> V3_F4     {return {p.x, p.y, p.z} }
v3f4_to_point3f4     :: #force_inline proc "contextless" (v: V3_F4)         -> Point3_F4 {return {v.x, v.y, v.z} }

cross_v3f4_uv3f4 :: #force_inline proc "contextless" (v: V3_F4,  u: UV3_F4) -> V3_F4 {return cross_v3(v, transmute(V3_F4) u)}
cross_u3f4_v3f4  :: #force_inline proc "contextless" (u: UV3_F4, v: V3_F4)  -> V3_F4 {return cross_v3(transmute(V3_F4) u, v)}

dot_v3f4_uv3f4 :: #force_inline proc "contextless" (v:      V3_F4,  unit_v: UV3_F4) -> f32 {return vdot(v, transmute(V3_F4) unit_v)}
dot_uv3f4_v3f4 :: #force_inline proc "contextless" (unit_v: UV3_F4, v:      V3_F4)  -> f32 {return vdot(v, transmute(V3_F4) unit_v)}

wedge_v3f4_uv3f4 :: #force_inline proc "contextless" (v     : V3_F4,  unit_v: UV3_F4) -> BiV3_F4 {return wedge_v3f4(v, v3(unit_v))}
wedge_uv3f4_vs   :: #force_inline proc "contextless" (unit_v: UV3_F4, v:      V3_F4)  -> BiV3_F4 {return wedge_v3f4(v3(unit_v), v)}
//endregion Grime
