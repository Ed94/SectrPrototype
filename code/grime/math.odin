package grime

is_power_of_two_u32 :: #force_inline proc "contextless" ( value : u32 ) -> b32
{
	return value != 0 && ( value & ( value - 1 )) == 0
}
