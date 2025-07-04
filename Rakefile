require_relative './lib/natalie/compiler/flags'
begin
  require 'syntax_tree/rake_tasks'
rescue LoadError
end

task default: :build

DEFAULT_BUILD_MODE = 'release'.freeze
DL_EXT = RbConfig::CONFIG['DLEXT']
SO_EXT = RbConfig::CONFIG['SOEXT']
SRC_DIRECTORIES = Dir.new('src').children.select { |p| File.directory?(File.join('src', p)) }

desc 'Build Natalie'
task :build do
  type = current_build_mode
  Rake::Task["build_#{type}"].invoke
end

desc 'Build Natalie with release optimizations enabled and warnings off (default)'
task build_release: %i[set_build_release libnatalie prism_c_ext libnat] do
  puts 'Build mode: release'
end

desc 'Build Natalie with no optimization and all warnings'
task build_debug: %i[set_build_debug libnatalie prism_c_ext libnat ctags] do
  puts 'Build mode: debug'
end

desc 'Build Natalie with sanitizers enabled'
task build_sanitized: %i[set_build_sanitized libnatalie prism_c_ext libnat] do
  puts 'Build mode: sanitized'
end

desc 'Remove temporary files created during build'
task :clean do
  SRC_DIRECTORIES.each do |subdir|
    path = File.join('build', subdir)
    rm_rf path
  end
  rm_rf 'build/build.log'
  rm_rf 'build/generated'
  rm_rf 'build/libnatalie_base.a'
  rm_rf "build/libnatalie_base.#{DL_EXT}"
  rm_rf 'build/libnat'
  rm_rf "build/libnat.#{SO_EXT}"
  rm_rf Rake::FileList['build/*.o']
  rm_rf 'test/build'
end

desc 'Remove all generated files'
task :clobber do
  rm_rf 'build'
  rm_rf '.build'
  rm_rf 'test/build'
end

task distclean: :clobber

desc 'Run the test suite'
task test: %i[build build_test_support] do
  sh 'bundle exec ruby test/all.rb'
end

desc 'Run the most-recently-modified test'
task test_last_modified: :build do
  last_edited = Dir['test/**/*_test.rb', 'spec/**/*_spec.rb'].max_by { |path| File.stat(path).mtime.to_i }
  sh ['bin/natalie', '-I', 'test/support', ENV['FLAGS'], last_edited].compact.join(' ')
end

desc 'Run a folder with tests'
task :test_folder, [:folder] => :build do |task, args|
  if args[:folder].nil?
    warn("Please run with the folder as argument: `rake #{task.name}[<spec/X/Y>]")
    exit(1)
  elsif !File.directory?(args[:folder])
    warn("The folder #{args[:folder]} does not exist or is not a directory")
    exit(1)
  else
    specs = Dir["#{args[:folder]}/**/*_test.rb", "#{args[:folder]}/**/*_spec.rb"]
    sh ['bin/natalie', 'test/runner.rb', specs.to_a].join(' ')
  end
end

desc 'Run the most-recently-modified test when any source files change (requires entr binary)'
task :watch do
  sh 'find . \( -path build -o -path ext -o -path master \) -prune ' \
       "-o -name '*.cpp' -o -name '*.c' -o -name '*.hpp' -o -name '*.rb' | " \
       "entr -c -s 'rake test_last_modified'"
end

# The self-hosted compiler is a bit slow yet, so let's run a core subset
# of the tests during regular CI.
desc 'Test that the self-hosted compiler builds and runs a core subset of the tests'
task test_self_hosted: %i[bootstrap build_test_support] do
  sh 'bin/nat --version'
  env = { 'NAT_BINARY' => 'bin/nat', 'GLOB' => 'spec/language/*_spec.rb', 'SPEC_TIMEOUT' => '480' }
  sh env, 'bundle exec ruby test/all.rb'
end

