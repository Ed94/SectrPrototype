package sectr

/*
Project: Encapsulation of all things a user can do separate from the core app behavior
that is managed independetly of it.
*/

// PMDB
CodeBase :: struct {
	placeholder : int,
}

ProjectConfig :: struct {
	placeholder : int,
}

Project :: struct {
	path : StrCached,
	name : StrCached,

	config   : ProjectConfig,
	codebase : CodeBase,

	// TODO(Ed) : Support multiple workspaces
	workspace : Workspace,
}
