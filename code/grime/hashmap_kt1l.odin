package grime

when (false) {

KT1L_Slot :: struct($Type: typeid) {
	key:   u64,
	value: Type,
}
KT1L_Meta :: struct {
	slot_size:       uintptr,
	kt_value_offset: uintptr,
	type_width:      uintptr,
	type_name:       string,
}
kt1l_populate_slice_a2_Slice_Byte :: proc(kt: ^[]byte, backing: Allocator = context.allocator, values: []byte, num_values: int, m: KT1L_Meta) {
	assert(kt != nil)
	if num_values == 0 { return }
	table_size_bytes := num_values * int(m.slot_size)
	err : AllocatorError
	kt^, err = alloc_bytes(table_size_bytes, allocator = backing)
	slice_assert(kt ^)
	kt_raw : Raw_Slice = transmute(Raw_Slice) kt^
	for cursor in 0 ..< cast(uintptr) num_values {
		slot_offset := cursor * m.slot_size
		slot_cursor := uintptr(kt_raw.data) + slot_offset
		slot_key    := cast(^u64) slot_cursor
		slot_value  := transmute([]byte) Raw_Slice { cast([^]byte) (slot_cursor + m.kt_value_offset), int(m.type_width)}
		a2_offset   := cursor * m.type_width * 2
		a2_cursor   := uintptr(& values[a2_offset])
		a2_key      := (transmute(^[]byte) a2_cursor) ^
		a2_value    := transmute([]byte) Raw_Slice { rawptr(a2_cursor + m.type_width), int(m.type_width) }
		copy(slot_value, a2_value)
		slot_key^ = 0; hash64_djb8(slot_key, a2_key)
	}
	kt_raw.len = num_values
}
kt1l_populate_slice_a2 :: proc($Type: typeid, kt: ^[]KT1L_Slot(Type), backing: AllocatorInfo, values: [][2]Type) {
	assert(kt != nil)
	values_bytes := transmute([]byte) Raw_Slice{data = raw_data(values), len = len(values) * size_of([2]Type)}
	kt1l_populate_slice_a2_Slice_Byte(transmute(^[]byte) kt, backing, values_bytes, len(values), {
		slot_size       = size_of(KT1L_Slot(Type)),
		kt_value_offset = offset_of(KT1L_Slot(Type), KT1L_Slot(Type).value),
		type_width      = size_of(Type),
		type_name       = #type_string(Type),
	})
}

}
