/* Parser: Code Agnostic
This is a 'coding langauge agnostic' parser.
Its not meant to parse regular textual formats used in natural langauges (paragraphs, sentences, etc).
It instead is meant to encode constructs significant to most programming languages.

AST Types:
* Word
* Operator
* BracketsScope

This parser supports parsing whitepsace asts or raw text content.
Operator tokens are not parsed into expressions (binary or polish) Thats beyond the scope of this parser.
*/
package sectr

PA_TokenType :: enum u32 {
	Invalid,

	B_Literal_Begin,
		Integer,  // 12345
		Deciaml,  // 123.45
		Word,     // Any string of visible characters that doesn't use an operator symbol.
	B_Literal_End,

	B_Operator_Begin,
		Ampersand,              // &
		Ampersand_Double,       // &&
		Ampersand_Double_Equal, // &&=
		Ampersand_Equal,        // &=
		And_Not,                // &~
		And_Not_Equal,          // &~=
		Arrow_Left,             // <-
		Arrow_Right,            // ->
		Asterisk,               // *
		Asterisk_Equal,         // *=
		At,                     // @
		Backslash,              // \
		Backslash_Double,       // \\
		Brace_Open,             // {
		Brace_Close,            // }
		Bracket_Open,           // [
		Bracket_Close,          // ]
		Caret,                  // ^
		Caret_Equal,            // ^=
		Colon,                  // :
		Comma,                  // ,
		Dash_Triple,            // ---
		Dollar,                 // $
		Ellispis_Dobule,        // ..
		Ellipsis_Triple,        // ...
		Equal,                  // =
		Equal_Double,           // ==
		Exclamation,            // !
		Exclamation_Equal,      // !=
		Greater,                // >
		Greater_Double,         // >>
		Greater_Double_Equal,   // >>=
		Greater_Equal,          // >=
		Hash,                   // #
		Lesser,                 // <
		Lesser_Double,          // <<
		Lesser_Double_Equal,    // <<=
		Lesser_Equal,           // <=
		Minus,                  // -
		Minus_Double,           // --
		Minus_Equal,            // -=
		Parenthesis_Open,       // (
		Parenthesis_Close,      // )
		Percent,                // %
		Percent_Equal,          // %=
		Percent_Double,         // %%
		Percent_Dboule_Equal,   // %%=
		Period,                 // .
		Plus,                   // +
		Plus_Dobule,            // ++
		Plus_Equal,             // +=
		Question,               // ?
		Semi_Colon,             // ;
		Slash,                  // /
		Slash_Equal,            // /=
		Slash_Double,           //
		Tilde,                  // ~
		Tilde_Equal,            // ~=
		Vert_Bar,               // |
		Vert_Bar_Double,        // ||
		Vert_Bar_Equal,         // |=
		Vert_Bar_Double_Equal,  // |==
	B_Operator_End,

	Count,
}

