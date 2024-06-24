# VE Font Cache : Odin Port

This is a port of the library base on [fork](https://github.com/hypernewbie/VEFontCache)

TODO (Making it a more idiomatic library):

* Use Odin's builtin dynamic arrays
* Use Odin's builtin map type
* Setup freetype, harfbuzz, depedency management within the library

TODO Documentation:

* Pureref outline of draw_text exectuion
* Markdown general documentation

TODO Content:

* Port over the original demo utilizing sokol libraries instead
* Provide a sokol_gfx backend package

TODO Additional Features:

* Support for freetype
* Support for harfbuzz
* Ability to set a draw transform, viewport and projection
  * By default the library's position is in unsigned normalized render space

TODO Optimizations:

* Support more granular handling of shapes by chunking any text from draw_text into visible and whitespace/formatting
