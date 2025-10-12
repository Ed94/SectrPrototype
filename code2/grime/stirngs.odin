package grime

Raw_String :: struct {
	data: [^]byte,
	len:     int,
}
string_cursor :: proc(s: string) -> [^]u8 { return slice_cursor(transmute([]byte) s) }
string_copy   :: proc(dst, src: string)   { slice_copy  (transmute([]byte) dst, transmute([]byte) src) }
string_end    :: proc(s: string) -> ^u8   { return slice_end (transmute([]byte) s) }
string_assert :: proc(s: string)          { slice_assert(transmute([]byte) s) }
