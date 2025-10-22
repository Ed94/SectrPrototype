package grime

VSlabSizeClass :: struct {
	vmem_reserve:    uint,
	block_size:      uint,
	block_alignment: uint,
}

Slab_Max_Size_Classes :: 24

SlabPolicy :: FStack(VSlabSizeClass, Slab_Max_Size_Classes)

VSlab :: struct {
	pools: FStack(VPool, Slab_Max_Size_Classes),
}
