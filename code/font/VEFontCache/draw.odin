package VEFontCache

FrameBufferPass :: enum u32 {
	None             = 0,
	Glyph            = 1,
	Atlas            = 2,
	Target           = 3,
	Target_Unchanged = 4,
}

DrawCall :: struct {
	pass              : FrameBufferPass,
	start_index       : u32,
	end_index         : u32,
	clear_before_draw : b32,
	region            : AtlasRegionKind,
	colour            : [4]f32,
}

DrawCall_Default :: DrawCall {
	pass              = .None,
	start_index       = 0,
	end_index         = 0,
	clear_before_draw = false,
	region            = .A,
	colour            = { 1.0, 1.0, 1.0, 1.0 }
}

DrawList :: struct {
	vertices : Array(Vertex),
	indices  : Array(u32),
	calls    : Array(DrawCall),
}
