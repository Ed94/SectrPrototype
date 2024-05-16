# Generates a more ergonomic filesystem organization for nagivating the codebase on windows using symbolic links

cls
write-host "Build.ps1"

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root       'code'
$path_scripts    = join-path $path_root       'scripts'

$path_virtual_view = join-path $path_root 'code_virtual_view'

if (test-path $path_virtual_view) {
	Remove-Item -Path $path_virtual_view -Recurse -Force -ErrorAction Ignore
}
New-Item -ItemType Directory -Path $path_virtual_view

$files = Get-ChildItem -Path $path_code -File -Recurse
foreach ($file in $files)
{
    # Determine if the file name contains a namespace
    $fileName = $file.Name
    if ($fileName -match '^(.+?)_(.+)\.odin$')
	{
        # Extract namespace and actual file name
        $namespace = $Matches[1]
        $actualFileName = $Matches[2] + ".odin"

        # Create a namespace directory in the virtual view if it doesn't exist
        $namespaceDir = Join-Path $path_virtual_view $namespace
        if (-not (Test-Path $namespaceDir)) {
            New-Item -ItemType Directory -Path $namespaceDir
        }

        # Create a symbolic link in the namespace directory pointing to the original file
        $targetFilePath = $file.FullName
        $linkPath = Join-Path $namespaceDir $actualFileName
        New-Item -ItemType SymbolicLink -Path $linkPath -Value $targetFilePath
    }
	else
	{
		# For files without a namespace, maintain the directory structure in the virtual view
		$relativePath = $file.FullName.Substring($path_code.Length + 1)
		$linkPath     = Join-Path $path_virtual_view $relativePath
		$linkDir      = Split-Path -Parent $linkPath

		if (-not (Test-Path $linkDir)) {
			New-Item -ItemType Directory -Path $linkDir -Force
		}
		New-Item -ItemType SymbolicLink -Path $linkPath -Value $file.FullName
	}
}

Write-Host "Virtual view created successfully."
