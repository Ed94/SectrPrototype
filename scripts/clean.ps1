cls

$path_root                 = git rev-parse --show-toplevel
$path_code                 = join-path $path_root 'code'
$path_code_compiler_staged = Join-Path $path_root 'code_compiler_staged'
$path_build                = join-path $path_root 'build'

if ( test-path $path_build )               { Remove-Item $path_build -Verbose -Force -Recurse }
if ( test-path $path_code_compiler_staged) { Remove-Item $path_code_compiler_staged -Verbose -Force -Recurse }
