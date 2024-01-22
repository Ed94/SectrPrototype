package sectr

import "core:fmt"
import "core:mem"
import "core:mem/virtual"
import "core:runtime"

Byte     :: 1
Kilobyte :: 1024 * Byte
Megabyte :: 1024 * Kilobyte
Gigabyte :: 1024 * Megabyte
Terabyte :: 1024 * Gigabyte
Petabyte :: 1024 * Terabyte
Exabyte  :: 1024 * Petabyte

kilobytes :: proc ( kb : $ integer_type ) -> integer_type {
	return kb * 1024
}
megabytes :: proc ( kb : $ integer_type ) -> integer_type {
	return kb * 1024 * 1024
}
