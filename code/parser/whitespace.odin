/* Parser: Whitespace
This is a prototype parser meant to only parse whitespace from visible blocks of code.
Its meant to be the most minimal useful AST with coupling to traditional text file formatting.

All symbols related directly to the parser are prefixed with the PWS_ namespace.

The AST is composed of the following node types:
* Visible
* Spaces
* Tabs
* Line

AST_Visible tracks a slice of visible codepoints.
It tracks a neighboring ASTs (left or right) which should always be Spaces, or Tabs.

AST_Spaces tracks a slice of singluar or consecutive Spaces.
Neighboring ASTS should either be Visible, Tabs.

AST_Tabs tracks a slice of singlar or consectuive Tabs.
Neighboring ASTS should be either Visible or Spaces.

AST_Line tracks a slice of AST nodes of Visible, Spaces, or Tabs that terminate with a New-Line token.
Neighboring ASTS are only Lines.

The ParseData struct will contain an Array of AST_Line. This represents the entire AST where the root is the first entry.
ASTs keep track of neighboring ASTs in double-linked list pattern for ease of use.
This may be removed in the future for perforamance reasons,
since this is a prototype it will only be removed if there is a performance issue.

Because this parser is so primtive, it can only be
manually constructed via an AST editor or from parsed text.
So there is only a parser directly dealing with text.

If its constructed from an AST-Editor. There will not be a content string referencable or runes derived fromt hat content string.
Instead the AST's content will directly contain the runes associated.
*/
package sectr

import "core:os"

Rune_Space           :: ' '
Rune_Tab             :: '\t'
Rune_Carriage_Return :: '\r'
Rune_Line_Feed       :: '\n'
// Rune_Tab_Vertical :: '\v'

PWS_TokenType :: enum u32 {
	Invalid,
	Visible,
	Spaces,
	Tabs,
	New_Line,
	End_Of_File,
	Count,
}

// TODO(Ed) : The runes and token arrays should be handled by a slab allocator
// This can grow in undeterministic ways, persistent will get very polluted otherwise.
PWS_LexResult :: struct {
	tokens    : Array(PWS_Token),
}

PWS_Token :: struct {
	type         : PWS_TokenType,
	line, column : u32,
	content      : StrRunesPair,
}

PWS_AST_Type :: enum u32 {
	Invalid,
	Visible,
	Spaces,
	Tabs,
	Line,
	Count,
}

PWS_AST :: struct {
	using links : DLL_NodeFull(PWS_AST),
	type        : PWS_AST_Type,

	line, column : u32,
	content      : StrRunesPair,
}

PWS_ParseError :: struct {
	token : ^PWS_Token,
	msg   : string,
}

PWS_ParseError_Max         :: 32
PWS_TokenArray_ReserveSize :: 128
PWS_NodeArray_ReserveSize  :: 32 * Kilobyte
PWS_LineArray_ReserveSize  :: 32

// TODO(Ed) : The ast arrays should be handled by a slab allocator dedicated to PWS_ASTs
// This can grow in undeterministic ways, persistent will get very polluted otherwise.
PWS_ParseResult :: struct {
	content   : string,
	tokens    : Array(PWS_Token),
	nodes     : Array(PWS_AST), // Nodes should be dumped in a pool.
	lines     : Array( ^PWS_AST),
	errors    : [PWS_ParseError_Max] PWS_ParseError,
}

PWS_LexerData :: struct {
	using result : PWS_LexResult,

	content       : string,
	previous_rune : rune,
	current_rune  : rune,
	previous      : PWS_TokenType,
	line          : u32,
	column        : u32,
	start  : int,
	length : int,
	current : PWS_Token,
}

