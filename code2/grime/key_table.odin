package grime

/*
Hassh Table based on John's Jai & Sean Barrett's
I don't like the table definition cntaining 
the allocator, hash or compare procedure to be used.
So it has been stripped and instead applied on procedure site,
the parent container or is responsible for tracking that.

TODO(Ed): Resolve appropriate Key-Table term for it.
*/

KT_Slot :: struct(
	$TypeHash:  typeid, 
	$TypeKey:   typeid, 
	$TypeValue: typeid
) {
	hash:  TypeHash,
	key:   TypeKey,
	value: TypeValue,
}

KT :: struct($KT_Slot: typeid) {
	load_factor_perent: int,
	count:              int,
	allocated:          int,
	slots_filled:       int,
	slots:              []KT_Slot,
}

KT_Info :: struct {
	key_width:           int,
	value_width:         int,
	slot_width:          int,
}

KT_Opaque :: struct {
	count:        int,
	allocated:    int,
	slots_filled: int,
	slots:        []byte,
}

KT_ByteMeta :: struct {
	hash_width:  int,
	value_width: int,
}

KT_COUNT_COLLISIONS :: #config(KT_COUNT_COLLISIONS, false)

KT_HASH_NEVER_OCCUPIED :: 0
KT_HASH_REMOVED        :: 1
KT_HASH_FIRST_VALID    :: 2
KT_LOAD_FACTOR_PERCENT :: 70

kt_byte_init :: proc(info: KT_Info, tbl_allocator: Odin_Allocator, kt: ^KT_Opaque, $HashType: typeid)
{
	#assert(size_of(HashType) >= 32)
	assert(tbl_allocator.procedure != nil)
	assert(info.value_width  >= 32)
	assert(info.slot_width   >= 64)
}
kt_deinit :: proc(table: ^$KT / typeid, allocator: Odin_Allocator)
{

}

kt_walk_table_body_proc :: #type proc($TypeHash: typeid, hash: TypeHash, kt: ^KT_Opaque, info: KT_Info, id: TypeHash) -> (should_break: bool)
kt_walk_table           :: proc($TypeHash: typeid, hash: TypeHash, kt: ^KT_Opaque, info: KT_Info, $walk_body: kt_walk_table_body_proc) -> (index: TypeHash)
{
	mask := cast(TypeHash)(kt.allocated - 1) // Cast may truncate
	if hash < KT_HASH_FIRST_VALID do hash += KT_HASH_FIRST_VALID
	index          : TypeHash = hash & mask
	probe_increment: TypeHash = 1
	for id := transmute(TypeHash) kt.slots[info.slot_width * index:]; id != 0;
	{
		if #force_inline walk_body(hash, kt, info, id) do break
		index = (index + probe_increment) & mask
		probe_increment += 1
	}
}

// Will not expand table if capacity reached, user must do that check beforehand.
// Will return existing if hash found
kt_byte_add :: proc(value: [^]byte, key: [^]byte, hash: $TypeHash, kt: ^KT_Opaque, info: KT_Info)-> [^]byte
{
	aasert(kt.slots_filled, kt.allocated)
	index := #force_inline kt_walk_table(hash, kt, info, 
	proc(hash: $TypeHash, kt: ^KT_Opaque, info: KT_Info, id: TypeHash) -> (should_break: bool)
	{
		if id == KT_HASH_REMOVED {
			kt.slots_filled -= 1
			should_break = true
			return
		}
		//TODO(Ed): Add collision tracking
		return
	})
	kt.count        += 1
	kt.slots_filled += 1
	slot_offset := info.slot_width * index
	entry       := table.slots[info.slot_width * index:]
	mem_copy_non_overlapping(entry,                                hash,  size_of(TypeHash))
	mem_copy_non_overlapping(entry[size_of(hash):],                key,   info.key_width)
	mem_copy_non_overlapping(entry[size_of(hash) + size_of(key):], value, info.value_width)
	return entry
}

// Will not expand table if capacity reached, user must do that check beforehand.
// Will override if hash exists
kt_byte_set :: proc()
{

}

kt_remove :: proc()
{

}

kt_byte_contains :: proc()
{

}

kt_byte_find_pointer :: proc()
{

}

kt_find :: proc()
{

}

kt_find_multiple :: proc()
{

}

kt_next_power_of_two :: #force_inline proc(x: int) -> int { power := 1; for ;x > power; do power += power; return power }
