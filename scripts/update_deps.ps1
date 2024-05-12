write-host 'Updating Dependencies..'

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root 'code'
$path_build      = join-path $path_root 'build'
$path_thirdparty = join-path $path_root 'thirdparty'
$path_toolchain  = join-path $path_root 'toolchain'

$url_backtrace_repo = 'https://github.com/Ed94/back.git'
$url_ini_parser     = 'https://github.com/laytan/odin-ini-parser.git'
$url_odin_repo      = 'https://github.com/Ed94/Odin.git'
$path_backtrace     = join-path $path_thirdparty 'backtrace'
$path_ini_parser    = join-path $path_thirdparty 'ini'
$path_odin          = join-path $path_toolchain  'Odin'

$incremental_checks = Join-Path $PSScriptRoot 'helpers/incremental_checks.ps1'
. $incremental_checks

if ( -not(Test-Path $path_thirdparty) ) {
	new-item -ItemType Directory -Path $path_thirdparty
}
if ( -not(Test-Path $path_toolchain) ) {
	new-item -ItemType Directory -Path $path_toolchain
}

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

		$path_scripts = join-path $path 'scripts'
		push-locaiton $path_scripts
		& .\build_and_run_gen_src_pass.ps1
		pop-location

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

	$path_scripts = join-path $path 'scripts'
	push-location $path_scripts
	& .\build_and_run_gen_src_pass.ps1
	pop-location

	write-host "Building $url"
	push-location $path
	& $build_command
	pop-location

	$latest_commit_hash | out-file $last_built_commit
	$script:binaries_dirty = $true
	write-host
}

push-location $path_thirdparty


Update-GitRepo -path $path_odin -url $url_odin_repo -build_command '.\build.bat'

if (Test-Path -Path $path_ini_parser)
{
	# Write-Host "Checking for updates on the ini-parser"
	git -C $path_ini_parser pull
}
else
{
	Write-Host "Cloning ini repository..."
	git clone $url_ini_parser $path_ini_parser
}

if (test-path $path_backtrace)
{
	git -C $path_backtrace pull
}
else
{
	Write-Host "Cloning backtrace repository..."
	git clone $url_backtrace_repo $path_backtrace
}

$path_vendor        = join-path $path_odin          'vendor'
$path_vendor_raylib = join-path $path_vendor        'raylib'
$path_raylib_dlls   = join-path $path_vendor_raylib 'windows'

if ( $binaries_dirty -or $true )
{
	$third_party_dlls = Get-ChildItem -Path $path_raylib_dlls -Filter '*.dll'
	foreach ($dll in $third_party_dlls) {
			$destination = join-path $path_build $dll.Name
			Copy-Item $dll.FullName -Destination $destination -Force
	}
}
pop-location
