package grime

import "base:intrinsics"

/*
Key Table 1-Layer Chained-Chunked-Cells
*/

KT1CX_Slot :: struct($type: typeid) {
	value:    type,
	key:      u64,
	occupied: b32,
}
KT1CX_Cell :: struct($type: typeid, $depth: int) {
	slots: [depth]KT1CX_Slot(type),
	next:  ^KT1CX_Cell(type, depth),
}
KT1CX :: struct($cell: typeid) {
	table: []cell,
}
KT1CX_Byte_Slot :: struct {
	key:      u64,
	occupied: b32,
}
KT1CX_Byte_Cell :: struct {
	next: ^byte,
}
KT1CX_Byte :: struct {
	table: []byte,
}
KT1CX_ByteMeta :: struct {
	slot_size:        int,
	slot_key_offset:  uintptr,
	cell_next_offset: uintptr,
	cell_depth:       int,
	cell_size:        int,
	type_width:       int,
	type:             typeid,
}
KT1CX_InfoMeta :: struct {
	table_size:       int,
	slot_size:        int,
	slot_key_offset:  uintptr,
	cell_next_offset: uintptr,
	cell_depth:       int,
	cell_size:        int,
	type_width:       int,
	type:             typeid,
}
KT1CX_Info :: struct {
	backing_table: AllocatorInfo,
}
kt1cx_init :: proc(info: KT1CX_Info, m: KT1CX_InfoMeta, result: ^KT1CX_Byte) {
	assert(result                       != nil)
	assert(info.backing_table.procedure != nil)
	assert(m.cell_depth     >  0)
	assert(m.table_size     >= 4 * Kilo)
	assert(m.type_width     >  0)
	table_raw := transmute(SliceByte) mem_alloc(m.table_size * m.cell_size, ainfo = odin_allocator(info.backing_table))
	slice_assert(transmute([]byte) table_raw)
	table_raw.len = m.table_size
	result.table  = transmute([]byte) table_raw
}
kt1cx_clear :: proc(kt: KT1CX_Byte, m: KT1CX_ByteMeta) {
	cell_cursor := cursor(kt.table)
	table_len   := len(kt.table) * m.cell_size
	for ; cell_cursor != end(kt.table); cell_cursor = cell_cursor[m.cell_size:] // for cell, cell_id in kt.table.cells
	{
		slots       := SliceByte { cell_cursor, m.cell_depth * m.slot_size } // slots = cell.slots
		slot_cursor := slots.data
		for;; {
			slot := slice(slot_cursor, m.slot_size)          // slot = slots[slot_id]
			zero(slot)                                       // slot = {}
			if slot_cursor == end(slots) { // if slot == end(slot)
				next := slot_cursor[m.cell_next_offset:]       // next = kt.table.cells[cell_id + 1]
				if next != nil {                               // if next != nil
					slots.data  = next                           // slots = next.slots
					slot_cursor = next
					continue
				}
			}
			slot_cursor = slot_cursor[m.slot_size:]          // slot = slots[slot_id + 1]
		}
	}
}
kt1cx_slot_id :: proc(kt: KT1CX_Byte, key: u64, m: KT1CX_ByteMeta) -> u64 {
	cell_size := m.cell_size // dummy value
	hash_index := key % u64(len(kt.table))
	return hash_index
}
kt1cx_get :: proc(kt: KT1CX_Byte, key: u64, m: KT1CX_ByteMeta) -> ^byte {
	hash_index   := kt1cx_slot_id(kt, key, m)
	cell_offset  := uintptr(hash_index) * uintptr(m.cell_size)
	cell_cursor  := cursor(kt.table)[cell_offset:]                          // cell_id = 0
	{
		slots       := slice(cell_cursor, m.cell_depth * m.slot_size)         // slots   = cell[cell_id].slots
		slot_cursor := cell_cursor                                            // slot_id = 0
		for;; 
		{
			slot := transmute(^KT1CX_Byte_Slot) slot_cursor[m.slot_key_offset:] // slot = cell[slot_id]
			if slot.occupied && slot.key == key {
				return cast(^byte) slot_cursor
			}
			if slot_cursor == end(slots)
			{
				cell_next := cell_cursor[m.cell_next_offset:] // cell.next
				if cell_next != nil {
					slots       = slice(cell_next, len(slots)) // slots = cell.next
					slot_cursor = cell_next
					cell_cursor = cell_next                    // cell = cell.next
					continue
				}
				else {
					return nil
				}
			}
			slot_cursor = slot_cursor[m.slot_size:]
		}
	}
}
kt1cx_set :: proc(kt: KT1CX_Byte, key: u64, value: []byte, backing_cells: AllocatorInfo, m: KT1CX_ByteMeta) -> ^byte {
	hash_index  := kt1cx_slot_id(kt, key, m)
	cell_offset := uintptr(hash_index) * uintptr(m.cell_size)
	cell_cursor := cursor(kt.table)[cell_offset:] // KT1CX_Cell(Type) cell = kt.table[hash_index]
	{
		slots       := SliceByte {cell_cursor, m.cell_depth * m.slot_size} // cell.slots
		slot_cursor := slots.data
		for ;;
		{
			slot := transmute(^KT1CX_Byte_Slot) slot_cursor[m.slot_key_offset:]
			if slot.occupied == false {
				slot.occupied = true
				slot.key      = key
				return cast(^byte) slot_cursor
			}
			else if slot.key == key {
				return cast(^byte) slot_cursor
			}
			if slot_cursor == end(slots) {
				curr_cell := transmute(^KT1CX_Byte_Cell) (uintptr(cell_cursor) + m.cell_next_offset) // curr_cell = cell
				if curr_cell != nil {
					slots.data  = curr_cell.next
					slot_cursor = curr_cell.next
					cell_cursor = curr_cell.next
					continue
				}
				else {
					new_cell       := mem_alloc(m.cell_size, ainfo = odin_allocator(backing_cells))
					curr_cell.next  = raw_data(new_cell)
					slot            = transmute(^KT1CX_Byte_Slot) cursor(new_cell)[m.slot_key_offset:]
					slot.occupied   = true
					slot.key        = key
					return raw_data(new_cell)
				}
			}
			slot_cursor = slot_cursor[m.slot_size:]
		}
		return nil
	}
}
kt1cx_assert :: proc(kt: $type / KT1CX) {
	slice_assert(kt.table)
}
kt1cx_byte :: proc(kt: $type / KT1CX) -> KT1CX_Byte { return { slice( transmute([^]byte) cursor(kt.table), len(kt.table)) } }
