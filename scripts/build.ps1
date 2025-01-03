cls
write-host "Build.ps1"

$incremental_checks = Join-Path $PSScriptRoot 'helpers/incremental_checks.ps1'
. $incremental_checks
write-host 'incremental_checks.ps1 imported'

$ini_parser = join-path $PSScriptRoot 'helpers/ini.ps1'
. $ini_parser
write-host 'ini.ps1 imported'

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root       'code'
$path_build      = join-path $path_root       'build'
$path_scripts    = join-path $path_root       'scripts'
$path_thirdparty = join-path $path_root       'thirdparty'
$path_toolchain  = join-path $path_root       'toolchain'
$path_odin       = join-path $path_toolchain  'odin'

#region Arguments
$force = $null

# This is to be used when Negate's TB backend is working on odin. We'll not want to use clang by default from then on.
$use_clang = $false

# This is a really lazy way of parsing the args, could use actual params down the line...

if ( $args ) { $args | ForEach-Object {
switch ($_){
 "force" { $force = $true }
 "clang" { $clang = $true }
}
}}
#endregion Arguments

if ( -not( test-path $path_build) ) {
	new-item -ItemType Directory -Path $path_build
}

$path_system_details = join-path $path_build 'system_details.ini'
if ( test-path $path_system_details ) {
    $iniContent = Get-IniContent $path_system_details
    $CoreCount_Physical = $iniContent["CPU"]["PhysicalCores"]
    $CoreCount_Logical  = $iniContent["CPU"]["LogicalCores"]
}
elseif ( $IsWindows ) {
	$CPU_Info = Get-CimInstance –ClassName Win32_Processor | Select-Object -Property NumberOfCores, NumberOfLogicalProcessors
	$CoreCount_Physical, $CoreCount_Logical = $CPU_Info.NumberOfCores, $CPU_Info.NumberOfLogicalProcessors

	new-item -path $path_system_details -ItemType File
    "[CPU]"                             | Out-File $path_system_details
    "PhysicalCores=$CoreCount_Physical" | Out-File $path_system_details -Append
    "LogicalCores=$CoreCount_Logical"   | Out-File $path_system_details -Append
}
write-host "Core Count - Physical: $CoreCount_Physical Logical: $CoreCount_Logical"

# Odin Compiler Flags

# For a beakdown of any flag, type <odin_compiler> <command> -help
$command_build  = 'build'
$command_check  = 'check'
$command_query  = 'query'
$command_report = 'report'
$command_run    = 'run'

$flag_build_mode                = '-build-mode:'
$flag_build_mode_dll            = '-build-mode:dll'
$flag_collection                = '-collection:'
$flag_debug                     = '-debug'
$flag_define                    = '-define:'
$flag_default_allocator_nil     = '-default-to-nil-allocator'
$flag_disable_assert            = '-disable-assert'
$flag_dynamic_map_calls         = '-dynamic-map-calls'
$flag_extra_assembler_flags     = '-extra_assembler-flags:'
$flag_extra_linker_flags        = '-extra-linker-flags:'
$flag_ignore_unknown_attributes = '-ignore-unknown-attributes'
$flag_keep_temp_files           = '-keep-temp-files'
$flag_max_error_count           = '-max-error-count:'
$flag_micro_architecture_native = '-microarch:native'
$flag_no_bounds_check           = '-no-bounds-check'
$flag_no_crt                    = '-no-crt'
$flag_no_entrypoint             = '-no-entry-point'
$flag_no_thread_local           = '-no-thread-local'
$flag_no_thread_checker         = '-no-threaded-checker'
$flag_output_path               = '-out='
$flag_optimization_level        = '-opt:'
$flag_optimize_none             = '-o:none'
$flag_optimize_minimal          = '-o:minimal'
$flag_optimize_size             = '-o:size'
$flag_optimize_speed            = '-o:speed'
$falg_optimize_aggressive       = '-o:aggressive'
$flag_pdb_name                  = '-pdb-name:'
$flag_sanitize_address          = '-sanitize:address'
$flag_sanitize_memory           = '-sanitize:memory'
$flag_sanitize_thread           = '-sanitize:thread'
$flag_subsystem                 = '-subsystem:'
$flag_show_timings              = '-show-timings'
$flag_show_more_timings         = '-show-more-timings'
$flag_show_system_calls         = '-show-system-calls'
$flag_target                    = '-target:'
$flag_thread_count              = '-thread-count:'
$flag_use_lld                   = '-lld'
$flag_use_separate_modules      = '-use-separate-modules'
$flag_vet_all                   = '-vet'
$flag_vet_unused_entities       = '-vet-unused'
$flag_vet_semicolon             = '-vet-semicolon'
$flag_vet_shadow_vars           = '-vet-shadowing'
$flag_vet_using_stmt            = '-vet-using-stmt'

