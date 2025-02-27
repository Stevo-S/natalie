require 'ffi'
require 'fileutils'
require 'linenoise'
require 'natalie/inline'
require 'tempfile'

LIBNAT_PATH = File.expand_path("../../build/libnat.#{RbConfig::CONFIG['SOEXT']}", __dir__)

unless File.exist?(LIBNAT_PATH)
  puts 'libnat.so not found. Please run `rake bootstrap`.'
  exit 1
end

module LibNat
  extend FFI::Library
  ffi_lib LIBNAT_PATH

  attach_function :libnat_init, %i[pointer pointer], :pointer

  def self.init
    env = FFI::Pointer.from_env
    self_ptr = to_ptr
    libnat_init(env, self_ptr)
  end
end

state_dir = File.join(Dir.home, '.local/state')
if File.directory?(state_dir)
  FileUtils.mkdir_p(File.join(state_dir, 'natalie'))
  HISTORY_PATH = File.join(state_dir, 'natalie/history.txt')
else
  HISTORY_PATH = File.join(Dir.home, '.natalie_history.txt')
end

Linenoise.load_history(HISTORY_PATH)

Linenoise.highlight_callback = lambda do |input|
  tokens = Natalie::Parser.new(input, '(repl)').tokenize.value.map(&:first)
  highlighted = ''
  offset = 0

  tokens.each do |token|
    until offset >= token.location.start_offset
      highlighted << ' '
      offset += 1
    end

    case token.type
    when :INTEGER
      highlighted << "\e[31m#{token.value}\e[0m"
    when /^KEYWORD_/
      highlighted << "\e[32m#{token.value}\e[0m"
    when :FLOAT
      highlighted << "\e[33m#{token.value}\e[0m"
    when :STRING_BEGIN, :STRING_CONTENT, :STRING_END
      highlighted << "\e[34m#{token.value}\e[0m"
    when :IDENTIFIER
      highlighted << "\e[36m#{token.value}\e[0m"
    else
      highlighted << token.value
    end

    offset = token.location.end_offset
  end

  highlighted
end

KEYWORDS = %w[__ENCODING__ __LINE__ __FILE__ BEGIN END alias and begin break case class def defined? do else
              elsif end ensure false for if in module next nil not or redo rescue retry return self super
              then true undef unless until when while yield].freeze

vars = {}
repl_num = 0

Linenoise.completion_callback = lambda do |input|
  tokens = Natalie::Parser.new(input, '(repl)').tokenize.value.map(&:first)
  tokens.pop if tokens.last.type == :EOF
  token = tokens.last
  locals = vars.keys.map(&:to_s)
  completions = []
  if token.type == :IDENTIFIER
    (KEYWORDS + locals).each do |word|
      if word.start_with?(token.value) && word != token.value
        completions << input + word[token.value.length..]
      end
    end
  end
  completions
end

@env = nil
@result_memory = FFI::Pointer.new_value

GC.disable

LibNat.init

loop do
  line = Linenoise.readline('nat> ')
  break if line.nil?

  next if line.strip.empty?

  Linenoise.add_history(line)

  source_path = '(repl)'
  parser = Natalie::Parser.new(line.strip, source_path, locals: vars.keys)
  ast = begin
    parser.ast
  rescue Natalie::Parser::ParseError => e
    puts e.message
    puts e.backtrace
    next
  end

  compiler = Natalie::Compiler.new(ast: ast, path: source_path, encoding: parser.encoding)
  compiler.repl = true
  compiler.repl_num = (repl_num += 1)
  compiler.vars = vars

  temp = Tempfile.create("natalie-repl.#{RbConfig::CONFIG['SOEXT']}")
  compiler.out_path = temp.path

  compiler.compile

  vars = compiler.context[:vars]

  library = Module.new do
    extend FFI::Library
    ffi_lib temp.path
    attach_function :EVAL, [:pointer, :pointer], :int
  end

  @env ||= FFI::Pointer.new_env
  status = library.EVAL(@env, @result_memory)

  if status.zero?
    p @result_memory.to_obj
  end

  File.unlink(temp.path)
end

Linenoise.save_history(HISTORY_PATH)
