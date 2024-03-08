# Sectr Prototype

This prototype aims to flesh out ideas I've wanted to explore futher when it came to code editing and tools for code in general.

The project is so far in a "codebase boostrapping" phase.

The code is organized into 2 modules sectr_host & sectr.
The host module loads the main module & its memory. Hot-reloading it's dll when it detects a change.

The main module only depends on libraries provided by odin repo's base, core, or vendor related packages, and a ini-parsing library.


