package sectr

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strings"

Serializer_Version :: 1
Serializer_Loading :: false

ArchiveData :: struct {
	data        : [] byte,
	version     : i32,
}

archive_init_temp :: proc () -> ^ ArchiveData {
	archive := new( ArchiveData, context.temp_allocator )
	archive.version = Serializer_Version
	return archive
}

state_serialize :: proc ( archive : ^ ArchiveData = nil ) {

}

project_serialize :: proc ( project : ^ Project, archive : ^ ArchiveData, is_writting : b32 = true )
{
	options : json.Marshal_Options
	options.spec        = json.Specification.MJSON
	options.indentation = 2
	options.pretty      = true
	options.use_spaces  = false

	if is_writting
	{
		marshal_archive : struct {
			version : i32,
			project : Project
		}
		marshal_archive.version = archive.version
		marshal_archive.project = project^
		// TODO(Ed): In the future this will be more complicated, as serialization of workspaces and the code database won't be trivial

		json_data, marshal_code := json.marshal( marshal_archive, options, allocator = context.temp_allocator )
		verify( marshal_code != json.Marshal_Data_Error.None, "Failed to marshal the project to JSON" )

		archive.data = json_data
	}
	else
	{
		parsed_json, parse_code := json.parse( archive.data, json.Specification.MJSON, allocator = context.temp_allocator )
		verify( parse_code != json.Error.None, "Failed to parse project JSON")

		archive_json := parsed_json.(json.Object)
		archive_version : i32 = cast(i32) archive_json["version"].(json.Float)
		verify( Serializer_Version != archive_version, "Version mismatch on archive!" )

		project_json := archive_json["project"].(json.Object)
		project.name  = project_json["name"].(json.String)

		// TODO(Ed) : Make this a separate proc
		workspace_json        := project_json["workspace"].(json.Object)
		project.workspace.name = workspace_json["name"].(json.String)

		// DEBUG DUD
		options.use_spaces = false
	}
}

project_save :: proc ( project : ^ Project, archive : ^ ArchiveData = nil )
{
	archive := archive
	if archive == nil {
		archive = archive_init_temp()
	}
	project_serialize( project, archive )

	if ! os.is_dir( project.path ) {
		os.make_directory( project.path )
		verify( ! os.is_dir( project.path ), "Failed to create project path for saving" )
	}

	os.write_entire_file( fmt.tprint( project.path, project.name, ".sectr_proj", sep = ""), archive.data )
}

project_load :: proc ( path : string, project : ^ Project, archive : ^ ArchiveData = nil ) {
	archive := archive
	if archive == nil {
		archive = archive_init_temp()
	}

	data, read_code := os.read_entire_file( path, context.temp_allocator )
	verify( ! read_code, "Failed to read from project file" )

	archive.data = data
	project_serialize( project, archive, Serializer_Loading )
}
