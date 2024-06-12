write-host 'Updating Dependencies..'

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root 'code'
$path_build      = join-path $path_root 'build'
$path_thirdparty = join-path $path_root 'thirdparty'
$path_toolchain  = join-path $path_root 'toolchain'

$url_backtrace_repo = 'https://github.com/Ed94/back.git'
$url_freetype       = 'https://github.com/Ed94/odin-freetype.git'
$url_harfbuzz       = 'https://github.com/Ed94/odin_harfbuzz.git'
$url_ini_parser     = 'https://github.com/laytan/odin-ini-parser.git'
$url_odin_repo      = 'https://github.com/Ed94/Odin.git'
$url_sokol          = 'https://github.com/Ed94/sokol-odin.git'
$url_sokol_tools    = 'https://github.com/floooh/sokol-tools-bin.git'

$path_backtrace     = join-path $path_thirdparty 'backtrace'
$path_freetype      = join-path $path_thirdparty 'freetype'
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

function Update-GitRepo
{
	param( [string] $path, [string] $url, [string] $build_command )

	if ( $build_command -eq $null ) {
		write-host "Attempted to call Update-GitRepo without build_command specified"
		return
	}

	$repo_name = $url.Split('/')[-1].Replace('.git', '')

	$last_built_commit = join-path $path_build "last_built_commit_$repo_name.txt"
	if ( -not(test-path -Path $path))
	{
		write-host "Cloining repo from $url to $path"
		git clone $url $path

		write-host "Building $url"
		push-location $path
		& "$build_command"
		pop-location

		git -C $path rev-parse HEAD | out-file $last_built_commit
		$script:binaries_dirty = $true
		write-host
		return
	}

	git -C $path fetch
	$latest_commit_hash = git -C $path rev-parse '@{u}'
	$last_built_hash    = if (Test-Path $last_built_commit) { Get-Content $last_built_commit } else { "" }

	if ( $latest_commit_hash -eq $last_built_hash ) {
		write-host
		return
	}

	write-host "Build out of date for: $path, updating"
	write-host 'Pulling...'
	git -C $path pull

	write-host "Building $url"
	push-location $path
	& $build_command
	pop-location

	$latest_commit_hash | out-file $last_built_commit
	$script:binaries_dirty = $true
	write-host
}

push-location $path_thirdparty

Update-GitRepo -path $path_odin     -url $url_odin_repo -build_command '.\scripts\build.ps1'
Update-GitRepo -path $path_sokol    -url $url_sokol     -build_command '.\build_windows.ps1'
Update-GitRepo -path $path_harfbuzz -url $url_harfbuzz  -build_command '.\scripts\build.ps1'

function clone-gitrepo { param( [string] $path, [string] $url )
	if (test-path $path) {
		# git -C $path pull
	}
	else {
		Write-Host "Cloning $url ..."
		git clone $url $path
	}
}

clone-gitrepo $path_backtrace   $url_backtrace_repo
clone-gitrepo $path_freetype    $url_freetype
clone-gitrepo $path_ini_parser  $url_ini_parser
clone-gitrepo $path_ini_parser  $url_ini_parser
clone-gitrepo $path_sokol_tools $url_sokol_tools

$path_vendor        = join-path $path_odin          'vendor'
$path_vendor_raylib = join-path $path_vendor        'raylib'
$path_freetype_dlls = join-path $path_freetype      'binaries/release'
$path_harfbuzz_dlls = join-path $path_harfbuzz      'lib/win64'
$path_raylib_dlls   = join-path $path_vendor_raylib 'windows'
$path_sokol_dlls    = join-path $path_thirdparty    'sokol'

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

	$third_party_dlls = Get-ChildItem -Path $path_raylib_dlls -Filter '*.dll'
	foreach ($dll in $third_party_dlls) {
			$destination = join-path $path_build $dll.Name
			Copy-Item $dll.FullName -Destination $destination -Force
	}
}
pop-location