desc 'Test that the self-hosted compiler builds and runs the full test suite'
task test_self_hosted_full: %i[bootstrap build_test_support] do
  sh 'bin/nat --version'
  env = { 'NAT_BINARY' => 'bin/nat' }
  sh env, 'bundle exec ruby test/all.rb'
end

desc 'Test that some representative code runs with the AddressSanitizer enabled'
task test_asan: [:build_sanitized, :build_test_support, 'bin/nat'] do
  ENV['ASAN_OPTIONS'] ||= 'detect_stack_use_after_return=1'
  sh 'ruby test/asan_test.rb'
end

task test_all_ruby_spec_nightly: :build do
  unless ENV['CI'] || ENV['DOCKER']
    puts 'This task only runs on CI and/or in Docker, because it is destructive.'
    puts 'Please set CI=true if you really want to run this.'
    exit 1
  end

  sh <<~END
    bundle config set --local with 'run_all_specs'
    bundle install
    git clone https://github.com/ruby/spec /tmp/ruby_spec
    mv spec/support spec/spec_helper.rb /tmp/ruby_spec
    rm -rf spec
    mv /tmp/ruby_spec spec
  END

  sh 'bundle exec ruby spec/support/nightly_ruby_spec_runner.rb'
end

task test_perf: [:build_release, 'bin/nat'] do
  sh 'ruby spec/support/test_perf.rb'
end

task test_perf_quickly: [:build_release] do
  sh 'ruby spec/support/test_perf.rb --quickly'
end

task output_language_specs: :build do
  version = RUBY_VERSION.sub(/\.\d+$/, '')
  sh <<~END
    bundle config set --local with 'run_all_specs'
    bundle install
    GLOB=spec/language/**/*_spec.rb ruby spec/support/cpp_output_specs.rb output/ruby#{version}
  END
end

task :copy_generated_files_to_output do
  version = RUBY_VERSION.sub(/\.\d+$/, '')
  Dir['build/generated/*'].each do |entry|
    mkdir_p entry.sub('build/generated', "output/ruby#{version}") if File.directory?(entry)
  end
  Rake::FileList['build/generated/**/*.cpp'].each do |path|
    cp path, path.sub('build/generated', "output/ruby#{version}")
  end
end

desc 'Build the self-hosted version of Natalie at bin/nat'
task bootstrap: [:build, 'bin/nat']

desc 'Build MRI C Extension for Prism'
task prism_c_ext: ["build/libprism.#{SO_EXT}", "build/prism/ext/prism/prism.#{DL_EXT}"]

desc 'Show line counts for the project'
task :cloc do
  sh 'cloc include lib src test'
end

desc 'Generate tags file for development'
task :ctags do
  if system('command -v ctags 2>&1 >/dev/null')
    out = `ctags #{HEADERS + SOURCES} 2>&1`
    puts out unless $?.success?
  else
    puts 'Note: ctags is not available on this system'
  end
end
task tags: :ctags

desc 'Format C++ code with clang-format'
task :format do
  sh 'find include src lib ' \
       "-type f -name '*.?pp' " \
       '! -path src/encoding/casemap.cpp ' \
       '! -path src/encoding/casefold.cpp ' \
       '-exec clang-format -i --style=file {} +'
  if Rake::Task.task_defined?('stree:write')
    Rake::Task['stree:write'].invoke
  else
    puts 'Did NOT run syntax_tree because it is not installed.'
  end
end

desc 'Show TODO and FIXME comments in the project'
task :todo do
  sh "egrep -r 'FIXME|TODO' src include lib"
end

desc 'Run clang-tidy'
task tidy: %i[build tidy_internal]

desc 'Lint GC visiting code'
task gc_lint: %i[build gc_lint_internal]

# # # # Docker Tasks (used for CI) # # # #

def docker_run_flags
  ci = '-i -t' if !ENV['CI'] && $stdout.isatty
  ci = "-e CI=#{ENV['CI']}" if ENV['CI']
  glob = "-e GLOB='#{ENV['GLOB']}'" if ENV['GLOB']
  ['-e DOCKER=true', ci, glob].compact.join(' ')
