package sectr

/*
Vec3    : 3D Vector    (x, y, z)              (3x1) 4D Expression : (x, y, z, 0)
Bivec3  : 3D Bivector  (yz, zx, xy)           (3x1)
Trivec3 : 3D Trivector (xyz)                  (1x1)
Rotor3  : 3D Rotation Versor-Transform        (4x1)
Motor3  : 3D Rotation & Translation Transform (4x2)
*/

Vec3     :: [3]f32
Vec4     :: [4]f32

Bivec3 :: struct #raw_union {
	using _   : struct { yz, zx, xy : f32 },
	using xyz : Vec3,
}

Trivec3 :: distinct f32

Rotor3 :: struct {
	using bv : Bivec3,
	      s  : f32,     // Scalar
}

Shifter3 :: struct {
	using bv : Bivec3,
	      s  : f32,    // Scalar
}

Motor3 :: struct {
	rotor : Rotor3,
	md    : Shifter3,
}

UnitVec3   :: distinct Vec3
UnitVec4   :: distinct Vec4
UnitBivec3 :: distinct Bivec3

//region Vec3

complement_vec3 :: #force_inline proc "contextless" ( v : Vec3 ) -> Bivec3 {return transmute(Bivec3) v}

cross_vec3 :: proc "contextless" (a, b : Vec3) -> (v : Vec3) {
	v = vec3( wedge(a, b))
	return
}

dot_vec3 :: proc "contextless" ( a, b : Vec3 ) -> (s : f32) {
	mult := a * b // array multiply
	s     = mult.x + mult.y + mult.z
	return
}

inverse_mag_vec3 :: proc "contextless" (v : Vec3) -> (result : f32) {
	square := pow2(v)
	result  = inverse_sqrt( square )
	return
}

magnitude_vec3 :: proc "contextless" (v : Vec3) -> (mag : f32) {
	square := pow2(v)
	mag     = sqrt(square)
	return
}

normalize_vec3 :: proc "contextless" (v : Vec3) -> (unit_v : UnitVec3) {
	unit_v = transmute(UnitVec3) (v * inverse_mag(v))
	return
}

pow2_vec3 :: #force_inline proc "contextless" ( v : Vec3 ) -> (s : f32) {	return dot(v, v) }

project_vec3 :: proc "contextless" ( a, b : Vec3 ) -> ( a_to_b : Vec3 ) {
	return
}

reject_vec3 :: proc "contextless" ( a, b : Vec3 ) -> ( a_from_b : Vec3 ) {
	return
}

project_v3_unitv3 :: proc "contextless" ( v : Vec3, u : UnitVec3 ) -> (v_to_u : Vec3) {
	inner := dot(v, u)
	v_to_u = (transmute(Vec3) u) * inner
	return
}
project_unitv3_v3 :: #force_inline proc "contextless" (u : UnitVec3, v : Vec3) -> (u_to_v : Vec3) {
	inner := dot(u, v)
	u_to_v = v * inner
	return
}

regress_vec3 :: proc "contextless" ( a, b : Vec3 ) -> f32 {
	return a.x * b.y - a.y * 
}

reject_v3_unitv3 :: proc "contextless" ( v : Vec3, u : UnitVec3 ) -> ( v_from_u : Vec3) {
	inner   := dot(v, u)
	v_from_u = (v - (transmute(Vec3) u)) * inner
	return
}
reject_unitv3_v3 :: proc "contextless" ( v : Vec3, u : UnitVec3 ) -> ( u_from_v : Vec3) {
	inner   := dot(u, v)
	u_from_v = ((transmute(Vec3) u) - v) * inner
	return
}

// Combines the deimensions that are present in a & b
wedge_vec3 :: proc "contextless" (a, b : Vec3) -> (bv : Bivec3) {
	yzx_zxy := a.yzx * b.zxy
	zxy_yzx := a.zxy * b.yzx
	bv       = transmute(Bivec3) (yzx_zxy - zxy_yzx)
	return
}

//endregion Vec3

//region Bivec3
bivec_from_f32s :: #force_inline proc "contextless" (yz, zx, xy : f32) -> Bivec3 {return { xyz = {yz, zx, xy} }}

complement_bivec3 :: #force_inline proc "contextless" (b : Bivec3) -> Bivec3 {return b.xyz}

