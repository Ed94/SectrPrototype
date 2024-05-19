function verify-path { param( $path )
	if (test-path $path) {return $true}

	new-item -ItemType Directory -Path $path
	return $false
}
