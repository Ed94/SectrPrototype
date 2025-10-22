write-host 'Updating Dependencies..'

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root 'code'
$path_build      = join-path $path_root 'build'
$path_thirdparty = join-path $path_root 'thirdparty'
$path_toolchain  = join-path $path_root 'toolchain'

$url_harfbuzz       = 'https://github.com/Ed94/harfbuzz-odin.git'
$url_ini_parser     = 'https://github.com/laytan/odin-ini-parser.git'
$url_odin_repo      = 'https://github.com/Ed94/Odin.git'
$url_sokol          = 'https://github.com/Ed94/sokol-odin.git'
$url_sokol_tools    = 'https://github.com/floooh/sokol-tools-bin.git'

# TODO(Ed): https://github.com/karl-zylinski/odin-handle-map

$path_harfbuzz      = join-path $path_thirdparty 'harfbuzz'
$path_ini_parser    = join-path $path_thirdparty 'ini'
$path_odin          = join-path $path_toolchain  'Odin'
$path_sokol         = join-path $path_thirdparty 'sokol'
$path_sokol_tools   = join-path $path_thirdparty 'sokol-tools'

$incremental_checks = Join-Path $PSScriptRoot 'helpers/incremental_checks.ps1'
. $incremental_checks

$misc = join-path $PSScriptRoot 'helpers/misc.ps1'
. $misc

$result = verify-path $path_build
$result = verify-path $path_thirdparty
$result = verify-path $path_toolchain

$binaries_dirty = $false

clone-gitrepo $path_ini_parser  $url_ini_parser
clone-gitrepo $path_ini_parser  $url_ini_parser
clone-gitrepo $path_sokol_tools $url_sokol_tools

Update-GitRepo -path $path_odin     -url $url_odin_repo -build_command '.\scripts\build.ps1'
Update-GitRepo -path $path_sokol    -url $url_sokol     -build_command '.\build_windows.ps1'
Update-GitRepo -path $path_harfbuzz -url $url_harfbuzz  -build_command '.\scripts\build.ps1'

$path_vendor        = join-path $path_odin          'vendor'
$path_vendor_raylib = join-path $path_vendor        'raylib'
$path_harfbuzz_dlls = join-path $path_harfbuzz      'lib/win64'
$path_raylib_dlls   = join-path $path_vendor_raylib 'windows'
$path_sokol_dlls    = join-path $path_thirdparty    'sokol'

push-location $path_thirdparty

if ( $binaries_dirty -or $true )
{
	$third_party_dlls = Get-ChildItem -path $path_harfbuzz_dlls -Filter '*.dll'
	foreach ($dll in $third_party_dlls) {
		$destination = join-path $path_build $dll.Name
		Copy-Item $dll.FullName -Destination $destination -Force
	}

	$third_party_dlls = Get-ChildItem -Path $path_sokol_dlls -Filter '*.dll'
	foreach ($dll in $third_party_dlls) {
		$destination = join-path $path_build $dll.Name
		Copy-Item $dll.FullName -Destination $destination -Force
	}
}
pop-location

$path_helpers  = join-path $PSScriptRoot 'helpers'
$path_devshell = join-path $path_helpers 'devshell.ps1'

. $path_devshell -arch amd64

$path_stb     = join-path $path_thirdparty 'stb'
$path_stb_src = join-path $path_stb        'src'

$pkg_stb_truetype_dirty = check-ModuleForChanges $path_stb

if ( $pkg_stb_truetype_dirty)
{
	push-location $path_stb_src

	& '.\build.bat'

	pop-location
}
