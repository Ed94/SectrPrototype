package grime

hash32_djb8 :: #force_inline proc "contextless" ( hash : ^u32, bytes : []byte ) {
	for value in bytes do (hash^) = (( (hash^) << 8) + (hash^) ) + u32(value)
}

hash64_djb8 :: #force_inline proc "contextless" ( hash : ^u64, bytes : []byte ) {
	for value in bytes do (hash^) = (( (hash^) << 8) + (hash^) ) + u64(value)
}
