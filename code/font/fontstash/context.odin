package fontstash

import "base:runtime"

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

CB_Resize :: #type proc(data : rawptr, width, height : u32 )
CB_Update :: #type proc(data : rawptr, dirty_rect : Rect, texture_data : rawptr )

Callbacks :: struct {
	resize : CB_Resize,
	update : CB_Update,
}

Context :: struct {
	callstack_ctx : runtime.Context,

	// params : Params,

	parser_kind : ParserKind,

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

	quad_location : QuadLocation,

	// dirty rectangle of the texture regnion that was updated
	dirty_rect : Rect,

	handle_error : HandleErrorProc,
	error_uptr   : rawptr,

	using callbacks : Callbacks,
}

// The package assumes this will exist so long as the owning runtime module is loaded and it has been initialized before usage.
Module_Context : ^Context

destroy_context :: proc()
{
	using Module_Context

	// for & font in array_to_slice(fonts) {
	// }
	delete( fonts )
	delete( atlas )

}

// For usage during hot-reload, when the instance reference of a context is lost.
reload_context :: proc( ctx : ^Context )
{
	Module_Context = ctx
	using Module_Context

	callstack_ctx = context
}

startup_context :: proc( ctx : ^Context, parser_kind : ParserKind, width, height : u32, quad_location : QuadLocation )
{
	Module_Context = ctx
	using Module_Context

	callstack_ctx = context

	error : AllocatorError
	fonts, error = make( Array(Font), 8 )
	assert( error == AllocatorError.None, "Failed to allocate fonts array" )
}
