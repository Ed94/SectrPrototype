$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root       'code'
$path_build      = join-path $path_root       'build'
$path_scripts    = join-path $path_root       'scripts'
$path_thirdparty = join-path $path_root       'thirdparty'
$path_toolchain  = join-path $path_root       'toolchain'
$path_odin       = join-path $path_toolchain  'odin'

$path_sokol_tools = join-path $path_thirdparty 'sokol-tools'

$path_sectr   = join-path $path_code  'sectr'
$path_shaders = join-path $path_sectr 'shaders'

$sokol_shdc  = join-path $path_sokol_tools 'bin/win32/sokol-shdc.exe'

$shadersrc_simple_font_glyph = join-path $path_shaders 'simple_font_glyph.shdc.glsl'
$shaderout_simple_font_glyph = join-path $path_shaders 'simple_font_glyph.odin'

$shadersrc_ve_blit_atlas     = join-path $path_shaders 've_blit_atlas.shdc.glsl'
$shaderout_ve_blit_atlas     = join-path $path_shaders 've_blit_atlas.odin'

$shadersrc_ve_draw_text      = join-path $path_shaders 've_draw_text.shdc.glsl'
$shaderout_ve_draw_text      = join-path $path_shaders 've_draw_text.odin'

$shadersrc_ve_render_glyph   = join-path $path_shaders 've_render_glyph.shdc.glsl'
$shaderout_ve_render_glyph   = join-path $path_shaders 've_render_glyph.odin'

$flag_input       = '--input '
$flag_output      = '--output '
$flag_target_lang = '--slang '
$flag_format_odin = '--format=sokol_odin'
$flag_module      = '--module'

push-location $path_shaders
& $sokol_shdc --input $shadersrc_simple_font_glyph --output $shaderout_simple_font_glyph --slang 'hlsl5' $flag_format_odin
& $sokol_shdc --input $shadersrc_ve_blit_atlas     --output $shaderout_ve_blit_atlas     --slang 'hlsl5' $flag_format_odin $flag_module='vefc_blit_atlas'
& $sokol_shdc --input $shadersrc_ve_render_glyph   --output $shaderout_ve_render_glyph   --slang 'hlsl5' $flag_format_odin $flag_module='vefc_render_glyph'
& $sokol_shdc --input $shadersrc_ve_draw_text      --output $shaderout_ve_draw_text      --slang 'hlsl5' $flag_format_odin $flag_module='vefc_draw_text'
pop-location
