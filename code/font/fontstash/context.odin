package fontstash

import "base:runtime"
import "core:slice"

// Legacy of original implementation
// Not sure going to use
Params :: struct {
	parser_kind   : ParserKind,
	width, height : i32,
	quad_location : QuadLocation, // (flags)
	render_create : RenderCreateProc,
	render_resize : RenderResizeProc,
	render_update : RenderUpdateProc,
	render_draw   : RenderDrawProc,
	render_delete : RenderDelete,
}

OnResizeProc :: #type proc(data : rawptr, width, height : u32 )
OnUpdateProc :: #type proc(data : rawptr, dirty_rect : Rect, texture_data : rawptr )

Callbacks :: struct {
	resize : OnResizeProc,
	update : OnUpdateProc,
}

Context :: struct {
	callstack_ctx : runtime.Context,

	// params : Params,

	parser_kind : ParserKind,
	parser_ctx  : ParserContext,

	fonts : Array(Font),

// Atlas
	atlas           : Array(AtlasNode),
	texture_data    : []byte,
	width, height   : i32,
// ----

	normalized_size : Vec2,

	verts   : [Vertex_Count * 2]f32,
	tcoords : [Vertex_Count * 2]f32,
	colors  : [Vertex_Count    ]f32,

	vis_stack  : StackFixed(VisState, Max_VisStates),

	quad_loc : QuadLocation,

	// dirty rectangle of the texture regnion that was updated
	dirty_rect : Rect,

	handle_error   : HandleErrorProc,
	error_userdata : rawptr,

	using callbacks : Callbacks,
}

// The package assumes this will exist so long as the owning runtime module is loaded and it has been initialized before usage.
Module_Context : ^Context

destroy_context :: proc()
{
	using Module_Context

	for & font in array_to_slice(fonts) {
		if font.free_data {
			// delete(font.data)
		}

		// delete(font.name)
		delete(font.glyphs)
	}
	delete( fonts )
	delete( atlas )
	delete( array_underlying_slice(texture_data) )
	// delete( vis_stack )
}

// For usage during hot-reload, when the instance reference of a context is lost.
reload_context :: proc( ctx : ^Context )
{
	Module_Context = ctx
	using Module_Context

	callstack_ctx = context
}

rest :: proc() {
	using Module_Context

	// atlas_reset()
	// dirty_rect_reset()
	slice.zero(texture_data)

	for & font in array_to_slice(fonts) {
		// font_lut_reset( & font )
	}

	// atlas_add_white_rect(2, 2)
	// push_vis_state()
	// clear_vis_state()
}

// Its recommmended to use an allocator that can handle resizing efficiently for the atlas nodes & texture (at least)
startup_context :: proc( ctx : ^Context, parser_kind : ParserKind,
	atlas_texture_width, atlas_texture_height : u32, quad_origin_location : QuadLocation,
	allocator := context.allocator )
{
	Module_Context    = ctx
	using Module_Context

	width    = cast(i32) atlas_texture_width
	height   = cast(i32) atlas_texture_height
	quad_loc = quad_origin_location

	context.allocator = allocator
	callstack_ctx     = context

	error : AllocatorError
	fonts, error = make( Array(Font), 8 )
	assert( error == AllocatorError.None, "Failed to allocate fonts array" )

	texture_data_array : Array(byte)
	texture_data_array, error = make( Array(byte), u64(width * height) )
	assert( error == AllocatorError.None, "Failed to allocate fonts array" )
	texture_data = array_to_slice(texture_data_array)

	// TODO(Ed): Verfiy and remove
	{
		quick_check := underlying_slice(texture_data)
		assert( & texture_data_array.header == & quick_check )
	}

	atlas, error = make( Array(AtlasNode), Init_Atlas_Nodes )
	assert( error == AllocatorError.None, "Failed to allocate fonts array" )
	// dirty_rect_reset()

	append(& atlas, AtlasNode { width = i16(width) })

	// atlas_add_white_rect(2, 2)

	// push_vis_state()
	// clear_vis_state()
}
