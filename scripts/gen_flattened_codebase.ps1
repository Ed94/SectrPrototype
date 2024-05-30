cls
Write-Host "Reverse Build.ps1"

$ps_misc = join-path $PSScriptRoot 'helpers/misc.ps1'
. $ps_misc

$path_root           = git rev-parse --show-toplevel
$path_code           = Join-Path $path_root 'code'
$path_code_flattened = Join-Path $path_root 'code_flattened'

if (Test-Path $path_code_flattened) {
    Remove-Item -Path $path_code_flattened -Recurse -Force -ErrorAction Ignore
}
New-Item -ItemType Directory -Path $path_code_flattened

# $whitelist_package = 'sectr'

function get-flattened-package
{
		param(
		[string]$pkg_name,
		[string]$path_pkg_dir,
		[string]$path_flattend_dir
	)
	$files = Get-ChildItem -Path $path_pkg_dir -File -Recurse
	foreach ($file in $files)
	{
		if ($file.Name -eq '.ODIN_MONOLITHIC_PACKAGE') {
			continue
		}

		# Read the file line by line to determine the package name, ignoring comments
		$package_name = $null
		Get-Content -Path $file.FullName | ForEach-Object {
			if ($_ -notmatch '^\s*//')
			{
				if ($_ -match '^package\s+(\w+)$') {
					$package_name = $Matches[1]
					return $false
				}
			}
		}

		if ($pacakge_name -ne $pkg_name) {
			Write-Host "Warning: The file $($file.FullName) does not contain a valid package declaration."
		}

		# Calculate relative path and prepend directory names to the file name
		$relative_path = $file.FullName.Substring($path_pkg_dir.Length + 1)
		$relative_dir  = Split-Path $relative_path -Parent
		$relative_dir  = $relative_dir.Replace('\', '_').Replace('/', '_')

		if ($relative_dir -ne '') {
			$target_file_name = "$relative_dir" + "_" + $file.Name
		} else {
			$target_file_name = $file.Name
		}

		$target_file_path = Join-Path $path_flattend_dir $target_file_name

		if (-not (Test-Path $target_file_path))
		{ New-Item -ItemType SymbolicLink -Path $target_file_path -Value $file.FullName }
		else
		{ Write-Host "Warning: The link for $($file.FullName) already exists at $target_file_path. Skipping..." }
	}
}

$path_pkg_gen   = join-path $path_code 'gen'
$path_pkg_host  = join-path $path_code 'host'
$path_pkg_sectr = join-path $path_code 'sectr'

$path_flattend_gen   = join-path $path_code_flattened 'gen'
$path_flattend_host  = join-path $path_code_flattened 'host'
$path_flattend_sectr = join-path $path_code_flattened 'sectr'

verify-path $path_flattend_gen
verify-path $path_flattend_host
verify-path $path_flattend_sectr

get-flattened-package 'gen'   $path_pkg_gen   $path_flattend_gen
get-flattened-package 'host'  $path_pkg_host  $path_flattend_host
get-flattened-package 'sectr' $path_pkg_sectr $path_flattend_sectr

Write-Host "Flattened directory structure for packages created successfully."
