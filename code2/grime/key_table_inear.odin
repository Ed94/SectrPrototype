package grime

/*
Key Table 1-Layer Linear (KT1L)

Mainly intended for doing linear lookup of key-paried values. IE: Arg value parsing with label ids.
The table is built in one go from the key-value pairs. The default populate slice_a2 has the key and value as the same type.
*/

KTL_Slot :: struct($Type: typeid) {
	key:   u64,
	value: Type,
}
KTL_Meta :: struct {
	slot_size:       int,
	kt_value_offset: int,
	type_width:      int,
	type:            typeid,
}

ktl_get :: #force_inline proc "contextless" (kt: []KTL_Slot($Type), key: u64) -> ^Type { 
	for & slot in kt { if key == slot.key do return & slot.value; }
	return nil 
}

// Unique populator for key-value pair strings

ktl_populate_slice_a2_str :: #force_inline proc(kt: ^[]KTL_Slot(string), backing: Odin_Allocator, values: [][2]string) {
	assert(kt != nil)
	if len(values) == 0 { return }
	raw_bytes, error := mem_alloc(size_of(KTL_Slot(string)) * len(values), ainfo = backing); assert(error == .None);
	kt^               = slice( transmute([^]KTL_Slot(string)) cursor(raw_bytes), len(raw_bytes) / size_of(KTL_Slot(string)) )
	for id in 0 ..< len(values) {
		mem_copy(& kt[id].value, & values[id][1], size_of(string))
		hash64_fnv1a(& kt[id].key, transmute([]byte) values[id][0])
	}
}
