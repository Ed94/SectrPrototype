package sectr

UI_Floating :: struct {
	label       : string,
	using links : DLL_NodePN(UI_Floating),
	captures    : rawptr,
	builder     : UI_FloatingBuilder,
	queued      : b32,
}
UI_FloatingBuilder :: #type proc( captures : rawptr ) -> (became_active : b32)

// Overlapping/Stacking window/frame manager
// AKA: Stacking or Floating Window Manager
UI_FloatingManager :: struct {
	using links : DLL_NodeFL(UI_Floating),
	build_queue : Array(UI_Floating),
	tracked     : HMapChainedPtr(UI_Floating),
	// tracked     : HMapZPL(UI_Floating),
}

ui_floating_startup :: proc( self : ^UI_FloatingManager, allocator : Allocator, build_queue_cap, tracked_cap : u64, dbg_name : string = ""  ) -> AllocatorError
{
	error : AllocatorError

	queue_dbg_name := str_intern(str_fmt_tmp("%s: build_queue", dbg_name))
	self.build_queue, error = array_init_reserve( UI_Floating, allocator, build_queue_cap, dbg_name = queue_dbg_name.str )
	if error != AllocatorError.None
	{
		ensure(false, "Failed to allocate the build_queue")
		return error
	}

	tracked_dbg_name := str_intern(str_fmt_tmp("%s: tracked", dbg_name))
	// self.tracked, error = zpl_hmap_init_reserve( UI_Floating, allocator, tracked_cap, dbg_name = tracked_dbg_name.str )
	self.tracked, error = hmap_chained_init(UI_Floating, uint(tracked_cap), allocator, dbg_name = tracked_dbg_name.str )
	if error != AllocatorError.None
	{
		ensure(false, "Failed to allocate tracking table")
		return error
	}
	return error
}

ui_floating_reload :: proc( self : ^UI_FloatingManager, allocator : Allocator )
{
	using self
	build_queue.backing     = allocator
	hmap_chained_reload(tracked, allocator)
}

ui_floating_just_builder :: #force_inline proc( label : string, builder : UI_FloatingBuilder ) -> ^UI_Floating
{
	No_Captures : rawptr = nil
	return ui_floating_with_capture(label, No_Captures, builder)
}

ui_floating_with_capture :: proc( label : string, captures : rawptr = nil, builder : UI_FloatingBuilder ) -> ^UI_Floating
{
	entry := UI_Floating {
		label    = label,
		captures = captures,
		builder  = builder,
	}

	floating  := get_state().ui_floating_context
	array_append( & floating.build_queue, entry )
	return nil
}

@(deferred_none = ui_floating_manager_end)
ui_floating_manager :: proc ( manager : ^UI_FloatingManager )
{
	ui_floating_manager_begin(manager)
}

ui_floating_manager_begin :: proc ( manager : ^UI_FloatingManager )
{
	state := get_state()
	state.ui_floating_context = manager
}

ui_floating_manager_end :: proc()
{
	state    := get_state()
	floating := & state.ui_floating_context
	ui_floating_build()
	floating = nil
}

ui_floating_build :: proc()
{
	ui        := ui_context()
	screen_ui := cast(^UI_ScreenState) ui
	using floating := get_state().ui_floating_context

	for to_enqueue in array_to_slice( build_queue)
	{
		key    := ui_key_from_string(to_enqueue.label)
		// lookup := zpl_hmap_get( & tracked, transmute(u64) key )
		lookup := hmap_chained_get( tracked, transmute(u64) key )

		// Check if entry is already present
		if lookup != nil && lookup.prev != nil && lookup.next != nil {
			lookup.captures = to_enqueue.captures
			lookup.builder  = to_enqueue.builder
			lookup.queued   = true
			continue
		}

		if lookup == nil {
			error : AllocatorError
			// lookup, error = zpl_hmap_set( & tracked, transmute(u64) key, to_enqueue )
			lookup, error = hmap_chained_set( tracked, transmute(u64) key, to_enqueue )
			if error != AllocatorError.None {
				ensure(false, "Failed to allocate entry to hashtable")
				continue
			}
			lookup.queued = true
		}
		else {
			lookup.captures = to_enqueue.captures
			lookup.builder  = to_enqueue.builder
			lookup.queued   = true
			continue
		}

		if first == nil {
			first = lookup
			last  = lookup
			continue
		}
		last.next = lookup
		last      = lookup
	}
	array_clear(build_queue)

	for entry := first; entry != nil; entry = entry.next
	{
		using entry
		if ! queued
		{
			if entry == first
			{
				first      = entry.next
				entry.next = nil
				continue
			}
			if entry == last
			{
				last       = last.prev
				last.prev  = nil
				entry.prev = nil
				continue
			}

			left  := entry.prev
			right := entry.next

			left.next  = right
			right.prev = left
			entry.prev = nil
			entry.next = nil
		}

		if builder( captures ) && entry != last
		{
			PopEntry:
			{
				if first == nil {
					first = entry
					last  = entry
					break PopEntry
				}
				if entry == first
				{
					first      = entry.next
					entry.next = nil
					break PopEntry
				}
				if entry == last
				{
					last       = last.prev
					last.prev  = nil
					entry.prev = nil
					break PopEntry
				}

				left  := entry.prev
				right := entry.next

				left.next  = right
				right.prev = left
			}

			last.next = entry
			last      = entry
		}
		queued = false
	}
}
