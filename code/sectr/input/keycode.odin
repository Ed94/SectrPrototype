package sectr

MaxKeyboardKeys :: 512

KeyCode :: enum u32 {
	null         = 0x00,

	ignored      = 0x01,
	menu         = 0x02,
	world_1      = 0x03,
	world_2      = 0x04,

	// 0x05
	// 0x06
	// 0x07

	backspace     = '\b', // 0x08
	tab           = '\t', // 0x09

	right         = 0x0A,
	left          = 0x0B,
	down          = 0x0C,
	up            = 0x0D,

	enter         = '\r', // 0x0E

	// 0x0F

	caps_lock     = 0x10,
	scroll_lock   = 0x11,
	num_lock      = 0x12,

	left_alt      = 0x13,
	left_shift    = 0x14,
	left_control  = 0x15,
	right_alt     = 0x16,
	right_shift   = 0x17,
	right_control = 0x18,

	print_screen  = 0x19,
	pause         = 0x1A,
	escape        = '\x1B', // 0x1B
	home          = 0x1C,
	end           = 0x1D,
	page_up       = 0x1E,
	page_down     = 0x1F,
	space         = ' ', // 0x20

	exclamation   = '!', // 0x21
	quote_dbl     = '"', // 0x22
	hash          = '#', // 0x23
	dollar        = '$', // 0x24
	percent       = '%', // 0x25
	ampersand     = '&', // 0x26
	quote         = '\'', // 0x27
	paren_open    = '(', // 0x28
	paren_close   = ')', // 0x29
	asterisk      = '*', // 0x2A
	plus          = '+', // 0x2B
	comma         = ',', // 0x2C
	minus         = '-', // 0x2D
	period        = '.', // 0x2E
	slash         = '/', // 0x2F

	nrow_0        = '0', // 0x30
	nrow_1        = '1', // 0x31
	nrow_2        = '2', // 0x32
	nrow_3        = '3', // 0x33
	nrow_4        = '4', // 0x34
	nrow_5        = '5', // 0x35
	nrow_6        = '6', // 0x36
	nrow_7        = '7', // 0x37
	nrow_8        = '8', // 0x38
	nrow_9        = '9', // 0x39

	// 0x3A

	semicolon     = ';', // 0x3B
	less          = '<', // 0x3C
	equals        = '=', // 0x3D
	greater       = '>', // 0x3E
	question      = '?', // 0x3F
	at            = '@', // 0x40

	A             = 'A', // 0x41
	B             = 'B', // 0x42
	C             = 'C', // 0x43
	D             = 'D', // 0x44
	E             = 'E', // 0x45
	F             = 'F', // 0x46
	G             = 'G', // 0x47
	H             = 'H', // 0x48
	I             = 'I', // 0x49
	J             = 'J', // 0x4A
	K             = 'K', // 0x4B
	L             = 'L', // 0x4C
	M             = 'M', // 0x4D
	N             = 'N', // 0x4E
	O             = 'O', // 0x4F
	P             = 'P', // 0x50
	Q             = 'Q', // 0x51
	R             = 'R', // 0x52
	S             = 'S', // 0x53
	T             = 'T', // 0x54
	U             = 'U', // 0x55
	V             = 'V', // 0x56
	W             = 'W', // 0x57
	X             = 'X', // 0x58
	Y             = 'Y', // 0x59
	Z             = 'Z', // 0x5A

	bracket_open  = '[',  // 0x5B
	backslash     = '\\', // 0x5C
	bracket_close = ']',  // 0x5D
	caret         = '^',  // 0x5E
	underscore    = '_',  // 0x5F
	backtick      = '`',  // 0x60

	kpad_0        = 0x61,
	kpad_1        = 0x62,
	kpad_2        = 0x63,
	kpad_3        = 0x64,
	kpad_4        = 0x65,
	kpad_5        = 0x66,
	kpad_6        = 0x67,
	kpad_7        = 0x68,
	kpad_8        = 0x69,
	kpad_9        = 0x6A,
	kpad_decimal  = 0x6B,
	kpad_equals   = 0x6C,
	kpad_plus     = 0x6D,
	kpad_minus    = 0x6E,
	kpad_multiply = 0x6F,
	kpad_divide   = 0x70,
	kpad_enter    = 0x71,

	F1            = 0x72,
	F2            = 0x73,
	F3            = 0x74,
	F4            = 0x75,
	F5            = 0x76,
	F6            = 0x77,
	F7            = 0x78,
	F8            = 0x79,
	F9            = 0x7A,
	F10           = 0x7B,
	F11           = 0x7C,
	F12           = 0x7D,

	insert        = 0x7E,
	delete        = 0x7F,

	F13 = 0x80,
	F14 = 0x81,
	F15 = 0x82,
	F16 = 0x83,
	F17 = 0x84,
	F18 = 0x85,
	F19 = 0x86,
	F20 = 0x87,
	F21 = 0x88,
	F22 = 0x89,
	F23 = 0x8A,
	F24 = 0x8B,
	F25 = 0x8C,

	count = 0x8D,
}