end

DEFAULT_HOST_RUBY_VERSION = 'ruby3.4'.freeze
SUPPORTED_HOST_RUBY_VERSIONS = %w[ruby3.2 ruby3.3 ruby3.4].freeze

def default_docker_build_args
  [
    "--build-arg IMAGE='ruby:#{ruby_version_number}'",
    "--build-arg NAT_BUILD_MODE=#{ENV.fetch('NAT_BUILD_MODE', 'release')}",
    "--build-arg NEED_VALGRIND=#{ENV.fetch('NEED_VALGRIND', 'false')}",
    "--build-arg NEED_CASTXML=#{ENV.fetch('NEED_CASTXML', 'false')}",
  ]
end

task :docker_build_gcc do
  suffix = ruby_version_string
  suffix += '_sanitized' if ENV['NAT_BUILD_MODE'] == 'sanitized'
  sh "docker build -t natalie_gcc_#{suffix} " \
       "#{default_docker_build_args.join(' ')} " \
       '.'
end

task :docker_build_clang do
  suffix = ruby_version_string
  suffix += '_sanitized' if ENV['NAT_BUILD_MODE'] == 'sanitized'
  sh "docker build -t natalie_clang_#{suffix} " \
       "#{default_docker_build_args.join(' ')} " \
       '--build-arg CC=clang ' \
       '--build-arg CXX=clang++ ' \
       '.'
end

task docker_bash: :docker_build_clang do
  sh "docker run -it --rm --entrypoint bash natalie_clang_#{ruby_version_string}"
end

task docker_bash_gcc: :docker_build_gcc do
  sh "docker run -it --rm --entrypoint bash natalie_gcc_#{ruby_version_string}"
end

task docker_bash_lldb: :docker_build_clang do
  sh 'docker run -it --rm ' \
       '--entrypoint bash ' \
       '--cap-add=SYS_PTRACE ' \
       '--security-opt seccomp=unconfined ' \
       "natalie_clang_#{ruby_version_string}"
end

task docker_bash_gdb: :docker_build_gcc do
  sh 'docker run -it --rm ' \
       '--entrypoint bash ' \
       '--cap-add=SYS_PTRACE ' \
       '--security-opt seccomp=unconfined ' \
       '-m 2g ' \
       '--cpus=2 ' \
       "natalie_gcc_#{ruby_version_string}"
end

task docker_test: %i[docker_test_gcc docker_test_clang docker_test_self_hosted docker_test_asan]

task :docker_test_output do
  rm_rf 'output'

  SUPPORTED_HOST_RUBY_VERSIONS.each do |version|
    mkdir_p "output/#{version}"
    ENV['RUBY'] = version
    Rake::Task[:docker_build_clang].invoke
    Rake::Task[:docker_build_clang].reenable # allow to run again
    sh "docker run #{docker_run_flags} --rm -v $(pwd)/output:/natalie/output " \
         "--entrypoint rake natalie_clang_#{version} " \
         'output_language_specs ' \
         'copy_generated_files_to_output'
  end

  SUPPORTED_HOST_RUBY_VERSIONS.each_cons(2) do |v1, v2|
    success = sh("diff -r output/#{v1} output/#{v2}")
    raise "Output for #{v1} and #{v2} differs" unless success
  end
end

task docker_test_gcc: :docker_build_gcc do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake natalie_gcc_#{ruby_version_string} test"
end

task docker_test_clang: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake natalie_clang_#{ruby_version_string} test"
end

task docker_test_self_hosted: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake natalie_clang_#{ruby_version_string} test_self_hosted"
end

task docker_test_self_hosted_full: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake natalie_clang_#{ruby_version_string} test_self_hosted_full"
end

