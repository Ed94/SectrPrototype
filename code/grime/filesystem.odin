package grime
// TODO(Ed): Review when os2 is done.

import "core:fmt"
import "core:os"
import "base:runtime"

// TODO(Ed): Make an async option...
file_copy_sync :: proc( path_src, path_dst: string, allocator := context.allocator ) -> b32
{
  file_size : i64
	{
		path_info, result := file_status( path_src, allocator )
		if result != os.ERROR_NONE {
			logf("Could not get file info: %v", result, LogLevel.Error )
			return false
		}
		file_size = path_info.size
	}

	src_content, result := os.read_entire_file( path_src, allocator )
	if ! result {
		logf( "Failed to read file to copy: %v", path_src, LogLevel.Error )
		runtime.debug_trap()
		return false
	}

	result = os.write_entire_file( path_dst, src_content, false )
	if ! result {
		logf( "Failed to copy file: %v", path_dst, LogLevel.Error )
		runtime.debug_trap()
		return false
	}
	return true
}

file_exists :: proc( file_path : string, allocator := context.allocator ) -> b32 {
	path_info, result := file_status( file_path, allocator )
	if result != os.ERROR_NONE {
		return false
	}
	return true;
}

file_is_locked :: proc( file_path : string ) -> b32 {
	handle, err := file_open(file_path, os.O_RDONLY)
	if err != os.ERROR_NONE {
			// If the error indicates the file is in use, return true.
			return true
	}

	// If the file opens successfully, close it and return false.
	file_close(handle)
	return false
}

file_rewind :: proc( file : os.Handle ) {
	file_seek( file, 0, 0 )
}

file_read_looped :: proc( file : os.Handle, data : []byte ) {
	total_read, result_code := file_read( file, data )
	if result_code == os.ERROR_HANDLE_EOF {
		file_rewind( file )
	}
}
