/* Parser: Whitespace
This is a prototype parser meant to only parse whitespace from visible blocks of code.
Its meant to be the most minimal useful AST for boostrapping an AST Editor.

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
Rune_Carriage_Return :: 'r'
Rune_New_Line        :: '\n'
// Rune_Tab_Vertical :: '\v'

PWS_TokenType :: enum u32 {
	Invalid,
	Visible,
	Space,
	Tab,
	New_Line,
	Count,
}

// TODO(Ed) : The runes and token arrays should be handled by a slab allocator
// This can grow in undeterministic ways, persistent will get very polluted otherwise.
PWS_LexResult :: struct {
	allocator : Allocator,
	content   : string,
	runes     : []rune,
	tokens    : Array(PWS_Token),
}

PWS_Token :: struct {
	type         : PWS_TokenType,
	line, column : u32,
	ptr          : ^rune,
}

PWS_AST_Content :: union #no_nil {
	^PWS_Token,
	[] rune,
}

PWS_AST_Spaces :: struct {
	content : PWS_AST_Content,

	using links : DLL_NodePN(PWS_AST),
}

PWS_AST_Tabs :: struct {
	content : PWS_AST_Content,

	using links : DLL_NodePN(PWS_AST),
}

PWS_AST_Visible :: struct {
	content : PWS_AST_Content,

	using links : DLL_NodePN(PWS_AST),
}

PWS_AST_Line :: struct {
	using content : DLL_NodeFL(PWS_AST),
	end_token     : ^ PWS_Token,

	using links : DLL_NodePN(PWS_AST),
}

PWS_AST :: union #no_nil {
	PWS_AST_Visible,
	PWS_AST_Spaces,
	PWS_AST_Tabs,
	PWS_AST_Line,
}

PWS_ParseError :: struct {
	token : ^PWS_Token,
	msg   : string,
}

PWS_ParseError_Max        :: 32
PWS_NodeArray_ReserveSize :: Kilobyte * 4
PWS_LineArray_RserveSize  :: Kilobyte

// TODO(Ed) : The ast arrays should be handled by a slab allocator dedicated to PWS_ASTs
// This can grow in undeterministic ways, persistent will get very polluted otherwise.
PWS_ParseResult :: struct {
	content   : string,
	runes     : []rune,
	tokens    : Array(PWS_Token),
	nodes     : Array(PWS_AST),
	lines     : Array( ^PWS_AST_Line),
	errors    : [PWS_ParseError_Max] PWS_ParseError,
}

// @(private="file")
// AST :: PWS_AST

pws_parser_lex :: proc ( content : string, allocator : Allocator ) -> ( PWS_LexResult, AllocatorError )
{
	LexerData :: struct {
		using result : PWS_LexResult,

		head   : [^] rune,
		left   : i32,
		line   : u32,
		column : u32,
	}
	using lexer : LexerData
	context.user_ptr = & lexer

	rune_type :: proc() -> PWS_TokenType
	{
		using self := context_ext( LexerData)

		switch (head[0])
		{
			case Rune_Space:
				return PWS_TokenType.Space

			case Rune_Tab:
				return PWS_TokenType.Tab

			case Rune_New_Line:
				return PWS_TokenType.New_Line

			// Support for CRLF format
			case Rune_Carriage_Return:
			{
				if left - 1 ==  0 {
					return PWS_TokenType.Invalid
				}
				if head[1] == Rune_New_Line {
					return PWS_TokenType.New_Line
				}
			}
		}

		// Everything that isn't the supported whitespace code points is considered 'visible'
		// Eventually we should support other types of whitespace
		return PWS_TokenType.Visible
	}

	advance :: proc() -> PWS_TokenType {
		using self := context_ext( LexerData)

		head    = head[1:]
		left   -= 1
		column += 1
		type   := rune_type()
		line   += u32(type == PWS_TokenType.New_Line)
		return type
	}

	alloc_error : AllocatorError
	runes, alloc_error = to_runes( content, allocator )
	if alloc_error != AllocatorError.None {
		ensure(false, "Failed to allocate runes from content")
		return result, alloc_error
	}

	left = cast(i32) len(runes)
	head = & runes[0]

	tokens, alloc_error = array_init_reserve( PWS_Token, allocator, u64(left / 2) )
	if alloc_error != AllocatorError.None {
		ensure(false, "Failed to allocate token's array")
		return result, alloc_error
	}

	line   = 0
	column = 0

	for ; left > 0;
	{
		current       : PWS_Token
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

pws_parser_parse :: proc( content : string, allocator : Allocator ) -> ( PWS_ParseResult, AllocatorError )
{
	ParseData :: struct {
		using result :  PWS_ParseResult,

		left  : u32,
		head  : [^]PWS_Token,
		line  : PWS_AST_Line,
	}

	using parser : ParseData
	context.user_ptr = & result

	//region Helper procs
	peek_next :: proc() -> ( ^PWS_Token)
	{
		using self := context_ext( ParseData)
		if left - 1 ==  0 {
			return nil
		}

		return head[ 1: ]
	}

	check_next :: proc(  expected : PWS_TokenType ) -> b32 {
		using self := context_ext( ParseData)

		next := peek_next()
		return next != nil && next.type == expected
	}

	advance :: proc( expected : PWS_TokenType ) -> (^PWS_Token)
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

	lex, alloc_error := pws_parser_lex( content, allocator )
	if alloc_error != AllocatorError.None {

	}

	runes  = lex.runes
	tokens = lex.tokens

	nodes, alloc_error = array_init_reserve( PWS_AST, allocator, PWS_NodeArray_ReserveSize )
	if alloc_error != AllocatorError.None {

	}

	lines, alloc_error = array_init_reserve( ^PWS_AST_Line, allocator, PWS_LineArray_RserveSize )
	if alloc_error != AllocatorError.None {

	}

	head = & tokens.data[0]

	// Parse Line
	for ; left > 0;
	{
		parse_content :: proc( $ Type : typeid, tok_type : PWS_TokenType ) -> Type
		{
			using self := context_ext( ParseData)

			ast : Type
			ast.content = cast( ^PWS_Token) head
			advance( tok_type )
			return ast
		}

		add_node :: proc( ast : PWS_AST ) //-> ( should_return : b32 )
		{
			using self := context_ext( ParseData)

			// TODO(Ed) : Harden this
			array_append( & nodes, ast )

			if line.first == nil {
				line.first = array_back( nodes )
			}
			else
			{
				line.last = array_back( nodes)
			}
		}

		// TODO(Ed) : Harden this
		#partial switch head[0].type
		{
			case PWS_TokenType.Visible:
			{
				ast := parse_content( PWS_AST_Visible, PWS_TokenType.Visible )
				add_node( ast )
			}
			case PWS_TokenType.Space:
			{
				ast := parse_content( PWS_AST_Visible, PWS_TokenType.Space )
				add_node( ast )
			}
			case PWS_TokenType.Tab:
			{
				ast := parse_content( PWS_AST_Tabs, PWS_TokenType.Tab )
				add_node( ast )
			}
			case PWS_TokenType.New_Line:
			{
				line.end_token = head

				ast : PWS_AST
				ast = line

				// TODO(Ed) : Harden This
				array_append( & nodes, ast )
				array_append( & lines, & array_back(nodes).(PWS_AST_Line) )
				line = {}
			}
		}
	}

	return result, alloc_error
}
