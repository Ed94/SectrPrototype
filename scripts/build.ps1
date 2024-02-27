cls

$incremental_checks = Join-Path $PSScriptRoot 'helpers/incremental_checks.ps1'
. $incremental_checks

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root       'code'
$path_build      = join-path $path_root       'build'
$path_scripts    = join-path $path_root       'scripts'
$path_thirdparty = join-path $path_root       'thirdparty'
$path_odin       = join-path $path_thirdparty 'odin'

if ( $IsWindows ) {
	$CPU_Info = Get-CimInstance –ClassName Win32_Processor | Select-Object -Property NumberOfCores, NumberOfLogicalProcessors
	$CoreCount_Physical, $CoreCount_Logical = $CPU_Info.NumberOfCores, $CPU_Info.NumberOfLogicalProcessors
}

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
$flag_disable_assert            = '-disable-assert'
$flag_extra_assembler_flags     = '-extra_assembler-flags:'
$flag_extra_linker_flags        = '-extra-linker-flags:'
$flag_ignore_unknown_attributes = '-ignore-unknown-attributes'
$flag_keep_temp_files           = '-keep-temp-files'
$flag_no_bounds_check           = '-no-bounds-check'
$flag_no_crt                    = '-no-crt'
$flag_no_entrypoint             = '-no-entry-point'
$flag_no_thread_local           = '-no-thread-local'
$flag_no_thread_checker         = '-no-thread-checker'
$flag_output_path               = '-out='
$flag_optimization_level        = '-opt:'
$flag_optimize_none             = '-o:none'
$flag_optimize_minimal          = '-o:minimal'
$flag_optimize_size             = '-o:size'
$flag_optimize_speed            = '-o:speed'
$falg_optimize_aggressive       = '-o:aggressive'
$flag_pdb_name                  = '-pdb-name:'
$flag_sanitize                  = '-sanitize:'
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

$msvc_link_default_base_address = 0x180000000

push-location $path_root
	$update_deps   = join-path $path_scripts 'update_deps.ps1'
	$odin_compiler = join-path $path_odin    'odin.exe'
	if ( -not( test-path 'build') ) {
		new-item -ItemType Directory -Path 'build'
	}

	function build-prototype
	{
		push-location $path_code
		$project_name = 'sectr'

		write-host "`nBuilding Sectr Prototype`n"

		$module_host  = join-path $path_code 'host'
		$module_sectr = $path_code

		$pkg_collection_thirdparty = 'thirdparty=' + $path_thirdparty

		$host_process_active = Get-Process | Where-Object {$_.Name -like 'sectr_host*'}
		if ( -not $host_process_active ) {
			# We cannot update thidparty dependencies during hot-reload.
			& $update_deps
			write-host
		}

		function build-sectr
		{
			$should_build = check-ModuleForChanges $module_sectr
			if ( -not( $should_build)) {
				write-host 'Skipping sectr build, module up to date'
				return $false
			}

			write-host 'Building Sectr Module'
			$module_dll = join-path $path_build ( $project_name + '.dll' )
			$pdb        = join-path $path_build ( $project_name + '.pdb' )

			$linker_args = ""
			$linker_args += ( $flag_msvc_link_disable_dynamic_base + ' ' )
			$linker_args += ( $flag_msvc_link_fixed_base_address   + ' ' )
			$linker_args += ( $flag_msvc_link_base_address + '0x20000000000' )
			# $linker_args += ( $flag_msvc_link_base_address + '0x200000000' )

			$build_args = @()
			$build_args += $command_build
			$build_args += '.'
			$build_args += $flag_build_mode_dll
			$build_args += $flag_output_path + $module_dll
			$build_args += ($flag_collection + $pkg_collection_thirdparty)
			$build_args += $flag_use_separate_modules
			$build_args += $flag_optimize_none
			$build_args += $flag_debug
			$build_args += $flag_pdb_name + $pdb
			$build_args += ($flag_extra_linker_flags + $linker_args )
			$build_args += $flag_subsystem + 'windows'
			# $build_args += $flag_show_system_calls
			# $build_args += $flag_show_timings

			if ( Test-Path $module_dll) {
				$module_dll_pre_build_hash = get-filehash -path $module_dll -Algorithm MD5
			}
			& $odin_compiler $build_args
			$module_dll_post_build_hash = get-filehash -path $module_dll -Algorithm MD5
			return $module_dll_pre_build_hash -ne $module_dll_post_build_hash
		}
		$sectr_built = build-sectr
		write-host # newline pad

		function build-host
		{
			$executable   = join-path $path_build ($project_name + '_host.exe')
			$pdb          = join-path $path_build ($project_name + '_host.pdb')

			if ( $host_process_active ) {
				write-host 'Skipping sectr_host build, process is active'
				return
			}

			$should_build = (check-ModuleForChanges $module_host) && (-not $sectr_built)
			if ( -not( $should_build)) {
				write-host 'Skipping sectr_host build, module up to date'
				return
			}

			$linker_args = ""
			$linker_args += ( $flag_msvc_link_disable_dynamic_base + ' ' )

			$build_args = @()
			$build_args += $command_build
			$build_args += './host'
			$build_args += $flag_output_path + $executable
			$build_args += ($flag_collection + $pkg_collection_thirdparty)
			$build_args += $flag_use_separate_modules
			$build_args += $flag_thread_count + $CoreCount_Physical
			$build_args += $flag_optimize_none
			$build_args += $flag_debug
			$build_args += $flag_pdb_name + $pdb
			$build_args += ($flag_extra_linker_flags + $linker_args )
			$build_args += $flag_subsystem + 'windows'
			# $build_args += $flag_show_system_call
			# $build_args += $flag_show_timings

			write-host 'Building Host Module'
			& $odin_compiler $build_args
			write-host
		}
		build-host

		Pop-Location # path_code
	}
	build-prototype
pop-location # path_root