task :docker_test_asan do
  ENV['NAT_BUILD_MODE'] = 'sanitized'
  Rake::Task['docker_build_gcc'].invoke
  sh "docker run #{docker_run_flags} --rm --entrypoint rake -e SOME_TESTS='#{ENV['SOME_TESTS']}' -e SPEC_TIMEOUT=480 natalie_gcc_#{ruby_version_string}_sanitized test_asan"
end

task docker_test_all_ruby_spec_nightly: :docker_build_clang do
  sh "docker run #{docker_run_flags} " \
       "-e STATS_API_SECRET=#{(ENV['STATS_API_SECRET'] || '').inspect} " \
       '--rm ' \
       '--entrypoint rake ' \
       "natalie_clang_#{ruby_version_string} test_all_ruby_spec_nightly"
end

task :docker_test_perf do
  ENV['NEED_VALGRIND'] = 'true'
  Rake::Task['docker_build_clang'].invoke
  sh "docker run #{docker_run_flags} " \
       "-e STATS_API_SECRET=#{(ENV['STATS_API_SECRET'] || '').inspect} " \
       "-e GIT_SHA=#{(ENV['LAST_COMMIT_SHA'] || '').inspect} " \
       "-e GIT_BRANCH=#{(ENV['BRANCH'] || '').inspect} " \
       '--rm ' \
       '--entrypoint rake ' \
       "natalie_clang_#{ruby_version_string} test_perf"
end

task docker_gc_stress_test: :docker_build_clang do
  sh "docker run #{docker_run_flags} " \
       '--rm ' \
       '--entrypoint bash ' \
       "natalie_clang_#{ruby_version_string} -c 'bin/natalie test/gc_stress_test.rb; status=$?; echo; echo $status; exit $status'"
end

task docker_tidy: :docker_build_clang do
  sh "docker run #{docker_run_flags} --rm --entrypoint rake natalie_clang_#{ruby_version_string} tidy"
end

task :docker_gc_lint do
  ENV['NEED_CASTXML'] = 'true'
  Rake::Task['docker_build_clang'].invoke
  sh "docker run #{docker_run_flags} --rm --entrypoint rake natalie_clang_#{ruby_version_string} gc_lint"
end

def ruby_version_string
  string = ENV['RUBY'] || DEFAULT_HOST_RUBY_VERSION
  raise 'must be in the format rubyX.Y' unless string =~ /^ruby\d\.\d$/
  string
end

def ruby_version_number
  ruby_version_string.sub('ruby', '')
end

# # # # Build Compile Database # # # #

if system('command -v compiledb 2>&1 >/dev/null')
  $compiledb_out = []

  def $stderr.puts(str)
    write(str + "\n")
    $compiledb_out << str
  end

  task :write_compile_database do
    if $compiledb_out.any?
      File.write('build/build.log', $compiledb_out.join("\n"))
      sh 'compiledb < build/build.log'
    end
  end
else
  task :write_compile_database do
    # noop
  end
end

# # # # Internal Tasks and Rules # # # #

STANDARD = 'c++17'.freeze
HEADERS = Rake::FileList['include/**/{*.h,*.hpp}']

PRIMARY_SOURCES = Rake::FileList['src/**/*.{c,cpp}'].exclude('src/main.cpp', 'src/des_tables.c')
RUBY_SOURCES = Rake::FileList['src/**/*.rb']
LIBNAT_SOURCES = Rake::FileList['lib/natalie/**/*.rb', 'lib/libnat_api.rb']
SPECIAL_SOURCES = Rake::FileList['build/generated/platform.cpp', 'build/generated/bindings.cpp']
SOURCES = PRIMARY_SOURCES + RUBY_SOURCES + LIBNAT_SOURCES + SPECIAL_SOURCES

PRIMARY_OBJECT_FILES = PRIMARY_SOURCES.sub('src/', 'build/').pathmap('%p.o')
RUBY_OBJECT_FILES = RUBY_SOURCES.pathmap('build/generated/%{^src/,}p.o')
SPECIAL_OBJECT_FILES = SPECIAL_SOURCES.pathmap('%p.o')
OBJECT_FILES = PRIMARY_OBJECT_FILES + RUBY_OBJECT_FILES + SPECIAL_OBJECT_FILES

