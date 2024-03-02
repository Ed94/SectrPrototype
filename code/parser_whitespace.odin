/* Parser: Whitespace
This is a prototype parser meant to only parse whitespace from visible blocks of code.
Its meant to be the most minimal useful AST for boostrapping an AST Editor.

All symbols related directly to the parser are prefixed with the WS_ namespace.

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
Rune_Carriage_Return :: 'r'
Rune_New_Line        :: '\n'
// Rune_Tab_Vertical :: '\v'

WS_TokenType :: enum u32 {
	Invalid,
	Visible,
	Space,
	Tab,
	New_Line,
	Count,
}

// TODO(Ed) : The runes and token arrays should be handled by a slab allocator dedicated to ASTs
// This can grow in undeterministic ways, persistent will get very polluted otherwise.
WS_LexResult :: struct {
	allocator : Allocator,
	content   : string,
	runes     : []rune,
	tokens    : Array(WS_Token),
}

WS_Token :: struct {
	type         : WS_TokenType,
	line, column : u32,
	ptr          : ^rune,
}

WS_AST_Content :: union #no_nil {
	[] WS_Token,
	[] rune,
}

WS_AST_Spaces :: struct {
	content : WS_AST_Content,

	using links : DLL_NodePN(WS_AST),
}

WS_AST_Tabs :: struct {
	content : WS_AST_Content,

	using links : DLL_NodePN(WS_AST),
}

WS_AST_Visible :: struct {
	content : WS_AST_Content,

	using links : DLL_NodePN(WS_AST),
}

WS_AST_Line :: struct {
	using content : DLL_NodeFL(WS_AST),
	end_token     : ^ WS_Token,

	using links : DLL_NodePN(WS_AST),
}

WS_AST :: union #no_nil {
	WS_AST_Visible,
	WS_AST_Spaces,
	WS_AST_Tabs,
	WS_AST_Line,
}

WS_ParseError :: struct {
	token : ^WS_Token,
	msg   : string,
}

WS_ParseError_Max        :: 32
WS_NodeArray_ReserveSize :: Kilobyte * 4
WS_LineArray_RserveSize  :: Kilobyte

// TODO(Ed) : The ast arrays should be handled by a slab allocator dedicated to ASTs
// This can grow in undeterministic ways, persistent will get very polluted otherwise.
WS_ParseResult :: struct {
	content   : string,
	runes     : []rune,
	tokens    : Array(WS_Token),
	nodes     : Array(WS_AST),
	lines     : Array( ^WS_AST_Line),
	errors    : [WS_ParseError_Max] WS_ParseError,
}

// @(private="file")
// AST :: WS_AST

ws_parser_lex :: proc ( content : string, allocator : Allocator ) -> ( WS_LexResult, AllocatorError )
{
	LexerData :: struct {
		using result : WS_LexResult,

		head   : [^] rune,
		left   : i32,
		line   : u32,
		column : u32,
	}
	using lexer : LexerData
	context.user_ptr = & lexer

	rune_type :: proc() -> WS_TokenType
	{
		using self := context_ext( LexerData)

		switch (head[0])
		{
			case Rune_Space:
				return WS_TokenType.Space

			case Rune_Tab:
				return WS_TokenType.Tab

			case Rune_New_Line:
				return WS_TokenType.New_Line

			// Support for CRLF format
			case Rune_Carriage_Return:
			{
				previous := cast( ^ rune) (uintptr(head) - 1)
				if (previous ^) == Rune_New_Line {
					return WS_TokenType.New_Line
				}
			}
		}

		// Everything that isn't the supported whitespace code points is considered 'visible'
		// Eventually we should support other types of whitespace
		return WS_TokenType.Visible
	}

	advance :: proc() -> WS_TokenType {
		using self := context_ext( LexerData)

		head    = head[1:]
		left   -= 1
		column += 1
		type   := rune_type()
		line   += u32(type == WS_TokenType.New_Line)
		return type
	}

	alloc_error : AllocatorError
	runes, alloc_error = to_runes( content, allocator )
	if alloc_error != AllocatorError.None {
		return result, alloc_error
	}

	left = cast(i32) len(runes)
	head = & runes[0]

	tokens, alloc_error = array_init_reserve( WS_Token, allocator, u64(left / 2) )
	if alloc_error != AllocatorError.None {
		ensure(false, "Failed to allocate token's array")
		return result, alloc_error
	}

	line   = 0
	column = 0

	for ; left > 0;
	{
		current       : WS_Token
		current.type   = rune_type()
		current.line   = line
		current.column = column

		for ; advance() == current.type; {
		}

		alloc_error = array_append( & tokens, current )
		if alloc_error != AllocatorError.None {
			ensure(false, "Failed to append token to token array")
			return lexer, alloc_error
		}
	}

	return result, alloc_error
}

ws_parser_parse :: proc( content : string, allocator : Allocator ) -> ( WS_ParseResult, AllocatorError )
{
	ParseData :: struct {
		using result :  WS_ParseResult,

		left  : u32,
		head  : [^]WS_Token,
		line  : WS_AST_Line,
	}

	using parser : ParseData
	context.user_ptr = & result

	//region Helper procs
	peek_next :: proc() -> ( ^WS_Token)
	{
		using self := context_ext( ParseData)
		if left - 1 ==  0 {
			return nil
		}

		return head[ 1: ]
	}

	check_next :: proc(  expected : WS_TokenType ) -> b32 {
		using self := context_ext( ParseData)

		next := peek_next()
		return next != nil && next.type == expected
	}

	advance :: proc( expected : WS_TokenType ) -> (^WS_Token)
	{
		using self := context_ext( ParseData)
		next := peek_next()
		if next == nil {
			return nil
		}
		if next.type != expected {
			ensure( false, "Didn't get expected token type from next in lexed" )
			return nil
		}
		head = next
		return head
	}
	//endregion Helper procs

	lex, alloc_error := ws_parser_lex( content, allocator )
	if alloc_error != AllocatorError.None {

	}

	runes  = lex.runes
	tokens = lex.tokens

	nodes, alloc_error = array_init_reserve( WS_AST, allocator, WS_NodeArray_ReserveSize )
	if alloc_error != AllocatorError.None {

	}

	lines, alloc_error = array_init_reserve( ^WS_AST_Line, allocator, WS_LineArray_RserveSize )
	if alloc_error != AllocatorError.None {

	}

	head = & tokens.data[0]

	// Parse Line
	for ; left > 0;
	{
		parse_content :: proc( $ Type : typeid, tok_type : WS_TokenType ) -> Type
		{
			using self := context_ext( ParseData)

			ast   : Type
			start := head
			end   : [^]WS_Token

			for ; check_next( WS_TokenType.Visible ); {
				end = advance( tok_type )
			}
			ast.content = slice_ptr( start, ptr_sub( end, start ))
			return ast
		}

		add_node :: proc( ast : WS_AST ) //-> ( should_return : b32 )
		{
			using self := context_ext( ParseData)

			// TODO(Ed) : Harden this
			array_append( & nodes, ast )

			if line.first == nil {
				line.first = array_back( & nodes )
			}
			else
			{
				line.last = array_back( & nodes)
			}
		}

		// TODO(Ed) : Harden this
		#partial switch head[0].type
		{
			case WS_TokenType.Visible:
			{
				ast := parse_content( WS_AST_Visible, WS_TokenType.Visible )
				add_node( ast )
			}
			case WS_TokenType.Space:
			{
				ast := parse_content( WS_AST_Visible, WS_TokenType.Space )
				add_node( ast )
			}
			case WS_TokenType.Tab:
			{
				ast := parse_content( WS_AST_Tabs, WS_TokenType.Tab )
				add_node( ast )
			}
			case WS_TokenType.New_Line:
			{
				line.end_token = head

				ast : WS_AST
				ast = line

				// TODO(Ed) : Harden This
				array_append( & nodes, ast )
				array_append( & lines, & array_back( & nodes).(WS_AST_Line) )
				line = {}
			}
		}
	}

	return result, alloc_error
}
