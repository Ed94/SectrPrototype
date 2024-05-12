package sectr

// Provides an alternative syntax for pointers

Ptr :: struct( $ Type : typeid ) {
	v : Type,
}

exmaple_ptr :: proc()
{
	a, b :  int
	var  : ^Ptr(int)
	reg  : ^int

	a = 1
	b = 1

	var   = &{a}
	var.v = 2
	var   = &{b}
	var.v = 3

	a = 1
	b = 1

	reg    = (& a)
	(reg^) = 2
	reg    = (& b)
	(reg^) = 3
}
