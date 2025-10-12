package grime

/*
Key Table 1-Layer Linear (KT1L)
*/

KT1L_Slot :: struct($Type: typeid) {
	key:   u64,
	value: Type,
}
KT1L_Meta :: struct {
	slot_size:       uintptr,
	kt_value_offset: uintptr,
	type_width:      uintptr,
	type:            typeid,
}
kt1l_populate_slice_a2_Slice_Byte :: proc(kt: ^[]byte, backing: AllocatorInfo, values: []byte, num_values: int, m: KT1L_Meta) {
	assert(kt != nil)
	if num_values == 0 { return }
	table_size_bytes := num_values * int(m.slot_size)
	kt^               = mem_alloc(table_size_bytes, ainfo = transmute(Odin_Allocator) backing)
	slice_assert(kt ^)
	kt_raw : SliceByte = transmute(SliceByte) kt^
	for id in 0 ..< cast(uintptr) num_values {
		slot_offset := id * m.slot_size                                        // slot id
		slot_cursor := kt_raw.data[slot_offset:]                               // slots[id]            type: KT1L_<Type>
		// slot_key    := transmute(^u64) slot_cursor                          // slots[id].key        type: U64
		// slot_value  := slice(slot_cursor[m.kt_value_offset:], m.type_width) // slots[id].value      type: <Type>
		a2_offset   := id * m.type_width * 2                                   // a2 entry id
		a2_cursor   := cursor(values)[a2_offset:]                              // a2_entries[id]       type: A2_<Type>
		// a2_key      := (transmute(^[]byte) a2_cursor) ^                     // a2_entries[id].key   type: <Type>
		// a2_value    := slice(a2_cursor[m.type_width:], m.type_width)        // a2_entries[id].value type: <Type>
		mem_copy_non_overlapping(slot_cursor[m.kt_value_offset:], a2_cursor[m.type_width:], cast(int) m.type_width) // slots[id].value = a2_entries[id].value
		(transmute([^]u64) slot_cursor)[0] = 0; 
		hash64_djb8(transmute(^u64) slot_cursor, (transmute(^[]byte) a2_cursor) ^)  // slots[id].key = hash64_djb8(a2_entries[id].key)
	}
	kt_raw.len = num_values
}
kt1l_populate_slice_a2 :: proc($Type: typeid, kt: ^[]KT1L_Slot(Type), backing: AllocatorInfo, values: [][2]Type) {
	assert(kt != nil)
	values_bytes := slice(transmute([^]u8) raw_data(values), len(values) * size_of([2]Type))
	kt1l_populate_slice_a2_Slice_Byte(transmute(^[]byte) kt, backing, values_bytes, len(values), {
		slot_size       = size_of(KT1L_Slot(Type)),
		kt_value_offset = offset_of(KT1L_Slot(Type), value),
		type_width      = size_of(Type),
		type            = Type,
	})
}
