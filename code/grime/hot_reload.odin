package grime

import "base:runtime"

reload_array :: proc( self : ^[dynamic]$Type, allocator : Allocator ) {
	raw          := transmute(runtime.Raw_Dynamic_Array) self
	raw.allocator = allocator
}

reload_queue :: proc( self : ^Queue($Type), allocator : Allocator ) {
	raw_array          := transmute(runtime.Raw_Dynamic_Array) self.data
	raw_array.allocator = allocator
}

reload_map :: proc( self : ^map [$KeyType] $EntryType, allocator : Allocator ) {
	raw          := transmute(runtime.Raw_Map) self
	raw.allocator = allocator
}
