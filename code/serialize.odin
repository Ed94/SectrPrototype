package sectr

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:reflect"
import "core:runtime"
import "core:strings"

@(private="file")
assign_int :: proc(val: any, i: $T) -> bool {
	v := reflect.any_core(val)
	switch &dst in v {
	case i8:      dst = i8     (i)
	case i16:     dst = i16    (i)
	case i16le:   dst = i16le  (i)
	case i16be:   dst = i16be  (i)
	case i32:     dst = i32    (i)
	case i32le:   dst = i32le  (i)
	case i32be:   dst = i32be  (i)
	case i64:     dst = i64    (i)
	case i64le:   dst = i64le  (i)
	case i64be:   dst = i64be  (i)
	case i128:    dst = i128   (i)
	case i128le:  dst = i128le (i)
	case i128be:  dst = i128be (i)
	case u8:      dst = u8     (i)
	case u16:     dst = u16    (i)
	case u16le:   dst = u16le  (i)
	case u16be:   dst = u16be  (i)
	case u32:     dst = u32    (i)
	case u32le:   dst = u32le  (i)
	case u32be:   dst = u32be  (i)
	case u64:     dst = u64    (i)
	case u64le:   dst = u64le  (i)
	case u64be:   dst = u64be  (i)
	case u128:    dst = u128   (i)
	case u128le:  dst = u128le (i)
	case u128be:  dst = u128be (i)
	case int:     dst = int    (i)
	case uint:    dst = uint   (i)
	case uintptr: dst = uintptr(i)
	case: return false
	}
	return true
}

when false {
unmarshal_from_object :: proc( $Type: typeid, object : json.Object ) -> Type
{
	result : Type
	type_info := type_info_of(Type)
	#partial switch type in type_info.variant {
		case runtime.Type_Info_Union:
			ensure( true, "This proc doesn't support raw unions" )
	}

	base_ptr := uintptr( & result )

	field_infos := reflect.struct_fields_zipped(Type)
	for field_info in field_infos
	{
		field_type := field_info.type.id
		field_ptr := cast(field_type) rawptr( base_ptr + field_info.offset )

		#partial switch type in field_info.type.variant {
			case runtime.Type_Info_Integer:
				field_ptr = object[filed_info.name].(json.Integer)
		}
	}

	return result
}
}

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
	// TODO(Ed): We'll need this for a better save/load snapshot setup.
}

project_serialize :: proc ( project : ^ Project, archive : ^ ArchiveData, is_writting : b32 = true )
{
	options : json.Marshal_Options
	options.spec        = json.Specification.MJSON
	options.indentation = 2
	options.pretty      = true
	options.use_spaces  = false

	MarshalArchive :: struct {
			version : i32,
			project : Project
	}

	if is_writting
	{
		marshal_archive : MarshalArchive
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

		// Note(Ed) : This works fine for now, but eventually it will most likely break with pointers...
		// We'll most likely set things up so that all refs in the project & workspace are handles.
		marshal_archive : MarshalArchive
		json.unmarshal( archive.data, & marshal_archive, spec = json.Specification.MJSON, allocator = context.temp_allocator )
		if marshal_archive.version == Serializer_Version {
			project^ = marshal_archive.project
		}

		// Manual unmarshal
		when false
		{
			project_json := archive_json["project"].(json.Object)
			project.name  = project_json["name"].(json.String)

			// TODO(Ed) : Make this a separate proc
			workspace_json := project_json["workspace"].(json.Object)
			{
				using project.workspace
				name = workspace_json["name"].(json.String)

				// cam = unmarshal_from_object(Camera, workspace_json["camera"].(json.Object) )
				frame_1 = frame_json_unmarshal( & workspace_json["frame_1"] )
			}
		}

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

project_load :: proc ( path : string, project : ^ Project, archive : ^ ArchiveData = nil )
{
	archive := archive
	if archive == nil {
		archive = archive_init_temp()
	}

	data, read_code := os.read_entire_file( path, context.temp_allocator )
	verify( ! read_code, "Failed to read from project file" )

	archive.data = data
	project_serialize( project, archive, Serializer_Loading )
}
