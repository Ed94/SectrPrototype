// Mask-Step-Index (MSI) Hash Table implementation.
// See: https://nullprogram.com/blog/2022/08/08/
package sectr
// TODO(Ed) : This is a wip, I haven't gotten the nuance of this mess down pact.

// Compute a mask, then a step size, and finally an index.
// The exponent parameter is a power-of-two exponent for the hash-table size.
msi_hmap_lookup :: proc ( hash : u64, exponent, index : u32 ) -> (candidate_index : i32)
{
	mask           := u32(1 << (exponent)) - 1
	step           := u32(hash >> (64 - exponent)) | 1
	candidate_index = i32( (index + step) & mask )
	return
}

HMap_MSI :: struct ( $ Type : typeid, $ Size : u32 )
	where is_power_of_two( Size )
{
	hashes : [ Size ]( ^ Type ),
	length : i32
}

HMap_MSI_Dyn :: struct ( $ Type : typeid ) {
	hashes : Array( DLL_Node( ^ Type ) ),
	size   : u64,
	length : i32,
}
