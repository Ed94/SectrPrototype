package sectr


InputBindCallback :: #type proc(user_ptr : rawptr)

InputBind :: struct
{


	user_ptr : rawptr,
	callback : InputBindCallback,
}
