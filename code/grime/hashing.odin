package grime

djb8_hash_32 :: #force_inline proc "contextless" ( hash : ^u32, bytes : []byte ) {
	for value in bytes do (hash^) = (( (hash^) << 8) + (hash^) ) + u32(value)
}

djb8_hash :: #force_inline proc "contextless" ( hash : ^u64, bytes : []byte ) {
	for value in bytes do (hash^) = (( (hash^) << 8) + (hash^) ) + u64(value)
}
