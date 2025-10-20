package grime

StrKey_U4 :: struct {
	len:    u32, // Length of string
	offset: u32, // Offset in varena
}

StrKT_U4_Cell_Depth :: 4

StrKT_U4_Slot  :: KT1CX_Slot(StrKey_U4)
StrKT_U4_Cell  :: KT1CX_Cell(StrKT_U4_Slot, 4)
StrKT_U4_Table :: KT1CX(StrKT_U4_Cell)

VStrKT_U4 :: struct {
	varena:  VArena, // Backed by growing vmem
	entries: StrKT_U4_Table
}

vstrkt_u4_init :: proc(varena: ^VArena) -> (cache: ^VStrKT_U4)
{
	return nil
}

vstrkt_u4_intern :: proc(cache: ^VStrKT_U4) -> StrKey_U4
{
	// profile(#procedure)
	return {}
}
