project('toolchains', 'c', 'cpp',
  version : '0.1',
  default_options : ['warning_level=3'])

fs = import('fs')

py3_mod = import('python')
py3_inst = py3_mod.find_installation('python3')

# LLVM variables and tools
# version is not specified, declare the same dependency in parrot before including the subproject to force a version
llvm_dep = dependency('llvm', method: 'config-tool', include_type: 'system')
llvm_bindir = llvm_dep.get_variable(configtool: 'bindir')
llc = find_program(llvm_bindir / 'llc')
llvm_objcopy = find_program(llvm_bindir / 'llvm-objcopy')
llvm_ld = find_program(llvm_bindir / 'ld.lld')
llvm_ar = find_program(llvm_bindir / 'llvm-ar')
llvm_dis = find_program(llvm_bindir / 'llvm-dis')
llvm_opt = find_program(llvm_bindir / 'opt')
clang = find_program(llvm_bindir / 'clang')
clangpp = find_program(llvm_bindir / 'clang++')

llvm_targets = files('llvm_targets.py')

## ara-link
ara_link = find_program('ara-link', version: llvm_dep.version(), required: false)
if not ara_link.found()
    ara_link_proj = subproject('ara-link')
    ara_link = ara_link_proj.get_variable('ara_link')
    message('Using ara-link from subproject.')
endif
llvm_link_cmd = [ara_link, '-S', '-o', '@OUTPUT@', '@INPUT@',]

# POSIX x86-64 toolchain
posix_enabled = false
if not get_option('enable_posix').disabled()
  # TODO, we currently hard depend on a build on POSIX
  assert(host_machine.system() == 'linux', 'Build on a non Linux system is not supported.')
  posix_ar = find_program('ar')

  posix_llvm = ['x86', 'x86-64']
  r = run_command(
    py3_inst, llvm_targets,
    '--llc', llc.full_path(),
    '--targets', posix_llvm, check: true)
  test = r.returncode() == 0
  if not test
    error('Clang does not support the targets @0@.'.format(', '.join(posix_llvm)))
  endif

  posix_enabled = true
endif

# ARM toolchain
arm_gcc = disabler()
arm_libgcc_dir = disabler()
arm_include_path = disabler()
arm_link_path = disabler()
arm_cxx_dir = disabler()
arm_enabled = false
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
  arm_tools = ['gcc', 'ar', 'ranlib', 'c++', 'size', 'objcopy', 'nm']
  arm_tools_summary = []
  foreach tool : arm_tools
    arm_tool = find_program(arm_triple + '-' + tool)
    set_variable('arm_' + tool.underscorify(), arm_tool)
    arm_tools_summary += [{'key': tool, 'value': arm_tool}]
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
  arm_libgcc_dir = get_option('arm_gcc_dir').format(gcc_arm_version)
  gcc_dir_error = ''
  if not fs.exists(arm_libgcc_dir)
    gcc_dir_error = f'\narm_libgcc_dir (@arm_libgcc_dir@) is not a valid directory.'
    arm_libgcc_dir = get_option('arm_gcc_dir').format(gcc_arm_major_version)
  endif

  # tests
  test = fs.exists(arm_libgcc_dir)
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'arm_libgcc_dir (@arm_libgcc_dir@) is not a valid directory.' + gcc_dir_error
  endif

  test = fs.exists(arm_libgcc_dir / 'libgcc.a')
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'arm_libgcc_dir (@arm_libgcc_dir@) does not contain libgcc.a.'
  endif

  # c++ library
  arm_cxx_dir= get_option('arm_cxx_dir')
  if arm_cxx_dir == 'default'
    arm_cxx_dir = arm_libgcc_dir / 'include' / f'g++-v@gcc_arm_major_version@'
  endif
  test = fs.exists(arm_cxx_dir)
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'arm_cxx_dir (@arm_cxx_dir@) is not a valid directory.'
  endif
  test = fs.exists(arm_cxx_dir / 'iostream')
  arm_toolchain = arm_toolchain and test
  if not test
    errors += f'arm_cxx_dir (@arm_cxx_dir@) does not contain iostream.'
  endif


  # llvm handling
  arm_llvm = ['arm', 'arm64']
  r = run_command(
    py3_inst, llvm_targets,
    '--llc', llc.full_path(),
    '--targets', arm_llvm, check: true)
  test = r.returncode() == 0
  arm_toolchain = arm_toolchain and test
  if not test
    errors += 'Clang does not support the targets @0@.'.format(', '.join(arm_llvm))
  endif

  # TODO download toolchain if not found
  # see arm_toolchain.sh
  arm_enabled = true
  error_string = 'ARM toolchain not found. The following errors occured:\n@0@'.format('\n'.join(errors))
  if not arm_toolchain
    if get_option('enable_arm').enabled()
      error(error_string)
    else
      message(error_string)
      arm_enabled = false
    endif
  endif
endif

summary({
  'POSIX is enabled': posix_enabled,
  'ARM is enabled': arm_enabled,
}, bool_yn: true, section: 'Architectures')

summary({
  'ar': posix_ar,
  'LLVM supports @0@'.format(', '.join(posix_llvm)): true,
}, bool_yn: true, section: 'POSIX')

if arm_enabled
  summary({
    'ARM GCC': arm_gcc,
    'ARM GCC libraries': arm_libgcc_dir,
    'ARM C++ libraries': arm_cxx_dir,
    'ARM include directory': arm_include_path,
    'ARM linkage directory': arm_link_path,
    'LLVM supports @0@'.format(', '.join(arm_llvm)): true,
  }, bool_yn: true, section: 'ARM')

  foreach arm_tool : arm_tools_summary
    summary(arm_tool['key'], arm_tool['value'], bool_yn: true, section: 'ARM')
  endforeach
endif

summary({
  'llc': llc,
  'llvm-objcopy': llvm_objcopy,
  'lld': llvm_ld,
  'llvm-ar': llvm_ar,
  'llvm-dis': llvm_dis,
  'opt': llvm_opt,
  'clang': clang,
  'clang++': clangpp,
}, bool_yn: true, section: 'LLVM')
