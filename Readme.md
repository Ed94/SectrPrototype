# Sectr Prototype

This prototype aims to flesh out ideas I've wanted to explore futher on code editing & related tooling.

The things to explore:

* 2D canvas for laying out code visualized in various types of ASTs
* WYSIWYG frontend ASTs
* Making AST editing as versatile as text editing.
* High-performance UI framework designed & built for AST editing.
* Generating a large amount of UI widget boxes with proper auto-layout & no perceptible rendering-lag or input lag for interactions (frametimes stable).
* Model-View-Controller interface between code managed by a 'backend' (both in memory and filesystem) and the UX composition (which has separate filesystem composition).

https://github.com/user-attachments/assets/0a895478-4a04-4ac6-a0ac-5355ff87ef4e

The dependencies are:

* Odin Compiler (Slightly custom [fork](https://github.com/Ed94/Odin))
  * Added #region, #endregion directives support for editors
  * I added support for 'monlithic packages' or 'uniform-across-subdirectories packages'. It allows me to organize the main package with sub-directories.
  * Added the ability to debug using statements on structs (fields get dumped to the stack as ptr refs)
  * Remove implicit assignments for container allocators in the Base and Core packages
    * I did not enjoy bug hunting a memory corruption because I mistakenly didn't properly initialize a core container with their designated initiatizer: new, make, or init.
    * See fork Readme for which procedures were changed..
* Odin repo's base, core, and vendor(raylib) libaries
* An ini parser
* backtrace (not used yet)
* freetype (not used yet)
* harfbuzz
* sokol
* sokol-tools
* Powershell (if you want to use my build scripts)

The project is so far in a "codebase boostrapping" phase. Most the work being done right now is setting up high performance linear zoom rendering for text and UI.

The project's is organized into 2 runtime modules sectr_host & sectr.
The host module loads the main module & its memory. Hot-reloading it's dll when it detects a change.

Codebase organization:

* App: General app config, state, and operations.
* Engine: client interface for host, tick, update, rendering.
  * Has the following definitions: startup, shutdown, reload, tick, clean_frame (which host hooks up to when managing the client dll)
  * Will handle async ops.
* Font Provider: Manages fonts.
  * Bulk of visualization must be able to render text effectively
  * Bulk of implementation maintained as a separate library: [VEFontCache-Odin](https://github.com/Ed94/VEFontCache-Odin)
* Grime: Name speaks for itself, stuff not directly related to the target features to iterate upon for the prototype.
  * Defining dependency aliases or procedure overload tables, rolling own allocator, data structures, etc.
* Input: All human input related features
  * Base input features (polling & related) are platform abstracted from sokol_app
  * Entirely user rebindable
* Math: The usual for 2D/3D.
* Parsers:
  * AST generation, editing, and serialization.
  * Parsers for different levels of "synatitic & semantic awareness", Formatting -> Domain Specific AST
  * Figure out pragmatic transformations between ASTs.
* Project: Encpasulation of user config/context/state separate from persistent app's
  * Manages the codebase (database & model view controller)
  * Manages workspaces : View compositions of the codebase
* UI: Core graphic user interface framework, AST visualzation & editing, backend visualization
  * PIMGUI (Persistent Immediate Mode User Interface)
  * Auto-layout
  * Supports heavy procedural generation of box widgets
  * Viewports
  * Docking/Tiling, Floating, Canvas

Due to the nature of the prototype there are 'sub-groups' such as the codebase being its own ordeal as well as the workspace.
They'll be elaborated in their own documentation

## Gallery

![img](docs/assets/sectr_host_2024-03-09_04-30-27.png)
![img](docs/assets/sectr_host_2024-05-04_12-29-39.png)
![img](docs/assets/Code_2024-05-04_12-55-53.png)
![img](docs/assets/sectr_host_2024-05-11_22-34-15.png)
![img](docs/assets/sectr_host_2024-05-15_03-32-36.png)
![img](docs/assets/Code_2024-05-21_23-15-16.gif)