# Find duplicate object files (even if in different directories), because a static library
# with duplicate names causes the following runtime warning on macOS:
#
#     warning: (arm64)  skipping debug map object with duplicate name and timestamp
#
object_file_names = OBJECT_FILES.map { |f| File.basename(f) }
if (duplicated_object_files = object_file_names.select { |f| object_file_names.count(f) > 1 }).any?
  raise "Duplicate object files detected: #{duplicated_object_files.inspect}"
end

require 'tempfile'

task(:set_build_debug) do
  Rake::Task[:clean].invoke if current_build_mode != 'debug'
  ENV['BUILD'] = 'debug'
  File.write('.build', 'debug')
end

task(:set_build_sanitized) do
  Rake::Task[:clean].invoke if current_build_mode != 'sanitized'
  ENV['BUILD'] = 'sanitized'
  File.write('.build', 'sanitized')
end

task(:set_build_release) do
  Rake::Task[:clean].invoke if current_build_mode != 'release'
  ENV['BUILD'] = 'release'
  File.write('.build', 'release')
end

task libnatalie: [
       :update_submodules,
       :bundle_install,
       :build_dir,
       'build/zlib/libz.a',
       'build/onigmo/lib/libonigmo.a',
       'build/libprism.a',
       "build/libprism.#{SO_EXT}",
       'build/generated/numbers.rb',
       :primary_objects,
       :ruby_objects,
       :special_objects,
       'build/libnatalie.a',
       "build/libnatalie_base.#{DL_EXT}",
       :write_compile_database,
     ]

# libnat is the parser and compiler, needed for the REPL.
task libnat: ["build/libnat.#{SO_EXT}"]

task :build_dir do
  mkdir_p 'build/generated' unless File.exist?('build/generated')
end

task build_test_support: ["build/test/support/ffi_stubs.#{SO_EXT}"]

multitask primary_objects: PRIMARY_OBJECT_FILES
multitask ruby_objects: RUBY_OBJECT_FILES
multitask special_objects: SPECIAL_OBJECT_FILES

file 'build/libnatalie.a' => %w[build/libnatalie_base.a build/onigmo/lib/libonigmo.a] do |t|
  apple_libtool = system('libtool -V 2>&1 | grep Apple 2>&1 >/dev/null')
  if apple_libtool
    sh "libtool -static -o #{t.name} #{t.sources.join(' ')}"
  else
    ar_script = ["create #{t.name}"]
    t.sources.each { |source| ar_script << "addlib #{source}" }
    ar_script << 'save'
    ENV['AR_SCRIPT'] = ar_script.join("\n")
    sh 'echo "$AR_SCRIPT" | ar -M'
  end
end

file 'build/libnatalie_base.a' => OBJECT_FILES + HEADERS do |t|
  sh "ar rcs #{t.name} #{OBJECT_FILES}"
end

file "build/libnatalie_base.#{DL_EXT}" => OBJECT_FILES + HEADERS do |t|
  sh "#{cxx} -shared -fPIC -rdynamic -Wl,-undefined,dynamic_lookup -o #{t.name} #{OBJECT_FILES}"
end

file 'build/onigmo/lib/libonigmo.a' do
  build_dir = File.expand_path('build/onigmo', __dir__)
  patch_path = File.expand_path('ext/onigmo.patch', __dir__)
  rm_rf build_dir
  cp_r 'ext/onigmo', build_dir
  sh <<-SH
    cd #{build_dir} && \
    sh autogen.sh && \
    ./configure --with-pic --prefix #{build_dir} && \
    git apply #{patch_path} && \
    make -j && \
    make install
  SH
end

file 'build/zlib/libz.a' do
  build_dir = File.expand_path('build/zlib', __dir__)
  rm_rf build_dir
  cp_r 'ext/zlib', build_dir
  sh <<-SH
    cd #{build_dir} && \
    ./configure && \
    make -j
  SH
