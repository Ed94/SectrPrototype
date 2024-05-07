package sectr

// GrimeContextExt :: struct {
// 	dbg_name : string
// }

// Global_Transient_Context : GrimeContextExt

context_ext :: proc( $ Type : typeid ) -> (^Type) {
	return cast(^Type) context.user_ptr
}

