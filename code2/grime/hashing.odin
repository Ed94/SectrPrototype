package grime

hash32_djb8 :: #force_inline proc "contextless" (hash: ^u32, bytes: []byte ) {
	for value in bytes do (hash^) = (( (hash^) << 8) + (hash^) ) + u32(value)
}

hash64_djb8 :: #force_inline proc "contextless" (hash: ^u64, bytes: []byte ) {
	for value in bytes do (hash^) = (( (hash^) << 8) + (hash^) ) + u64(value)
}

// Ripped from core:hash, fnv32a
@(optimization_mode="favor_size")
hash32_fnv1a :: #force_inline proc "contextless" (hash: ^u32, data: []byte, seed := u32(0x811c9dc5)) {
	hash^ = seed; for b in data { hash^ = (hash^ ~ u32(b)) * 0x01000193 }
}
// Ripped from core:hash, fnv64a
@(optimization_mode="favor_size")
hash64_fnv1a :: #force_inline proc "contextless" (hash: ^u64, data: []byte, seed := u64(0xcbf29ce484222325)) {
	hash^ = seed; for b in data { hash^ = (hash^ ~ u64(b)) * 0x100000001b3 }
}
