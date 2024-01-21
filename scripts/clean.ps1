cls

$path_root  = git rev-parse --show-toplevel
$path_code  = join-path $path_root 'code'
$path_build = join-path $path_root 'build'

if ( test-path $path_build ) {
	Remove-Item $path_build -Verbose -Force -Recurse
}
