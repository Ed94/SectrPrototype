package grime

Raw_String :: struct {
	data: [^]byte,
	len:     int,
}
string_cursor :: #force_inline proc "contextless" (s: string) -> [^]u8 { return slice_cursor(transmute([]byte) s) }
string_copy   :: #force_inline proc "contextless" (dst, src: string)   { slice_copy  (transmute([]byte) dst, transmute([]byte) src) }
string_end    :: #force_inline proc "contextless" (s: string) -> ^u8   { return slice_end (transmute([]byte) s) }
string_assert :: #force_inline proc "contextless" (s: string)          { slice_assert(transmute([]byte) s) }

str_to_cstr_capped :: proc(content: string, mem: []byte) -> cstring {
	copy_len := min(len(content), len(mem) - 1)
	if copy_len > 0 do copy(mem[:copy_len], transmute([]byte) content)
	mem[copy_len] = 0
	return transmute(cstring) raw_data(mem)
}

cstr_len_capped    :: #force_inline proc "contextless" (content: cstring, cap: int)    -> (len: int) { for len = 0; (len <= cap) && (transmute([^]byte)content)[len] != 0; len += 1 {} return }
cstr_to_str_capped :: #force_inline proc "contextless" (content: cstring, mem: []byte) -> string     { return transmute(string) Raw_String { cursor(mem), cstr_len_capped (content, len(mem)) } }
