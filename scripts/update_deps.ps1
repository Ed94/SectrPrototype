write-host 'Updating Dependencies..'

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root 'code'
$path_build      = join-path $path_root 'build'
$path_thirdparty = join-path $path_root 'thirdparty'

$url_odin_repo = 'https://github.com/Ed94/Odin.git'
$path_odin     = join-path $path_thirdparty 'Odin'

$incremental_checks = Join-Path $PSScriptRoot 'helpers/incremental_checks.ps1'
. $incremental_checks

if ( -not(Test-Path $path_thirdparty) ) {
	new-item -ItemType Directory -Path $path_thirdparty
}

push-location $path_thirdparty

if (Test-Path -Path $path_odin)
{
	Write-Host "Checking for updates in the Odin repository..."
	git -C $path_odin fetch

	# Get the latest local and remote commit hashes for the current branch
	$localCommit  = git -C $path_odin rev-parse HEAD
	$remoteCommit = git -C $path_odin rev-parse '@{u}'

	# Compare local and remote commits
	if ($localCommit -ne $remoteCommit) 
	{
			Write-Host "Odin repository is out-of-date. Pulling changes and rebuilding..."
			git -C $path_odin pull
			push-location $path_odin
			& .\build.bat
			pop-location

			$binaries_dirty = true
	}
	else
	{
			Write-Host "Odin repository is up-to-date. No need to rebuild."
	}
}
else
{
	# Odin directory does not exist, so clone the repository
	Write-Host "Cloning Odin repository..."
	git clone $url_odin_repo $path_odin
	push-location $path_odin
	& .\build.bat
	pop-location

	$binaries_dirty = true
}

$path_vendor        = join-path $path_odin          'vendor'
$path_vendor_raylib = join-path $path_vendor        'raylib'
$path_raylib_dlls   = join-path $path_vendor_raylib 'windows'

if ( $binaries_dirty )
{
	$third_party_dlls = Get-ChildItem -Path $path_raylib_dlls -Filter '*.dll'
	foreach ($dll in $third_party_dlls) {
			$destination = join-path $path_build $dll.Name
			Copy-Item $dll.FullName -Destination $destination -Force
	}
}
pop-location
