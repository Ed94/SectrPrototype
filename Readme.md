# Sectr Prototype

This prototype aims to flesh out ideas I've wanted to explore futher when it came to code editing and tools for code in general.

The things to explore:

* 2D canvas for laying out code visualized in various types of ASTs
* WYSIWYG frontend ASTs
* Making AST editing as versatile as text editing.
* High-performance generating a large amount of UI widget boxes with proper auto-layout & no perceptible rendering-lag or input lag for interactions (frametimes stable).
* Model-View-Controller interface between code managed by a 'backend' (both in memory and filesystem) and the UX composition (which has separate filesystem composition).

The project is so far in a "codebase boostrapping" phase.

The project's is organized into 2 modules sectr_host & sectr.
The host module loads the main module & its memory. Hot-reloading it's dll when it detects a change.

The dependencies are:

* Odin Compiler
* Odin repo's base, core, and vendor(raylib) libaries
* An ini parser

The client(sectr) module's organization is relatively flat due to the nature of odin's module suste, not allowing for cyclic dependencies across modules, and modules can only be in one directory.
This makes it difficult to unflatten, not something organic todo in a prototype...

Even so the notatble groups are:

* API : Provides the overarching interface of the app's general behavior. Host uses this to provide the client its necessary data and exection env.
  * Has the following definitions: startup, shutdown, reload, tick, clean_frame
* Grime : Name speaks for itself, stuff not directly related to the target features to iterate upon for the prototype.
  * Defining dependency aliases or procedure overload tables, rolling own allocator, data structures, etc.
* Font Provider : Manages fonts.
  * When loading fonts, the provider currently uses raylib to generate bitmap glyth sheets for a range of font sizes at once.
  * Goal is to eventually render using SDF shaders.
* Input : Standard input pooling and related features. Platform abstracted via raylib for now.
* Parser : AST generation, editing, and serialization. A 1/3 of this prototype will most likely be this alone.
* UI : AST visualzation & editing, backend visualization, project organizationa via workspaces (2d cavnases)
  * Will most likely be the bulk of this prototype.
  * PIMGUI (Persistent Immediate Mode User Interface)
  * Auto-layout with heavy procedural generation of box widgets

There is some unused code in `code/__imgui_raddbg`. Its a partial translation of some data structures from raddbg's ui.

## Gallery

![img](docs/assets/sectr_host_2024-03-09_04-30-27.png)
![img](docs/assets/sectr_host_2024-05-04_12-29-39.png)
![img](docs/assets/Code_2024-05-04_12-55-53.png)