PA_Token_Str_Table := [PA_TokenType.Count] string {
	"____Invalid____", // Invalid,

	"____B_Literal_Begin____", // B_Literal_Begin,
		"____Integer____",       // Integer,  // 12345
		"____Deciaml____",       // 123.45
		"____Word____",          // Any string of visible characters that doesn't use an operator symbol.
	"____B_Literal_Begin____", // B_Literal_End,

	"____B_Operator_Begin____", // B_Operator_Begin,
		"&",    // 	Ampersand,              // &
		"&&",   // 	Ampersand_Double,       // &&
		"&&=",  // 	Ampersand_Double_Equal, // &&=
		"&=",   // 	Ampersand_Equal,        // &=
		"&~",   // 	And_Not,                // &~
		"&~=",  // 	And_Not_Equal,          // &~=
		"<-",   // 	Arrow_Left,             // <-
		"->",   // 	Arrow_Right,            // ->
		"*",    // 	Asterisk,               // *
		"*=",   // 	Asterisk_Equal,         // *=
		"@",    // 	At,                     // @
		"\\",   // 	Backslash,              // \
		"\\\\", // 	Backslash_Double,       // \\
		"{",    // 	Brace_Open,             // {
		"}",    // 	Brace_Close,            // }
		"[",    // 	Bracket_Open,           // [
		"]",    // 	Bracket_Close,          // ]
		"^",    // 	Caret,                  // ^
		"^=",   // 	Caret_Equal,            // ^=
		":",    // 	Colon,                  // :
		",",    // 	Comma,                  // ,
		"---",  // 	Dash_Triple,            // ---
		"$",    // 	Dollar,                 // $
		"..",   // 	Ellispis_Dobule,        // ..
		"...",  // 	Ellipsis_Triple,        // ...
		"=",    // 	Equal,                  // =
		"==",   // 	Equal_Double,           // ==
		"!",    // 	Exclamation,            // !
		"!=",   // 	Exclamation_Equal,      // !=
		">",    // 	Greater,                // >
		">>",   // 	Greater_Double,         // >>
		">>=",  // 	Greater_Double_Equal,   // >>=
		">=",   // 	Greater_Equal,          // >=
		"#",    // 	Hash,                   // #
		"<",    // 	Lesser,                 // <
		"<<",   // 	Lesser_Double,          // <<
		"<<=",  // 	Lesser_Double_Equal,    // <<=
		"<=",   // 	Lesser_Equal,           // <=
		"-",    // 	Minus,                  // -
		"--",   // 	Minus_Double,           // --
		"-=",   // 	Minus_Equal,            // -=
		"(",    // 	Parenthesis_Open,       // (
		")",    // 	Parenthesis_Close,      // )
		"%",    // 	Percent,                // %
		"%=",   // 	Percent_Equal,          // %=
		"%%",   // 	Percent_Double,         // %%
		"%%=",  // 	Percent_Dboule_Equal,   // %%=
		".",    // 	Period,                 // .
		"+",    // 	Plus,                   // +
		"++",   // 	Plus_Dobule,            // ++
		"+=",   // 	Plus_Equal,             // +=
		"?",    // 	Question,               // ?
		";",    // 	Semi_Colon,             // ;
		"/",    // 	Slash,                  // /
		"/=",   // 	Slash_Equal,            // /=
		"//",   // 	Slash_Double,           //
		"~",    // 	Tilde,                  // ~
		"~=",   // 	Tilde_Equal,            // ~=
		"|",    // 	Vert_Bar,               // |
		"||",   // 	Vert_Bar_Double,        // ||
		"|=",   // 	Vert_Bar_Equal,         // |=
		"//=",  // 	Vert_Bar_Double_Equal,  //=
	"____B_Operator_End____", // B_Operator_End,
}

PA_Token :: struct {
	type         : PA_TokenType,
	line, column : u32,
	ptr          : ^rune,
}

PA_LiteralType :: enum u32 {
	Integer,
	Decimal,
	Word,
}

PA_Literal :: struct {
	type  : PA_LiteralType,
	token : ^PA_Token,
}

PA_OperatorType :: enum u32 {

}

PA_Operator :: struct {
	type  : PA_OperatorType,
	token : ^PA_Token,
}

PA_BracketScopeType :: enum u32 {
	Angled,
	Curly,
	Square,
	Round,
}

PA_BracketScope :: struct {
	type  : PA_BracketScopeType,
	token : ^PA_Token,
	body  : ^PA_AST,
}

PA_AST :: union {

}

// Changes parse behavior for specific tokens.
PA_ParsePolicy :: struct {
	scope_detect_angled : b8,
	scope_detect_curly  : b8,
	scope_detect_square : b8,
	scope_detect_round  : b8,
}

PA_ParseError :: struct {
	token : ^ PA_Token,
	msg   : string,
}

PA_ParseError_Max :: 32
PA_NodeArray_ReserveSize :: 4 * Kilobyte

PA_ParseResult :: struct {
	content : string,
	runes   : []rune,
	tokens  : Array(PA_Token),
	pws_ast : ^PWS_AST,
	nodes   : Array(PA_AST), // Switch this to a pool?
	errors  : [PA_ParseError_Max] PA_ParseError
}

pa_parse_text :: proc( content : string, allocator : Allocator ) -> ( PA_ParseResult, AllocatorError )
{
	return {}, AllocatorError.None
}

pa_parse_ws_ast :: proc( ast : ^PWS_AST, allocator : Allocator ) -> ( PA_ParseResult, AllocatorError )
{
	return {}, AllocatorError.None
}
