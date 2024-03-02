# This is meant to be used with build.ps1, and is not a standalone script.

function Get-IniContent { param([ string]$filePath )
    $ini            = @{}
    $currentSection = $null
    switch -regex -file $filePath
	{
        "^\[(.+)\]$" {
            $currentSection       = $matches[1].Trim()
            $ini[$currentSection] = @{}
        }
        "^(.+?)\s*=\s*(.*)" {
            $key, $value = $matches[1].Trim(), $matches[2].Trim()
            if ($null -ne $currentSection) {
                $ini[$currentSection][$key] = $value
            }
        }
    }
    return $ini
}
