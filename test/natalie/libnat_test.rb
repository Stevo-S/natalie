# skip-ruby

require_relative '../spec_helper'

require 'ffi'
require 'tempfile'
require 'natalie/inline'

LIBNAT_PATH = "build/libnat.#{RbConfig::CONFIG['SOEXT']}"
unless File.exist?(LIBNAT_PATH)
  `rake #{LIBNAT_PATH}`
end

module LibNat
  extend FFI::Library
  ffi_lib "build/libnat.#{RbConfig::CONFIG['SOEXT']}"

  attach_function :libnat_init, %i[pointer pointer], :pointer

  def self.init
    env = FFI::Pointer.from_env
    libnat_init(env, FFI::Pointer.new(:pointer, self.object_id))
  end

  def self.parse(code, path)
    parser = Natalie::Parser.new(code, path, locals: [])
    parser.ast
  end

  def self.compile(ast, path, encoding)
    compiler = Natalie::Compiler.new(ast: ast, path: path, encoding: encoding)
    temp = Tempfile.create("natalie.#{RbConfig::CONFIG['SOEXT']}")
    compiler.repl = true # actually this should be called something else ¯\_(ツ)_/¯
    compiler.out_path = temp.path
    compiler.compile
    temp.path
  end
end

describe 'libnat.so' do
  before :all do
    GC.disable
    LibNat.init
  end

  it 'can parse code' do
    ast = LibNat.parse('1 + 2', 'bar.rb')
    ast.should be_an_instance_of(Prism::ProgramNode)
  end

  it 'can compile code' do
    ast = LibNat.parse('1 + 2', 'foo.rb')
    temp_path = LibNat.compile(ast, 'foo.rb', Encoding::UTF_8)

    library = Module.new do
      extend FFI::Library
      ffi_lib(temp_path)
      attach_function :EVAL, [:pointer, :pointer], :int
    end

    env = FFI::Pointer.from_env
    result_memory = FFI::Pointer.new_value
    status = library.EVAL(env, result_memory)
    status.should == 0
    result_memory.to_obj.should == 3
  ensure
    File.unlink(temp_path) if temp_path
  end
end