end

file 'build/generated/numbers.rb' do |t|
  f1 = Tempfile.new(%w[numbers .cpp])
  f2 = Tempfile.create('numbers')
  f2.close
  begin
    f1.puts '#include <stdio.h>'
    f1.puts '#include "natalie/constants.hpp"'
    f1.puts 'int main() {'
    f1.puts '  printf("NAT_MAX_FIXNUM = %lli\n", Natalie::NAT_MAX_FIXNUM);'
    f1.puts '  printf("NAT_MIN_FIXNUM = %lli\n", Natalie::NAT_MIN_FIXNUM);'
    f1.puts '}'
    f1.close
    sh "#{cxx} #{include_flags.join(' ')} -std=#{STANDARD} -o #{f2.path} #{f1.path}"
    sh "#{f2.path} > #{t.name}"
  ensure
    File.unlink(f1.path)
    File.unlink(f2.path)
  end
end

file 'build/generated/platform.cpp' => OBJECT_FILES - ['build/generated/platform.cpp.o'] do |t|
  git_revision = `git show --pretty=%H --quiet`.chomp
  File.write(t.name, <<~END)
    #include "natalie.hpp"
    const char *Natalie::ruby_platform = #{RUBY_PLATFORM.inspect};
    const char *Natalie::ruby_release_date = "#{Time.now.strftime('%Y-%m-%d')}";
    const char *Natalie::ruby_revision = "#{git_revision}";
  END
end

file 'build/generated/platform.cpp.o' => 'build/generated/platform.cpp' do |t|
  sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -c -o #{t.name} #{t.name.pathmap('%d/%n')}"
end

file 'build/generated/bindings.cpp.o' => ['lib/natalie/compiler/binding_gen.rb'] + HEADERS do |t|
  sh "ruby lib/natalie/compiler/binding_gen.rb > #{t.name.pathmap('%d/%n')}"
  sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -c -o #{t.name} #{t.name.pathmap('%d/%n')}"
end

file 'bin/nat' => LIBNAT_SOURCES + %w[bin/natalie build/libnatalie.a] do
  sh 'bin/natalie --build-dir=build/libnat -c bin/nat bin/natalie'
end

file "build/libnat.#{SO_EXT}" => LIBNAT_SOURCES do |t|
  if system('pkg-config --exists libffi')
    ffi_cxx_flags = `pkg-config --cflags libffi`.chomp
    ffi_ld_flags = `pkg-config --libs libffi`.chomp
  end
  cxx_flags = (extra_cxx_flags + [ffi_cxx_flags]).compact.join(' ').strip
  cmd = [
    "CXX='#{cxx}'",
    "NAT_CXX_FLAGS=#{cxx_flags.inspect}",
    "NAT_LD_FLAGS='-shared -fPIC -rdynamic -Wl,-undefined,dynamic_lookup'",
    "bin/natalie -c build/libnat.#{SO_EXT}",
    '--build-dir=build/libnat',
    '--compilation-type=shared-object',
    'lib/libnat_api.rb',
  ].join(' ')
  sh cmd
end

rule '.c.o' => 'src/%n' do |t|
  sh "#{cc} -I include -g -fPIC -c -o #{t.name} #{t.source}"
end

rule '.cpp.o' => ['src/%{build/,}X'] + HEADERS do |t|
  subdir = File.dirname(t.name)
  mkdir_p(subdir) unless File.directory?(subdir)
  sh "#{cxx} #{cxx_flags.join(' ')} -std=#{STANDARD} -c -o #{t.name} #{t.source}"
end

rule '.rb.o' => ['src/%{build\/generated/,}X'] do |t|
  subdir = File.dirname(t.name)
  mkdir_p(subdir) unless File.directory?(subdir)
  sh "NAT_CXX_FLAGS='#{extra_cxx_flags.join(' ')}' CXX='#{cxx}' bin/natalie --compilation-type=object -c #{t.name} #{t.source}"
