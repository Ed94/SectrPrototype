package sectr

// A dump of equivalent symbol generatioon (because the toolchain can't do it)
// Symbol alias tables are in grim.odin

vec3_to_bivec     :: #force_inline proc "contextless" (v     : Vec3)     -> Bivec3  {return transmute(Bivec3)  v    }
bivec3_to_vec3    :: #force_inline proc "contextless" (bv    : Bivec3)   -> Vec3    {return transmute(Vec3)    bv   }
rotor3_to_quat128 :: #force_inline proc "contextless" (rotor : Rotor3)   -> Quat128 {return transmute(Quat128) rotor}
unitvec3_to_vec3  :: #force_inline proc "contextless" (v     : UnitVec3) -> Vec3    {return transmute(Vec3)    v    }
unitvec4_to_vec4  :: #force_inline proc "contextless" (v     : UnitVec4) -> Vec4    {return transmute(Vec4)    v    }

plane_to_vec4      :: #force_inline proc "contextless" (p : Plane3)     -> Vec4   {return transmute(Vec4)   p}
point3_to_vec3     :: #force_inline proc "contextless" (p : Point3)     -> Vec3   {return transmute(Vec3)   p}
pointflat3_to_vec3 :: #force_inline proc "contextless" (p : PointFlat3) -> Vec3   {return { p.x, p.y, p.z }}
vec3_to_point3     :: #force_inline proc "contextless" (v : Vec3)       -> Point3 {return transmute(Point3) v}

cross_v3_unitv3 :: #force_inline proc "contextless" (v : Vec3, u : UnitVec3) -> Vec3 {return cross_vec3(v, transmute(Vec3) u)}
cross_unitv3_vs :: #force_inline proc "contextless" (u : UnitVec3, v : Vec3) -> Vec3 {return cross_vec3(transmute(Vec3) u, v)}

dot_v3_unitv3 :: #force_inline proc "contextless" (v      : Vec3,    unit_v : UnitVec3) -> f32 {return dot_vec3(v, transmute(Vec3) unit_v)}
dot_unitv3_vs :: #force_inline proc "contextless" (unit_v : UnitVec3, v     : Vec3)     -> f32 {return dot_vec3(v, transmute(Vec3) unit_v)}

wedge_v3_unitv3 :: #force_inline proc "contextless" (v      : Vec3,     unit_v : UnitVec3) -> Bivec3 {return wedge_vec3(v, transmute(Vec3) unit_v)}
wedge_unitv3_vs :: #force_inline proc "contextless" (unit_v : UnitVec3, v      : Vec3)     -> Bivec3 {return wedge_vec3(transmute(Vec3) unit_v, v)}
