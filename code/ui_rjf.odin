package sectr

when false {
	ui_box_cache_insert :: proc( using cache : HMap_RJF( ^ UI_Box ), key : u64, value : ^ UI_Box ) -> ^ UI_Box {
		slot := rjf_hmap_get_slot( cache, key )

		// dll_insert_raw( nil, slot.first, slot.last, slot.last, value )
		{
			new_links := & new.hash_links

			// Empty Case
			if first == null {
				first = new
				last  = new
				new_links.next = null
				new_links.prev = null
			}
			else if position == null {
				// Position is not set, insert at beginning
				new_links.next = first
				first.first    = new
				first          = new
				new_links.prev = null
			}
			else if position == last {
				// Positin is set to last, insert at end
				last.last      = new
				new_links.prev = last
				last           = new
				new_links.next = null
			}
			else {
				// Insert around position
				if position.next != null {
					position.next.prev = new
				}
				new.next      = position.next
				position.next = new
				new.prev      = position
			}
		}
	}
}
