package grime

StrKey_U4 :: struct {
	len:    u32, // Length of string
	offset: u32, // Offset in varena
}

StrKT_U4_Cell_Depth :: 4

StrKT_U4_Slot  :: KTCX_Slot(StrKey_U4)
StrKT_U4_Cell  :: KTCX_Cell(StrKT_U4_Slot, 4)
StrKT_U4_Table :: KTCX(StrKT_U4_Cell)

VStrKT_U4 :: struct {
	varena: VArena, // Backed by growing vmem
	kt:     StrKT_U4_Table,
}

vstrkt_u4_init :: proc(varena: ^VArena, capacity: int, cache: ^VStrKT_U4)
{
	capacity := cast(int) closest_prime(cast(uint) capacity)
	ktcx_init(capacity, varena_allocator(varena), &cache.kt)
	return
}

vstrkt_u4_intern :: proc(cache: ^VStrKT_U4) -> StrKey_U4
{
	// profile(#procedure)
	return {}
}
