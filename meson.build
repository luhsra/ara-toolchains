project('toolchains', 'c', 'cpp',
  version : '0.1',
  default_options : ['warning_level=3'])

fs = import('fs')

py3_mod = import('python')
py3_inst = py3_mod.find_installation('python3')

# version is not specified, declare the same dependency in parrot before including the subproject to force a version
llvm_dep = dependency('llvm', method: 'config-tool', include_type: 'system')
llvm_bindir = llvm_dep.get_variable(configtool: 'bindir')
llc = find_program(llvm_bindir / 'llc')
llvm_objcopy = find_program(llvm_bindir / 'llvm-objcopy')
llvm_ld = find_program(llvm_bindir / 'lld')
llvm_dis = find_program(llvm_bindir / 'llvm-dis')
clang = find_program(llvm_bindir / 'clang')
clangpp = find_program(llvm_bindir / 'clang++')

llvm_targets = files('llvm_targets.py')

# ARM toolchain
if not get_option('enable_arm').disabled()
  arm_triple = 'arm-none-eabi'
  arm_toolchain = true
  errors = []

  # include paths
  arm_include_path = get_option('arm_include_dir').format(get_option('arm_libs'))
  # tests
  test = fs.exists(arm_include_path)
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'arm_include_dir (@arm_include_path@) is not a valid directory.'
  endif

  # lib path
  arm_link_path = get_option('arm_link_dir').format(get_option('arm_libs'))
  # tests
  test = fs.exists(arm_link_path)
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'arm_lib_dir (@arm_link_path@) is not a valid directory.'
  endif
  test = fs.exists(arm_link_path / 'libc.a')
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'arm_lib_dir (@arm_link_path@) does not contain a libc.a.'
  endif


  # gcc tools and libs
  tools = ['gcc', 'ar', 'ranlib', 'c++', 'size', 'objcopy']
  foreach tool : tools
    set_variable('arm_' + tool.underscorify(), find_program(arm_triple + '-' + tool))
  endforeach

  gcc_version = files('gcc_version.py') # drop, when https://github.com/mesonbuild/meson/issues/7166 is resolved
  if get_option('arm_gcc_version') == 'default'
    r = run_command(py3_inst, gcc_version, arm_gcc.path(), check: true)
    if r.returncode() != 0
      error('Cannot extract default GCC option. Consider setting "arm_gcc_version".')
    endif
    gcc_arm_version = r.stdout().strip()
    gcc_arm_major_version = gcc_arm_version.split('.')[0]
  else
    gcc_arm_version = get_option('arm_gcc_version')
  endif
  libgcc_dir = get_option('arm_gcc_dir').format(gcc_arm_version)
  gcc_dir_error = ''
  if not fs.exists(libgcc_dir)
    gcc_dir_error = f'\nlibgcc_dir (@libgcc_dir@) is not a valid directory.'
    libgcc_dir = get_option('arm_gcc_dir').format(gcc_arm_major_version)
  endif

  # tests
  test = fs.exists(libgcc_dir)
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'libgcc_dir (@libgcc_dir@) is not a valid directory.' + gcc_dir_error
  endif

  test = fs.exists(libgcc_dir / 'libgcc.a')
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'libgcc_dir (@libgcc_dir@) does not contain libgcc.a.'
  endif

  # c++ library
  gcc_cxx_include = libgcc_dir / 'include' / f'g++-v@gcc_arm_major_version@'
  test = fs.exists(gcc_cxx_include)
  arm_toolchain = arm_toolchain and test
  if not test
    errors += 'gcc_cxx_include (@gcc_cxx_include@) is not a valid directory.'
  endif
  test = fs.exists(gcc_cxx_include / 'iostream')
  arm_toolchain = arm_toolchain and test
  if not test
    errors += 'gcc_cxx_include (@gcc_cxx_include@) does not contain iostream.'
  endif


  # llvm handling
  wanted_llvm_targets = ['arm', 'arm64']
  r = run_command(
    py3_inst, llvm_targets,
    '--llc', llc.full_path(),
    '--targets', wanted_llvm_targets, check: true)
  message(r.returncode())
  test = r.returncode() == 0
  arm_toolchain = arm_toolchain and test
  if not test
    errors += 'Clang does not support the targets @0@.'.format(', '.join(wanted_llvm_targets))
  endif

  # TODO download toolchain if not found
  # see arm_toolchain.sh
  error_string = 'ARM toolchain not found. The following errors occured:\n@0@'.format('\n'.join(errors))
  if not arm_toolchain
    if get_option('enable_arm').enabled()
      error(error_string)
    else
      message(error_string)
    endif
  endif

  summary({
    'ARM GCC': arm_gcc,
    'ARM GCC libraries': libgcc_dir,
    'ARM include directory': arm_include_path,
    'ARM linkage directory': arm_link_path,
    'LLVM supports @0@'.format(', '.join(wanted_llvm_targets)): true,
  })
endif
