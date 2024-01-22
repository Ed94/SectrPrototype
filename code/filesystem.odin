package sectr

import "core:fmt"
import "core:os"
import "core:runtime"

copy_file_sync :: proc( path_src, path_dst: string ) -> bool
{
    file_size : i64
	{
		path_info, result := os.stat( path_src, context.temp_allocator )
		if result != os.ERROR_NONE {
			fmt.println("Error getting file info: ", result )
			return false
		}
		file_size = path_info.size
	}

	src_content, result := os.read_entire_file( path_src, context.temp_allocator )
	if ! result {
		fmt.println( "Failed to read file to copy" )
		runtime.debug_trap()
		return false
	}

	result = os.write_entire_file( path_dst, src_content, false )
	if ! result {
		fmt.println( "Failed to copy file")
		runtime.debug_trap()
		return false
	}
    return true
}
