package grime

Raw_String :: struct {
	data: [^]byte,
	len:     int,
}
string_cursor :: #force_inline proc "contextless" (s: string) -> [^]u8 { return slice_cursor(transmute([]byte) s) }
string_copy   :: #force_inline proc "contextless" (dst, src: string)   { slice_copy  (transmute([]byte) dst, transmute([]byte) src) }
string_end    :: #force_inline proc "contextless" (s: string) -> ^u8   { return slice_end (transmute([]byte) s) }
string_assert :: #force_inline proc "contextless" (s: string)          { slice_assert(transmute([]byte) s) }
