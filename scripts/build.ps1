cls

$path_root       = git rev-parse --show-toplevel
$path_code       = join-path $path_root 'code'
$path_build      = join-path $path_root 'build'
$path_thirdparty = join-path $path_root 'thirdparty'

# Odin Compiler Flags

$flag_build                               = 'build'
$flag_run                                 = 'run'
$flag_check                               = 'check'
$flag_query                               = 'query'
$flag_report                              = 'report'
$flag_debug                               = '-debug'
$flag_output_path                         = '-out='
$flag_optimization_level                  = '-opt:'
$flag_optimize_none                       = '-o:none'
$flag_optimize_minimal                    = '-o:minimal'
$flag_optimize_size                       = '-o:size'
$flag_optimize_speed                      = '-o:speed'
$falg_optimize_aggressive                 = '-o:aggressive'
$flag_show_timings                        = '-show-timings'
$flag_show_more_timings                   = '-show-more-timings'
$flag_thread_count                        = '-thread-count:'
$flag_collection                          = '-collection:'
$flag_build_mode                          = '-build-mode:'
$flag_build_mode_dll                      = '-build-mode:dll'
$flag_no_bounds_check                     = '-no-bounds-check'
$flag_disable_assert                      = '-disable-assert'
$flag_no_thread_local                     = '-no-thread-local'
$flag_no_thread_checker                   = '-no-thread-checker'
$flag_vet_all                             = '-vet'
$flag_vet_unused_entities                 = '-vet-unused'
$flag_vet_semicolon                       = '-vet-semicolon'
$flag_vet_shadow_vars                     = '-vet-shadowing'
$flag_vet_using_stmt                      = '-vet-using-stmt'
$flag_use_separate_modules                = '-use-separate-modules'
$flag_define                              = '-define:'

$flag_extra_assembler_flags               = '-extra_assembler-flags:'
$flag_extra_linker_flags                  = '-extra-linker-flags:'
$flag_ignore_unknown_attributes           = '-ignore-unknown-attributes'
$flag_keep_temp_files                     = '-keep-temp-files'
$flag_no_crt                              = '-no-crt'
$flag_no_entrypoint                       = '-no-entry-point'
$flag_pdb_name                            = '-pdb-name:'
$flag_sanitize                            = '-sanitize:'
$flag_subsystem                           = '-subsystem:'
$flag_target                              = '-target:'
$flag_use_lld                             = '-lld'

push-location $path_root

	if ( -not( test-path 'build') ) {
		new-item -ItemType Directory -Path 'build'
	}
	function build-prototype
	{
		$host_process_active = Get-Process | Where-Object {$_.Name -like 'sectr_host*'}

		push-location $path_code

		$project_name = 'sectr'
		$executable   = join-path $path_build ($project_name + '_host.exe')
		$pdb          = join-path $path_build ($project_name + '_host.pdb')

		if ( -not($host_process_active)) {
			$build_args = @()
			$build_args += $flag_build
			$build_args += './host'
			$build_args += $flag_output_path + $executable
			$build_args += $flag_optimize_none
			$build_args += $flag_debug
			$build_args += $flag_pdb_name + $pdb
			$build_args += $flag_subsystem + 'windows'

			& odin $build_args

			$third_party_dlls = Get-ChildItem -Path $path_thirdparty -Filter '*.dll'
			foreach ($dll in $third_party_dlls) {
					$destination = join-path $path_build $dll.Name
					Copy-Item $dll.FullName -Destination $destination -Force
			}
		}
		else {
			write-host 'Skipping sectr_host build, process is active'
		}

		$module_dll = join-path $path_build ( $project_name + '.dll' )
		$pdb        = join-path $path_build ( $project_name + '.pdb' )

		$build_args = @()
		$build_args += $flag_build
		$build_args += '.'
		$build_args += $flag_build_mode_dll
		$build_args += $flag_output_path + $module_dll
		$build_args += $flag_optimize_none
		$build_args += $flag_debug
		$build_args += $flag_pdb_name + $pdb

		& odin $build_args

		Pop-Location
	}
	build-prototype
pop-location
