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

$shadersrc_learngl_font_glyph = join-path $path_shaders 'learngl_font_glyph_sokol.glsl'
$shaderout_learngl_font_glyph = join-path $path_shaders 'learngl_font_glyph_sokol.odin'

$flag_input       = '--input '
$flag_output      = '--output '
$flag_target_lang = '--slang '
$flag_format_odin = '--format=sokol_odin'

$cmd_args = @()
$cmd_args += $flag_input  + $shadersrc_learngl_font_glyph
$cmd_args += $flag_output + $shaderout_learngl_font_glyph
$cmd_args += $flag_target_lang + 'hlsl5'

& $sokol_shdc --input $shadersrc_learngl_font_glyph --output $shaderout_learngl_font_glyph --slang 'hlsl5' $flag_format_odin
