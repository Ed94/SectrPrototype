package grime

import "base:intrinsics"

/*
Key Table Chained-Chunked-Cells

Table has a cell with a user-specified depth. Each cell will be a linear search if the first slot is occupied.
Table allocated cells are looked up by hash. 
If a cell is exhausted additional are allocated singly-chained reporting to the user when it does with a "cell_overflow" counter.
Slots track occupacy with a tombstone (occupied signal).

If the table ever needs to change its size, it should be a wipe and full traversal of the arena holding the values..
or maybe a wipe of that arena as it may no longer be accessible.

Has a likely-hood of having cache misses (based on reading other impls about these kind of tables). 
Odin's hash-map or Jai's are designed with open-addressing and prevent that.
Intended to be wrapped in parent interface (such as a string cache). Keys are hashed by the table's user.
The table is not intended to directly store the type's value in it's slots (expects the slot value to be some sort of reference).
The value should be stored in an arena.

Could be upgraded two a X-layer, not sure if its ever viable. 
Would essentially be segmenting the hash to address a multi-layered table lookup.
Where one table leads to another hash resolving id for a subtable with linear search of cells after.
*/

KTCX_Slot :: struct($type: typeid) {
	value:    type,
	key:      u64,
	occupied: b32,
}
KTCX_Cell :: struct($type: typeid, $depth: int) {
	slots: [depth]KTCX_Slot(type),
	next:  ^KTCX_Cell(type, depth),
}
KTCX :: struct($cell: typeid) {
	table:         []cell,
	cell_overflow: int,
}
KTCX_Byte_Slot :: struct {
	key:      u64,
	occupied: b32,
}
KTCX_Byte_Cell :: struct {
	next: ^byte,
}
KTCX_Byte :: struct {
	table:         []byte,
	cell_overflow: int,
}
KTCX_ByteMeta :: struct {
	slot_size:        int,
	slot_key_offset:  uintptr,
	cell_next_offset: uintptr,
	cell_depth:       int,
	cell_size:        int,
	type_width:       int,
	type:             typeid,
}
KTCX_Info :: struct {
	table_size:       int,
	slot_size:        int,
	slot_key_offset:  uintptr,
	cell_next_offset: uintptr,
	cell_depth:       int,
	cell_size:        int,
	type_width:       int,
	type:             typeid,
}
ktcx_byte :: #force_inline proc "contextless" (kt: $type / KTCX) -> KTCX_Byte { return { slice( transmute([^]byte) cursor(kt.table), len(kt.table)) } }

ktcx_init_byte :: proc(result: ^KTCX_Byte, tbl_backing: Odin_Allocator, m: KTCX_Info) {
	assert(result                       != nil)
	assert(tbl_backing.procedure != nil)
	assert(m.cell_depth     >  0)
	assert(m.table_size     >= 4 * Kilo)
	assert(m.type_width     >  0)
	table_raw, error := mem_alloc(m.table_size * m.cell_size, ainfo = tbl_backing)
	assert(error == .None); slice_assert(transmute([]byte) table_raw)
	(transmute(^SliceByte) & table_raw).len = m.table_size
	result.table = table_raw
}
ktcx_clear :: proc(kt: KTCX_Byte, m: KTCX_ByteMeta) {
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
ktcx_slot_id :: #force_inline proc "contextless" (table: []byte, key: u64) -> u64 {
	return key % u64(len(table))
}
ktcx_get :: proc(kt: KTCX_Byte, key: u64, m: KTCX_ByteMeta) -> ^byte {
	hash_index   := key % u64(len(kt.table)) // ktcx_slot_id
	cell_offset  := uintptr(hash_index) * uintptr(m.cell_size)
	cell_cursor  := cursor(kt.table)[cell_offset:]                          // cell_id = 0
	{
		slots       := slice(cell_cursor, m.cell_depth * m.slot_size)         // slots   = cell[cell_id].slots
		slot_cursor := cell_cursor                                            // slot_id = 0
		for;; 
		{
			slot := transmute(^KTCX_Byte_Slot) slot_cursor[m.slot_key_offset:] // slot = cell[slot_id]
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
ktcx_set :: proc(kt: ^KTCX_Byte, key: u64, value: []byte, backing_cells: Odin_Allocator, m: KTCX_ByteMeta) -> ^byte {
	hash_index  := key % u64(len(kt.table)) // ktcx_slot_id
	cell_offset := uintptr(hash_index) * uintptr(m.cell_size)
	cell_cursor := cursor(kt.table)[cell_offset:] // KTCX_Cell(Type) cell = kt.table[hash_index]
	{
		slots       := SliceByte {cell_cursor, m.cell_depth * m.slot_size} // cell.slots
		slot_cursor := slots.data
		for ;;
		{
			slot := transmute(^KTCX_Byte_Slot) slot_cursor[m.slot_key_offset:]
			if slot.occupied == false {
				slot.occupied = true
				slot.key      = key
				return cast(^byte) slot_cursor
			}
			else if slot.key == key {
				return cast(^byte) slot_cursor
			}
			if slot_cursor == end(slots) {
				curr_cell := transmute(^KTCX_Byte_Cell) (uintptr(cell_cursor) + m.cell_next_offset) // curr_cell = cell
				if curr_cell != nil {
					slots.data  = curr_cell.next
					slot_cursor = curr_cell.next
					cell_cursor = curr_cell.next
					continue
				}
				else {
					ensure(false, "Exhausted a cell. Increase the table size?")
					new_cell, _    := mem_alloc(m.cell_size, ainfo = backing_cells)
					curr_cell.next  = raw_data(new_cell)
					slot            = transmute(^KTCX_Byte_Slot) cursor(new_cell)[m.slot_key_offset:]
					slot.occupied   = true
					slot.key        = key
					kt.cell_overflow += 1
					return raw_data(new_cell)
				}
			}
			slot_cursor = slot_cursor[m.slot_size:]
		}
		return nil
	}
}

// Type aware wrappers

ktcx_init :: #force_inline proc(table_size: int, tbl_backing: Odin_Allocator, 
	kt: ^$kt_type / KTCX(KTCX_Cell(KTCX_Slot($Type), $Depth))
){
	ktcx_init_byte(transmute(^KTCX_Byte) kt, tbl_backing, {
		table_size       = table_size,
		slot_size        = size_of(KTCX_Slot(Type)),
		slot_key_offset  = offset_of(KTCX_Slot(Type),        key),
		cell_next_offset = offset_of(KTCX_Cell(Type, Depth), next),
		cell_depth       = Depth,
		cell_size        = size_of(KTCX_Cell(Type, Depth)),
		type_width       = size_of(Type),
		type             = Type,
	})
}
