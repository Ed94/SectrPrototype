package grime
// TODO(Ed): Review when os2 is done.

// TODO(Ed): Make an async option...
file_copy_sync :: proc( path_src, path_dst: string, allocator := context.allocator ) -> b32
{
  file_size : i64
	{
		path_info, result := file_status( path_src, allocator )
		if result != OS_ERROR_NONE {
			log_fmt("Could not get file info: %v", result, LoggerLevel.Error )
			return false
		}
		file_size = path_info.size
	}

	src_content, result := file_read_entire( path_src, allocator )
	if ! result {
		log_fmt( "Failed to read file to copy: %v", path_src, LoggerLevel.Error )
		debug_trap()
		return false
	}

	result = file_write_entire( path_dst, src_content, false )
	if ! result {
		log_fmt( "Failed to copy file: %v", path_dst, LoggerLevel.Error )
		debug_trap()
		return false
	}
	return true
}

file_exists :: proc( file_path : string, allocator := context.allocator ) -> b32 {
	path_info, result := file_status( file_path, allocator )
	if result != OS_ERROR_NONE {
		return false
	}
	return true;
}

file_is_locked :: proc( file_path : string ) -> b32 {
	handle, err := file_open(file_path, FS_Open_Readonly)
	if err != OS_ERROR_NONE {
			// If the error indicates the file is in use, return true.
			return true
	}

	// If the file opens successfully, close it and return false.
	file_close(handle)
	return false
}

file_rewind :: proc( file : OS_Handle ) {
	file_seek( file, 0, 0 )
}

file_read_looped :: proc( file : OS_Handle, data : []byte ) {
	total_read, result_code := file_read( file, data )
	if result_code == OS_ERROR_HANDLE_EOF {
		file_rewind( file )
	}
}
