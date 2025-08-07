package grime

// Key Table 1-Layer Linear (KT1L)

KT1L_Use_TypeErased :: true

KT1L_Slot :: struct($KeyType, $ValueType: typeid) {
	key:   KeyType,
	value: ValueType,
}
KT1L_Meta :: struct {
	slot_size:       uintptr,
	kt_value_offset: uintptr,
	type_width:      uintptr,
	type:            typeid,
}
kt1l_64_populate_slice_a2_Slice_Byte :: proc(kt: ^[]byte, backing: Allocator, values: []byte, num_values: int, m: KT1L_Meta) {
	assert(kt != nil)
	if num_values == 0 { return }
	table_size_bytes := num_values * int(m.slot_size)
	alloc_error: AllocatorError
	kt^, alloc_error = alloc_bytes(table_size_bytes, allocator = backing)
	assert(alloc_error == .None)
	slice_assert(kt ^)
	kt_raw : SliceByte = transmute(SliceByte) kt^
	for id in 0 ..< cast(uintptr) num_values {
		slot_offset := id * m.slot_size                                     // slot id
		slot_cursor := kt_raw.data[slot_offset:]                            // slots[id]            type: KT1L_<Type>
		slot_key    := cast(^u64) slot_cursor                               // slots[id].key        type: U64
		slot_value  := slice(slot_cursor[m.kt_value_offset:], m.type_width) // slots[id].value      type: <Type>
		a2_offset   := id * m.type_width * 2                                // a2 entry id
		a2_cursor   := cursor(values)[a2_offset:]                           // a2_entries[id]       type: A2_<Type>
		a2_key      := (transmute(^[]byte) a2_cursor) ^                     // a2_entries[id].key   type: <Type>
		a2_value    := slice(a2_cursor[m.type_width:], m.type_width)        // a2_entries[id].value type: <Type>
		copy(slot_value, a2_value)                                          // slots[id].value = a2_entries[id].value
		slot_key^ = 0; hash64_djb8(slot_key, a2_key)                        // slots[id].key   = hash64_djb8(a2_entries[id].key)
	}
	kt_raw.len = num_values
}
when KT1L_Use_TypeErased 
{
	kt1l_64_populate_slice_a2 :: proc(kt: ^[]KT1L_Slot(u64, $Type), values: [][2]Type, backing:= context.allocator) {
		assert(kt != nil)
		values_bytes := slice(transmute([^]u8) raw_data(values), len(values) * size_of([2]Type))
		kt1l_64_populate_slice_a2_Slice_Byte(transmute(^[]byte) kt, backing, values_bytes, len(values), {
			slot_size       = size_of(KT1L_Slot(Type)),
			kt_value_offset = offset_of(KT1L_Slot(Type), value),
			type_width      = size_of(Type),
			type            = Type,
		})
	}
}
else
{
	kt1l_64_populate_slice_a2 :: proc(kt: ^[]KT1L_Slot(u64, $Type), values: [][2]Type, backing:= context.allocator) {
		assert(kt != nil)
		if len(values) == 0 { retrurn }	
		kt, alloc_error = make_slice([]KT1L_Slot(u64, Type), len(values), allocator = backing)
		assert(alloc_error == .None)
		slice_assert(kt)
		for id in 0 ..< len(values) {
			slot := & kt[id]
			hash64_djb8(& slot.key, values[id][0])
			slot.value = values[id][1]
		}
	}
}

// TODO(Ed): Move ot package mappings
kt1l_populate_slice_a2 :: proc {
	kt1l_64_populate_slice_a2,
}
