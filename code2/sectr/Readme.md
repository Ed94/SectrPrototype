# Sectr Package

This is the monolithic package representing the prototype itself. Relative to the host package this represents what define's the client module API, process memory, and thread memory.

Many definitions that are considered independent of the prototype have been lifted to the grime package, vefontcache, or in the future other packages within this codebase collection.

All allocators and containers within Sectr are derived from Grime.

The memory heurstics for sectr are categorized for now into:

* Persistent Static: Never released for process lifetime.
* Persistent Conservative: Can be wiped
* Frame
* File Mappings
* Codebase DB
