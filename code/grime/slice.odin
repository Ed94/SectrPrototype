package grime

SliceByte :: struct {
	data: [^]byte,
	len: int
}
SliceRaw  :: struct ($Type: typeid) {
	data: [^]Type,
	len:  int,
}
slice        :: #force_inline proc "contextless" (s: [^] $Type, num: $Some_Integer) -> [ ]Type { return transmute([]Type) SliceRaw(Type) { s, cast(int) num } }
slice_cursor :: #force_inline proc "contextless" (s: []$Type)                       -> [^]Type { return transmute([^]Type) raw_data(s) }
slice_assert :: #force_inline proc (s: $SliceType / []$Type) {
	assert(len(s) > 0)
	assert(s != nil)
}
slice_end :: #force_inline proc "contextless" (s : $SliceType / []$Type) -> ^Type { return & cursor(s)[len(s)] }

@(require_results) slice_to_bytes :: proc "contextless" (s: []$Type) -> []byte         { return ([^]byte)(raw_data(s))[:len(s) * size_of(Type)] }
@(require_results) slice_raw      :: proc "contextless" (s: []$Type) -> SliceRaw(Type) { return transmute(SliceRaw(Type)) s }

slice_zero :: proc "contextless" (data: $SliceType / []$Type) { memory_zero(raw_data(data), size_of(Type) * len(data)) }
slice_copy :: proc "contextless" (dst, src: $SliceType / []$Type) -> int {
	n := max(0, min(len(dst), len(src)))
	if n > 0 {
		mem_copy(raw_data(dst), raw_data(src), n * size_of(Type))
	}
	return n
}
slice_copy_non_overlapping :: proc "contextless" (dst, src: $SliceType / []$Type) -> int {
	n := max(0, min(len(dst), len(src)))
	if n > 0 {
		mem_copy_non_overlapping(raw_data(dst), raw_data(src), n * size_of(Type))
	}
	return n
}
