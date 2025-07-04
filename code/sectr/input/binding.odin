package sectr

InputBindSig :: distinct u128

InputBind :: struct {
	keys:       [4]KeyCode,
	mouse_btns: [4]MouseBtn,
	scroll:     [2]AnalogAxis,
	modifiers:  ModifierCodeFlags,
	label:      string,
}

InputBindStatus :: struct {
	detected: b32,
	consumed: b32,
	frame_id: u64,
}

InputActionProc :: #type proc(user_ptr: rawptr)
InputAction :: struct {
	id:           int,
	user_ptr:     rawptr,
	cb:           InputActionProc,
	always:       b32,
}

InputContext :: struct {
	binds:         []InputBind,
	status:        []InputBindStatus,
	onpush_action: []InputAction,
	onpop_action:  []InputAction,
	signature:     []InputBindSig,
}

inputbind_signature :: proc(binding: InputBind) -> InputBindSig {
	// TODO(Ed): Figure out best hasher for this...
	return cast(InputBindSig) 0
}

// Note(Ed): Bindings should be remade for a context when a user modifies any in configuration.

inputcontext_init :: proc(ctx: ^InputContext, binds: []InputBind, onpush: []InputAction = {}, onpop: []InputAction = {}) {
	ctx.binds         = binds
	ctx.onpush_action = onpush
	ctx.onpop_action  = onpop

	for bind, id in ctx.binds {
		ctx.signature[id] = inputbind_signature(bind)
	}
}

inputcontext_make :: #force_inline proc(binds: []InputBind, onpush: []InputAction = {}, onpop: []InputAction = {}) -> InputContext {
	ctx: InputContext; inputcontext_init(& ctx, binds, onpush, onpop); return ctx
}

// Should be called by the user explicitly during frame cleanup.
inputcontext_clear_status :: proc(ctx: ^InputContext) {
	zero(ctx.status)
}

inputbinding_status :: #force_inline proc(id: int) -> InputBindStatus { 
	return get_input_binds().status[id]
}

inputcontext_inherit :: proc(dst: ^InputContext, src: ^InputContext) {
	for dst_id, dst_sig in dst.signature 
	{
		for src_id, src_sig in src.signature 
		{
			if dst_sig != src_sig {
				continue
			}
			dst.status[dst_id] = src.status[src_id]
		}
	}
}

inputcontext_push :: proc(ctx: ^InputContext, dont_inherit_status: b32 = false) {
	// push context stack
	// clear binding status for context
	// optionally inherit status
	// detect status
	// Dispatch push actions meeting conditions
}

inputcontext_pop :: proc(ctx: ^InputContext, dont_inherit_status: b32 = false) {
	// Dispatch pop actions meeting conditions
	// parent inherit consumed statuses
	// pop context stack
}
