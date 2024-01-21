package sectr

kilobytes :: proc ( kb : $integer_type ) -> integer_type {
	return kb * 1024
}
megabytes :: proc ( kb : $integer_type ) -> integer_type {
	return kb * 1024 * 1024
}
