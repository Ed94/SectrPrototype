// TODO(Ed) : Move this to a grime package
package sectr

import "core:fmt"
import "core:os"
import "core:runtime"

copy_file_sync :: proc( path_src, path_dst: string ) -> b32
{
  file_size : i64
	{
		path_info, result := os.stat( path_src, context.temp_allocator )
		if result != os.ERROR_NONE {
			logf("Could not get file info: %v", result, LogLevel.Error )
			return false
		}
		file_size = path_info.size
	}

	src_content, result := os.read_entire_file( path_src, context.temp_allocator )
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

file_exists :: proc( file_path : string ) -> b32 {
	path_info, result := os.stat( file_path, context.temp_allocator )
	if result != os.ERROR_NONE {
		return false
	}
	return true;
}

is_file_locked :: proc( file_path : string ) -> b32 {
	handle, err := os.open(file_path, os.O_RDONLY)
	if err != os.ERROR_NONE {
			// If the error indicates the file is in use, return true.
			return true
	}

	// If the file opens successfully, close it and return false.
	os.close(handle)
	return false
}

rewind :: proc( file : os.Handle ) {
	os.seek( file, 0, 0 )
}

read_looped :: proc( file : os.Handle, data : []byte ) {
	total_read, result_code := os.read( file, data )
	if result_code == os.ERROR_HANDLE_EOF {
		rewind( file )
	}
}