end

file "build/libprism.#{SO_EXT}" => ['build/libprism.a']

file 'build/libprism.a' => ["build/prism/ext/prism/prism.#{DL_EXT}"] do
  build_dir = File.expand_path('build/prism', __dir__)
  cp "#{build_dir}/build/libprism.a", File.expand_path('build', __dir__)
  cp "#{build_dir}/build/libprism.#{SO_EXT}", File.expand_path('build', __dir__)
end

file "build/prism/ext/prism/prism.#{DL_EXT}" => Rake::FileList['ext/prism/**/*.{h,c,rb}'] do
  build_dir = File.expand_path('build/prism', __dir__)

  rm_rf build_dir
  cp_r 'ext/prism', build_dir

  sh <<-SH
    cd #{build_dir} && \
    PRISM_FFI_BACKEND=true rake templates
    cd #{build_dir} && \
    make && \
    cd ext/prism && \
    ruby extconf.rb && \
    make -j
  SH
end

file "build/test/support/ffi_stubs.#{SO_EXT}" => 'test/support/ffi_stubs.c' do |t|
  mkdir_p 'build/test/support'
  sh "#{cc} -shared -fPIC -rdynamic -Wl,-undefined,dynamic_lookup -o #{t.name} #{t.source}"
end

task :tidy_internal do
  sh "clang-tidy --warnings-as-errors='*' #{PRIMARY_SOURCES.exclude('src/dtoa.c')}"
end

task :gc_lint_internal do
  sh 'ruby test/gc_lint.rb'
end

task :bundle_install do
  sh 'bundle check || bundle install'
end

task :update_submodules do
  sh 'git submodule update --init --recursive' unless ENV['SKIP_SUBMODULE_UPDATE']
end

def ccache_exists?
  return @ccache_exists if defined?(@ccache_exists)
  @ccache_exists = system('command -v ccache 2>&1 > /dev/null')
end

def cc
  @cc ||=
    if ENV['CC']
      ENV['CC']
    elsif ccache_exists?
      'ccache cc'
    else
      'cc'
    end
end

def cxx
  @cxx ||=
    if ENV['CXX']
      ENV['CXX']
    elsif ccache_exists?
      'ccache c++'
    else
      'c++'
    end
end

def cxx_flags
  base_flags =
    case ENV['BUILD']
    when 'release'
      Natalie::Compiler::Flags::RELEASE_FLAGS
    when 'sanitized'
      Natalie::Compiler::Flags::SANITIZED_FLAGS
    when 'debug', '', nil
      Natalie::Compiler::Flags::DEBUG_FLAGS
    else
      raise "unknown build mode: #{ENV['BUILD']}"
    end
  base_flags + extra_cxx_flags + include_flags
end

def extra_cxx_flags
  flags = ['-fPIC'] # needed for repl
  if RUBY_PLATFORM =~ /darwin/
    # needed for Process.groups to return more than 16 groups on macOS
    flags += ['-D_DARWIN_C_SOURCE']
  end
  flags + Array(ENV['NAT_CXX_FLAGS'])
end

def include_flags
  include_paths.map { |path| "-I #{path}" }
end

def include_paths
  [
    File.expand_path('include', __dir__),
    File.expand_path('ext/tm/include', __dir__),
    File.expand_path('build', __dir__),
    File.expand_path('build/onigmo/include', __dir__),
    File.expand_path('build/prism/include', __dir__),
  ]
end

def current_build_mode
  return DEFAULT_BUILD_MODE unless File.exist?('.build')

  File.read('.build').strip
end

if defined?(SyntaxTree)
  SyntaxTree::Rake::CheckTask.new
  SyntaxTree::Rake::WriteTask.new do |t|
    t.source_files = FileList[%w[Gemfile Rakefile lib/**/*.rb test/**/*.rb bin/natalie examples/**/*.rb]]
    # additional options in .streerc are respected
  end
end
