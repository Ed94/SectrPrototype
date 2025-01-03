package grime

djb8_hash :: #force_inline proc "contextless" ( hash : ^u64, bytes : []byte ) {
	for value in bytes do (hash^) = (( (hash^) << 8) + (hash^) ) + u64(value)
}
