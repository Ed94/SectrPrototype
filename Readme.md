# Sectr Prototype

This prototype aims to flesh out ideas I've wanted to explore futher on code editing & related tooling.

Current goal with the prototype is just making a good visualizer & note aggregation for codebases & libraries.
My note repos with affine links give an idea of what that would look like.

The things to explore (future):

* 2D canvas for laying out code visualized in various types of ASTs
* WYSIWYG frontend ASTs
* Making AST editing as versatile as text editing.
* High-performance UI framework designed & built for AST editing.
* Generating a large amount of UI widget boxes with proper auto-layout & no perceptible rendering-lag or input lag for interactions (frametimes stable).
* Model-View-Controller interface between code managed by a 'backend' (both in memory and filesystem) and the UX composition (which has separate filesystem composition).

https://github.com/user-attachments/assets/0a895478-4a04-4ac6-a0ac-5355ff87ef4e

The dependencies are:

* Odin Compiler (Slightly custom [fork](https://github.com/Ed94/Odin))
  * I added support for 'monlithic packages' or 'uniform-across-subdirectories packages'. It allows me to organize the main package with sub-directories.
  * Added the ability to debug using statements on structs (fields get dumped to the stack as ptr refs)
  * Remove implicit assignments for container allocators in the Base and Core packages
    * I did not enjoy bug hunting a memory corruption because I mistakenly didn't properly initialize a core container with their designated initiatizer: new, make, or init.
    * See fork Readme for which procedures were changed..
* Odin repo's base, core, and some of vendor
* [VEFontCache-Odin](https://github.com/Ed94/VEFontCache-Odin): Text rendering & shaping library created for this prototype
* [stb_truetype-odin](https://github.com/Ed94/stb_truetype-odin): Variant of the stb/truetype package in odin's vendor collection made for VEFontCache-Odin
* [harfbuzz-odin](https://github.com/Ed94/harfbuzz-odin): Custom repo with tailor made bindings for VEFontCache-Odin
* [sokol-odin (Sectr Fork)](https://github.com/Ed94/sokol-odin)
* [sokol-tools](https://github.com/floooh/sokol-tools)
* Powershell (if you want to use my build scripts)
* Eventually some config parser (maybe I'll use metadesk, or [ini](https://github.com/laytan/odin-ini-parser))

The project is so far in a "codebase boostrapping" phase. Most the work being done right now is setting up high performance linear zoom rendering for text and UI.
Text has recently hit sufficient peformance targets, and now inital UX has become the focus.

## Gallery

![img](docs/assets/sectr_host_2024-05-11_22-34-15.png)

## Notes

Due to bug with custom ols click file in root of sectr to get full symbol reflection setup on the monolithic package.

For support for regions - grab a region extension and use the following regex:

VS-Code Explicit Folding:

```json
    "explicitFolding.rules": {
        "odin": [
            {
                "beginRegex": "region\\b",
                "endRegex": "endregion\\b"
            },
            {
                "beginRegex": "{",
                "endRegex": "}"
            },
            {
                "beginRegex": "\\[",
                "endRegex": "\\]"
            },
            {
                "beginRegex": "\\(",
                "endRegex": "\\)"
            },
            {
                "beginRegex": "\"",
                "endRegex": "\""
            },
            {
                "beginRegex": "/\\*",
                "endRegex": "\\*/"
            }
        ]
    },
```
