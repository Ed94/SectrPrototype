set-alias -Name 'build'      -Value '.\build.ps1'
set-alias -Name 'buildclean' -Value '.\clean.ps1'

$path_root       = git rev-parse --show-toplevel
$path_thirdparty = join-path $path_root 'thirdparty'
$path_odin       = join-path $path_thirdparty 'Odin'

$env:odin = $path_odin