$flag_msvc_link_disable_dynamic_base = '/DYNAMICBASE:NO'
$flag_msvc_link_base_address         = '/BASE:'
$flag_msvc_link_fixed_base_address   = '/FIXED'
$flag_msvc_link_stack_size           = '/STACK'
$flag_msvc_link_debug                = '/DEBUG'

$msvc_link_default_base_address = 0x180000000

push-location $path_root
	$update_deps   = join-path $path_scripts 'update_deps.ps1'
	$odin_compiler = join-path $path_odin    'odin.exe'

	function Invoke-WithColorCodedOutput { param( [scriptblock] $command )
		& $command 2>&1 | ForEach-Object {
			# Write-Host "Type: $($_.GetType().FullName)" # Add this line for debugging
			$color = 'White' # Default text color
			switch ($_) {
				{ $_ -imatch "error" } { $color = 'Red'; break }
				{ $_ -imatch "warning" } { $color = 'Yellow'; break }
			}
			Write-Host "`t$_" -ForegroundColor $color
		}
	}

	function build-prototype
	{
		push-location $path_code
		$project_name = 'sectr'

		write-host "`nBuilding Sectr Prototype`n"

		$path_font = join-path $path_code 'font'

		$package_grime       = join-path $path_code 'grime'
		$package_VEFontCache = join-path $path_font 'VEFontCache'
		$module_host         = join-path $path_code 'host'
		$module_sectr        = join-path $path_code 'sectr'
		if ($force){
			mark-ModuleDirty $package_VEFontCache
			mark-ModuleDirty $package_grime
			mark-ModuleDirty $module_sectr
			mark-ModuleDirty $module_host
		}

		$pkg_VEFontCache_dirty = check-ModuleForChanges $package_VEFontCache
		$pkg_grime_dirty       = check-ModuleForChanges $package_grime

		$pkg_collection_codebase   = 'codebase='   + $path_code
		$pkg_collection_thirdparty = 'thirdparty=' + $path_thirdparty

		$host_process_active = Get-Process | Where-Object {$_.Name -like 'sectr_host*'}
		if ( -not $host_process_active ) {
			# We cannot update thidparty dependencies during hot-reload.
			& $update_deps
			write-host
		}

		$module_build_failed = 0
		$module_built        = 1
		$module_unchanged    = 2

		function build-sectr
		{
			$should_build = (check-ModuleForChanges $module_sectr) -or $pkg_grime_dirty -or $pkg_VEFontCache_dirty
			if ( -not( $should_build)) {
				write-host 'Skipping sectr build, module up to date'
				return $module_unchanged
			}

			write-host 'Building Sectr Module'
			$module_dll = join-path $path_build ( $project_name + '.dll' )
			$pdb        = join-path $path_build ( $project_name + '.pdb' )

			if (test-path $pdb) {
				remove-item $pdb
			}

			$linker_args = ""
			# $linker_args += ( $flag_msvc_link_debug + ' ' )
			$linker_args += ( $flag_msvc_link_disable_dynamic_base + ' ' )
			$linker_args += ( $flag_msvc_link_fixed_base_address   + ' ' )
			$linker_args += ( $flag_msvc_link_base_address + '0x20000000000' )
			# $linker_args += ( $flag_msvc_link_base_address + '0x200000000' )

			$build_args = @()
			$build_args += $command_build
			$build_args += './sectr'
			$build_args += $flag_build_mode_dll
			$build_args += $flag_output_path + $module_dll
			$build_args += ($flag_collection + $pkg_collection_codebase)
			$build_args += ($flag_collection + $pkg_collection_thirdparty)
			# $build_args += $flag_micro_architecture_native
			$build_args += $flag_use_separate_modules
			$build_args += $flag_thread_count + $CoreCount_Physical
			# $build_args += $flag_optimize_none
			# $build_args += $flag_optimize_minimal
			# $build_args += $flag_optimize_speed
			$build_args += $falg_optimize_aggressive
			$build_args += $flag_debug
			$build_args += $flag_pdb_name + $pdb
			$build_args += $flag_subsystem + 'windows'
			# $build_args += $flag_show_system_calls
			$build_args += $flag_show_timings
			$build_args += ($flag_extra_linker_flags + $linker_args )
			# $build_args += $flag_no_thread_checker
			# $build_args += $flag_dynamic_map_calls
			# $build_args += $flag_default_allocator_nil
			$build_args += ($flag_max_error_count + '10')
			# $build_args += $flag_sanitize_address
			# $build_args += $flag_sanitize_memory

			if ( Test-Path $module_dll) {
				$module_dll_pre_build_hash = get-filehash -path $module_dll -Algorithm MD5
			}

			Invoke-WithColorCodedOutput -command { & $odin_compiler $build_args }

			if ( Test-Path $module_dll ) {
				$module_dll_post_build_hash = get-filehash -path $module_dll -Algorithm MD5
			}

			$built = ($module_dll_pre_build_hash -eq $null) -or ($module_dll_pre_build_hash.Hash -ne $module_dll_post_build_hash.Hash)
			if ( -not $built ) {
				write-host 'Failed to build, marking module dirty'
				mark-ModuleDirty $module_sectr
			}
			return $built
		}
		$script:sectr_build_code = build-sectr

		function build-host
		{
			$executable   = join-path $path_build ($project_name + '_host.exe')
			$pdb          = join-path $path_build ($project_name + '_host.pdb')

			if ( $host_process_active ) {
				write-host 'Skipping sectr_host build, process is active'
				return
			}

			$dependencies_built = $script:sectr_build_code -ne $module_build_failed
			if ( -not $dependencies_built ) {
				write-host 'Skipping sectr_host build, dependencies failed to build'
				return
			}

			$should_build = (check-ModuleForChanges $module_host) -or ( $script:sectr_build_code -eq $module_built )
			if ( -not( $should_build)) {
				write-host 'Skipping sectr_host build, module up to date'
				return
			}

			if (test-path $pdb) {
				remove-item $pdb
			}

			write-host 'Building Host Module'
			$linker_args = ""
			# $linker_args += ( $flag_msvc_link_disable_dynamic_base + ' ' )
			# $linker_args += ( $flag_msvc_link_stack_size + ' ')

			$build_args = @()
			$build_args += $command_build
			$build_args += './host'
			$build_args += $flag_output_path + $executable
			$build_args += ($flag_collection + $pkg_collection_codebase)
			$build_args += ($flag_collection + $pkg_collection_thirdparty)
			# $build_args += $flag_micro_architecture_native
			$build_args += $flag_use_separate_modules
			$build_args += $flag_thread_count + $CoreCount_Physical
			# $build_args += $flag_optimize_none
			$build_args += $flag_optimize_minimal
			# $build_args += $flag_optimize_speed
			# $build_args += $falg_optimize_aggressive
			$build_args += $flag_debug
			$build_args += $flag_pdb_name + $pdb
			$build_args += $flag_subsystem + 'windows'
			# $build_args += ($flag_extra_linker_flags + $linker_args )
			$build_args += $flag_show_timings
			# $build_args += $flag_show_system_call
			# $build_args += $flag_no_bounds_check
			# $build_args += $flag_no_thread_checker
			# $build_args += $flag_default_allocator_nil
			$build_args += ($flag_max_error_count + '10')
			# $build_args += $flag_sanitize_address
			# $build_args += $flag_sanitize_memory

			if ( Test-Path $executable) {
				$executable_pre_build_hash = get-filehash -path $executable -Algorithm MD5
			}

			Invoke-WithColorCodedOutput { & $odin_compiler $build_args }

			if ( Test-Path $executable ) {
				$executable_post_build_hash = get-filehash -path $executable -Algorithm MD5
			}

			$built = ($executable_pre_build_hash -eq $null) -or ($executable_pre_build_hash.Hash -ne $executable_post_build_hash.Hash)
			if ( -not $built ) {
				write-host 'Failed to build, marking module dirty'
				mark-ModuleDirty $module_host
			}
		}
		build-host

		Pop-Location # path_code
	}
	build-prototype
pop-location # path_root

exit 0
