/*
	This was a tracking allocator made to kill off various bugs left with grime's pool & slab allocators
	It doesn't perform that well on a per-frame basis and should be avoided for general memory debugging

	It only makes sure that memory allocations don't collide in the allocator and deallocations don't occur for memory never allocated.

	I'm keeping it around as an artifact & for future allocators I may make.
*/
package grime

MemoryTrackerEntry :: struct {
	start, end : rawptr,
}
MemoryTracker :: struct {
	parent  : ^MemoryTracker,
	name    : string,
	entries : Array(MemoryTrackerEntry),
}

Track_Memory :: true

@(disabled = Track_Memory == false)
memtracker_clear :: proc (tracker: MemoryTracker) {
	log_print_fmt("Clearing tracker: %v", tracker.name)
	memtracker_dump_entries(tracker);
	array_clear(tracker.entries)
}
@(disabled = Track_Memory == false)
memtracker_init :: proc (tracker: ^MemoryTracker, allocator: Odin_Allocator, num_entries: int, name: string) {
	tracker.name = name
	error: AllocatorError
	tracker.entries, error = make( Array(MemoryTrackerEntry), num_entries, dbg_name = name, allocator = allocator )
	if error != AllocatorError.None do fatal("Failed to allocate memory tracker's hashmap");
}
@(disabled = Track_Memory == false)
memtracker_register :: proc(tracker: ^MemoryTracker, new_entry: MemoryTrackerEntry )
{
	profile(#procedure)
	if tracker.entries.num == tracker.entries.capacity {
		ensure(false, "Memory tracker entries array full, can no longer register any more allocations")
		return
	}
	for idx  in 0..< tracker.entries.num
	{
		entry := & tracker.entries.data[idx]
		if new_entry.start > entry.start do continue

		if (entry.end < new_entry.start) {
			msg := str_pfmt("Detected a collision:\nold_entry: %v -> %v\nnew_entry: %v -> %v | %v", entry.start, entry.end, new_entry.start, new_entry.end, tracker.name )
			ensure( false, msg )
			memtracker_dump_entries(tracker ^)
		}
		array_append_at(& tracker.entries, new_entry, idx)
		log_print_fmt("Registered: %v -> %v | %v", new_entry.start, new_entry.end, tracker.name)
		return
	}
	array_append( & tracker.entries, new_entry )
	log_print_fmt("Registered: %v -> %v | %v", new_entry.start, new_entry.end, tracker.name )
}
@(disabled = Track_Memory == false)
memtracker_register_auto_name :: #force_inline proc(tracker: ^MemoryTracker, start, end: rawptr) {
	memtracker_register( tracker, {start, end})
}
@(disabled = Track_Memory == false)
memtracker_register_auto_name_slice :: #force_inline proc( tracker : ^MemoryTracker, slice : []byte ) { 
	memtracker_register( tracker, { raw_data(slice), transmute(rawptr) & cursor(slice)[len(slice) - 1] }) 
}
@(disabled = Track_Memory == false)
memtracker_unregister :: proc( tracker : MemoryTracker, to_remove : MemoryTrackerEntry )
{
	profile(#procedure)
	entries := array_to_slice(tracker.entries)
	for idx in 0..< tracker.entries.num
	{
		entry := & entries[idx]
		if entry.start == to_remove.start {
			if (entry.end == to_remove.end || to_remove.end == nil) {
				log_print_fmt("Unregistered: %v -> %v | %v", to_remove.start, to_remove.end, tracker.name );
				array_remove_at(tracker.entries, idx)
				return
			}
			ensure(false, str_pfmt_tmp("Found an entry with the same start address but end address was different:\nentry   : %v -> %v\nto_remove: %v -> %v | %v", entry.start, entry.end, to_remove.start, to_remove.end, tracker.name ))
			memtracker_dump_entries(tracker)
		}
	}
	ensure(false, str_pfmt_tmp("Attempted to unregister an entry that was not tracked: %v -> %v | %v", to_remove.start, to_remove.end, tracker.name))
	memtracker_dump_entries(tracker)
}
@(disabled = Track_Memory == false)
memtracker_check_for_collisions :: proc ( tracker : MemoryTracker )
{
	profile(#procedure)
	// entries := array_to_slice(tracker.entries)
	for idx in 1 ..< tracker.entries.num {
		// Check to make sure each allocations adjacent entries do not intersect
		left  := & tracker.entries.data[idx - 1]
		right := & tracker.entries.data[idx]
		collided := left.start > right.start || left.end > right.end
		if collided {
			msg := str_pfmt_tmp("Memory tracker detected a collision:\nleft: %v\nright: %v | %v", left, right, tracker.name )
			memtracker_dump_entries(tracker)
		}
	}
}
@(disabled = Track_Memory == false)
memtracker_dump_entries :: proc( tracker : MemoryTracker ) {
	log_print( "Dumping Memory Tracker:")
	for idx in 0 ..< tracker.entries.num {
		entry := & tracker.entries.data[idx]
		log_print_fmt("%v -> %v", entry.start, entry.end)
	}
}
