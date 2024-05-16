cls
Write-Host "Reverse Build.ps1"

$path_root                 = git rev-parse --show-toplevel
$path_code                 = Join-Path $path_root 'code'
$path_code_compiler_staged = Join-Path $path_root 'code_compiler_staged'

if (Test-Path $path_code_compiler_staged) {
    Remove-Item -Path $path_code_compiler_staged -Recurse -Force -ErrorAction Ignore
}
New-Item -ItemType Directory -Path $path_code_compiler_staged

$whitelist_package = 'sectr'

$files = Get-ChildItem -Path $path_code -File -Recurse
foreach ($file in $files)
{
    # Read the file line by line to determine the package name, ignoring comments
    $packageName = $null
    Get-Content -Path $file.FullName | ForEach-Object {
        if ($_ -notmatch '^\s*//')
		{
            if ($_ -match '^package\s+(\w+)$') {
                $packageName = $Matches[1]
                return $false
            }
        }
    }

    if ($packageName)
	{
        # Calculate relative path and prepend directory names to the file name
        $relativePath = $file.FullName.Substring($path_code.Length + 1)
        $relativeDir = Split-Path $relativePath -Parent
        $relativeDir = $relativeDir.Replace('\', '_').Replace('/', '_')

        if ($relativeDir -ne '') {
            $targetFileName = "$relativeDir" + "_" + $file.Name
        } else {
            $targetFileName = $file.Name
        }

        # Determine target directory based on the package name
        if ($packageName -eq $whitelist_package) {
            $targetDir = $path_code_compiler_staged
        } else {
            $targetDir = Join-Path $path_code_compiler_staged $packageName
            if (-not (Test-Path $targetDir)) {
                New-Item -ItemType Directory -Path $targetDir
            }
        }

        $targetFilePath = Join-Path $targetDir $targetFileName

        # Check if the target file path already exists and handle it accordingly
        if (-not (Test-Path $targetFilePath)) {
            New-Item -ItemType SymbolicLink -Path $targetFilePath -Value $file.FullName
        } else {
            Write-Host "Warning: The link for $($file.FullName) already exists at $targetFilePath. Skipping..."
        }
    }
	else {
        Write-Host "Warning: The file $($file.FullName) does not contain a valid package declaration."
    }
}

Write-Host "Compiler staged directory structure created successfully."