//region Operations isomoprhic to vectors
negate_bivec3      :: #force_inline proc "contextless" (b : Bivec3)             -> Bivec3     {return transmute(Bivec3) -b.xyz}
add_bivec3         :: #force_inline proc "contextless" (a,          b : Bivec3) -> Bivec3     {return transmute(Bivec3) (a.xyz + b.xyz)}
sub_bivec3         :: #force_inline proc "contextless" (a,          b : Bivec3) -> Bivec3     {return transmute(Bivec3) (a.xyz - b.xyz)}
mul_bivec3         :: #force_inline proc "contextless" (a,          b : Bivec3) -> Bivec3     {return transmute(Bivec3) (a.xyz * b.xyz)}
mul_bivec3_f32     :: #force_inline proc "contextless" (b : Bivec3, s : f32)    -> Bivec3     {return transmute(Bivec3) (b.xyz * s)}
mul_f32_bivec3     :: #force_inline proc "contextless" (s : f32,    b : Bivec3) -> Bivec3     {return transmute(Bivec3) (s * b.xyz)}
div_bivec3_f32     :: #force_inline proc "contextless" (b : Bivec3, s : f32)    -> Bivec3     {return transmute(Bivec3) (b.xyz / s)}
inverse_mag_bivec3 :: #force_inline proc "contextless" (b : Bivec3)             -> f32        {return transmute(Bivec3) inverse_mag_vec3(b.xyz)}
magnitude_bivec3   :: #force_inline proc "contextless" (b : Bivec3)             -> f32        {return transmute(Bivec3) magnitude_vec3  (b.xyz)}
normalize_bivec3   :: #force_inline proc "contextless" (b : Bivec3)             -> UnitBivec3 {return transmute(Bivec3) normalize_vec3  (b.xyz)}
squared_mag_bivec3 :: #force_inline proc "contextless" (b : Bivec3)             -> f32        {return transmute(Bivec3) pow_2_vec3      (b.xyz)}
//endregion Operations isomoprhic to vectors

// anti-wedge (Combines dimensions that are absent from a & b)
regress_bivec3      :: #force_inline proc "contextless" ( a, b : Bivec3 ) -> Vec3 {return wedge(vec3(a), vec3(b))}
// regress_bivec3_v  :: #force_inline proc "contextless" (b : Bivec3, v : Vec3) -> f32  {return regress(b.xyz, v)}
// regress_v3_bivec3 :: #force_inline proc "contextless" (v : Vec3, b : Bivec3) -> f32  {return regress(b.xyz, v)}

//endregion Bivec3

//region Rotor3

rotor3_via_comps :: proc "contextless" (yz, zx, xy, scalar : f32) -> (rotor : Rotor3) {
	rotor = Rotor3 {bivec(yz, zx, xy), scalar}
	return
}

rotor3_via_bv_s :: proc "contextless" (bv : Bivec3, scalar : f32) -> (rotor : Rotor3) {
	rotor = Rotor3 {bv, scalar}
	return
}

rotor3_via_from_to :: proc "contextless" ( from, to : Vec3 ) -> (rotor : Rotor3) {
	scalar := 1 + dot( from, to )
	return
}

inverse_mag_rotor3 :: proc "contextless" (rotor : Rotor3) -> (s : f32) {
	return
}

magnitude_rotor3 :: proc "contextless" (rotor : Rotor3) -> (s : f32) {
	return
}

squared_mag :: proc "contextless" (rotor : Rotor3) -> (s : f32) {
	return
}

reverse_rotor3 :: proc "contextless" (rotor : Rotor3) -> (reversed : Rotor3) {
	reversed = { negate(rotor.bv), rotor.s }
	return
}

//endregion Rotor3

//region Flat Projective Geometry

Point3     :: distinct Vec3
PointFlat3 :: distinct Vec4
Line3  :: struct {
	weight : Vec3,
	bulk   : Bivec3,
}
Plane3 :: distinct Vec4 // 4D Anti-vector

// aka: wedge operation for points
join_point3 :: proc "contextless" (p, q : Point3) -> (l : Line3) {
	weight := sub(q, p)
	bulk   := wedge(to_vec3(p), to_vec3(q))
	l       = {weight, bulk}
	return
}

join_pointflat3 :: proc "contextless" (p, q : PointFlat3) -> (l : Line3) {
	weight := p.w * q - p * q.w
	bulk   := wedge(vec3(p), vec3(q))
	l       = {weight, bulk}
	return
}

sub_point3 :: proc "contextless" (a, b : Point3) -> (v : Vec3) {
	v = to_vec3(a) - to_vec3(b)
	return
}

//endregion Flat Projective Geometry

//region Rational Trig

quadrance :: proc "contextless" (a, b : Point3) -> (q : f32) {
	q = pow2( sub(a, b))
	return
}

// Assumes the weight component is normalized.
spread :: proc "contextless" (l, m : Line3) -> (s : f32) {
	s = dot(l.weight, m.weight)
	return
}

//endregion Rational Trig