pws_parser_lex :: proc ( text : string, allocator : Allocator ) -> ( PWS_LexResult, AllocatorError )
{
	bytes := transmute([]byte) text
	log( str_fmt_tmp( "lexing: %v ...", (len(text) > 30 ? transmute(string) bytes[ :30] : text) ))

	profile(#procedure)
	using lexer : PWS_LexerData
	context.user_ptr = & lexer
	content = text

	if len(text) == 0 {
		ensure( false, "Attempted to lex nothing")
		return result, .None
	}

	rune_type :: proc( codepoint : rune ) -> PWS_TokenType
	{
		using self := context_ext( PWS_LexerData)

		switch codepoint
		{
			case Rune_Space:
				return PWS_TokenType.Spaces

			case Rune_Tab:
				return PWS_TokenType.Tabs

			case Rune_Line_Feed:
				return PWS_TokenType.New_Line

			// Support for CRLF format
			case Rune_Carriage_Return:
			{
				if previous_rune == 0 {
					return PWS_TokenType.Invalid
				}

				// Assume for now its a new line
				return PWS_TokenType.New_Line
			}
		}

		// Everything that isn't the supported whitespace code points is considered 'visible'
		// Eventually we should support other types of whitespace
		return PWS_TokenType.Visible
	}

	alloc_error : AllocatorError
	// tokens, alloc_error = array_init_reserve( PWS_Token, allocator, Kilobyte * 4 )
	tokens, alloc_error = array_init_reserve( PWS_Token, allocator, PWS_TokenArray_ReserveSize )
	if alloc_error != AllocatorError.None {
		ensure(false, "Failed to allocate token's array")
		return result, alloc_error
	}

	line   = 0
	column = 0

	make_token :: proc ( byte_offset : int ) -> AllocatorError
	{
		self := context_ext( PWS_LexerData); using self

		if previous_rune == Rune_Carriage_Return && current_rune != Rune_Line_Feed {
			ensure(false, "Rouge Carriage Return")
		}

		start_ptr   := uintptr( raw_data(content)) + uintptr(start)
		token_slice := transmute(string) byte_slice( rawptr(start_ptr), length )

		current.content = str_intern( token_slice )

		start   = byte_offset
		length  = 0
		line   += cast(u32) (current.type == .New_Line)
		column  = 0

		return array_append( & tokens, current )
	}

	last_rune : rune
	last_byte_offset : int
	for codepoint, byte_offset in text
	{
		type := rune_type( codepoint )
		current_rune = codepoint

		if (current.type != type && previous != .Invalid) ||
			 ( previous_rune != Rune_Carriage_Return && current.type == .New_Line )
		{
			alloc_error = make_token( byte_offset )
			if alloc_error != AllocatorError.None {
				ensure(false, "Failed to append token to token array")
				return lexer, alloc_error
			}
		}

		current.type   = type
		current.line   = line
		current.column = column

		column += 1
		length += 1
		previous      = current.type
		previous_rune = codepoint
		last_byte_offset = byte_offset
	}

	make_token( last_byte_offset )

	return result, alloc_error
}

PWS_ParseData :: struct {
	using result :  PWS_ParseResult,

	left      : u32,
	head      : [^]PWS_Token,
	line      : PWS_AST,
	prev_line : ^PWS_AST,
}

pws_parser_parse :: proc( text : string, allocator : Allocator ) -> ( PWS_ParseResult, AllocatorError )
{
	bytes := transmute([]byte) text

	profile(#procedure)
	using parser : PWS_ParseData
	context.user_ptr = & result

	if len(text) == 0 {
		ensure( false, "Attempted to lex nothing")
		return result, .None
	}

	lex, alloc_error := pws_parser_lex( text, allocator = allocator )
	verify( alloc_error == nil, "Allocation faiure in lex")

	tokens = lex.tokens

	log( str_fmt_tmp( "parsing: %v ...", (len(text) > 30 ? transmute(string) bytes[ :30] : text) ))

	// TODO(Ed): Change this to use a node pool
	nodes, alloc_error = array_init_reserve( PWS_AST, allocator, PWS_NodeArray_ReserveSize )
	verify( alloc_error == nil, "Allocation failure creating nodes array")

	parser.lines, alloc_error = array_init_reserve( ^PWS_AST, allocator, PWS_LineArray_ReserveSize )
	verify( alloc_error == nil, "Allocation failure creating line array")

	//region Helper procs
	eat_line :: #force_inline proc()
	{
		self := context_ext( PWS_ParseData); using self
		tok := cast( ^PWS_Token) head

		line.type    = .Line
		line.line    = tok.line
		line.column  = tok.column
		line.content = tok.content

		alloc_error := array_append( & nodes, line )
		verify( alloc_error == nil, "Allocation failure appending node")
		node := & nodes.data[ nodes.num - 1 ]

		// TODO(Ed): Review this with multiple line test
		dll_push_back( & prev_line, node )
		prev_line = node

		// Debug build compile error
			// alloc_error = array_append( & lines, prev_line )
			// verify( alloc_error == nil, "Allocation failure appending node")

		line = {}
	}
	//endregion

	head = & tokens.data[0]
	left = u32(tokens.num)

	// Parse Line
	for ; left > 0;
	{
		type : PWS_AST_Type
		#partial switch head[0].type
		{
			case .Tabs:
				type = .Tabs

			case .Spaces:
				type = .Spaces

			case .Visible:
				type = .Visible

			case .New_Line:
				eat_line()

				alloc_error = array_append( & parser.lines, prev_line )
				verify( alloc_error == nil, "Allocation failure appending node")

			case PWS_TokenType.End_Of_File:
		}

		if type != .Line
		{
			tok := cast( ^PWS_Token) head
			ast : PWS_AST
			ast.type    = type
			ast.line    = tok.line
			ast.column  = tok.column
			ast.content = tok.content

			// Compiler Error (-Debug)
			// prev_node = array_back( nodes )
			prev_node : ^PWS_AST = nil
			if nodes.num > 0 {
				prev_node = & nodes.data[ nodes.num - 1 ]
			}

			alloc_error := array_append( & nodes, ast )
			verify( alloc_error == nil, "Allocation failure appending node")

			node := & nodes.data[ nodes.num - 1 ]

			// dll_push_back( & prev_node, last_node )
			{
				if prev_node != nil
				{
					node.prev      = prev_node
					prev_node.next = node
				}
			}

			// dll_fl_append( & line, last_node )
			if line.first == nil {
				line.first = node
				line.last  = node
			}
			else {
				line.last = node
			}
		}

		head  = head[ 1:]
		left -= 1
	}

	if line.first != nil {
		eat_line()

		alloc_error = array_append( & parser.lines, prev_line )
		verify( alloc_error == nil, "Allocation failure appending node")
	}

	return result, alloc_error
}
