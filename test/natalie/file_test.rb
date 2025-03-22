require_relative '../spec_helper'

tmp_path = File.expand_path('../tmp', __dir__)
Dir.mkdir(tmp_path) unless File.exist?(tmp_path)

describe 'File' do
  it 'is an IO object' do
    f = File.new('test/support/file.txt')
    f.should be_kind_of(IO)
    f.close
  end

  it 'raises ENOENT when opening a file that does not exist' do
    -> { File.new('file_does_not_exist.txt') }.should raise_error(Errno::ENOENT)
  end

  describe 'SEPARATOR' do
    it 'is hardcoded to / for now' do
      File::SEPARATOR.should == '/'
    end
  end

  describe '.new' do
    it 'returns the File object' do
      path = File.expand_path('../tmp/file.txt', __dir__)
      file = File.new(path, 'w')
      bytes_written = file.write('hello world')
      file.close
      bytes_written.should == 11
      actual = File.read(path)
      actual.should == 'hello world'
    end

    it 'raises an error when trying to read/write a bad path' do
      -> { File.new('/tmp/should_not_exist/file.txt') }.should raise_error(Errno::ENOENT)
      -> { File.new('/tmp/should_not_exist.txt', 'r') }.should raise_error(Errno::ENOENT)
    end
  end

  describe '.open' do
    it 'without a block it returns the File object' do
      path = File.expand_path('../tmp/file.txt', __dir__)
      file = File.open(path, 'w')
      bytes_written = file.write('hello world')
      file.close
      bytes_written.should == 11
      actual = File.read(path)
      actual.should == 'hello world'
    end

    it 'accepts a block' do
      path = File.expand_path('../tmp/file.txt', __dir__)
      bytes_written = File.open(path, 'w') { |f| f.write('hello world') }
      actual = File.read(path)
      actual.should == 'hello world'
      bytes_written.should == 11
    end

    it 'raises an error when trying to read/write a bad path' do
      -> { File.open('/tmp/should_not_exist/file.txt') }.should raise_error(Errno::ENOENT)
      -> { File.open('/tmp/should_not_exist.txt', 'r') }.should raise_error(Errno::ENOENT)
    end

    it 'closes the file when the block has an exception' do
      path = File.expand_path('../tmp/file.txt', __dir__)
      file = nil
      begin
        File.open(path, 'w') do |f|
          file = f
          f.puts('hello world')
          raise 'some error'
        end
      rescue StandardError
      end
      file.closed?.should == true
    end

    # NOTE: these modes do something on Windows only
    it 'accepts "b" and "t" as a mode modifier' do
      %w[rb r+b rb+ rt r+t rt+].each do |mode|
        file = File.open('test/support/file.txt', mode)
        file.read.should == "foo bar baz\n"
        file.close
      end
      %w[wb w+b wb+ wt w+t wt+].each do |mode|
        file = File.open('test/tmp/file.txt', mode)
        file.write('stuff')
        file.close
      end
      %w[ab a+b ab+ at a+t at+].each do |mode|
        file = File.open('test/tmp/file.txt', mode)
        file.write('stuff')
        file.close
      end
    end

    it 'does not accept "b" and "t" in the wrong position' do
      -> { File.open('test/support/file.txt', 'br') }.should raise_error(ArgumentError, 'invalid access mode br')
      -> { File.open('test/support/file.txt', 'tw') }.should raise_error(ArgumentError, 'invalid access mode tw')
    end
  end

  describe '#read' do
    it 'reads the entire file' do
      f = File.new('test/support/file.txt')
      f.read.should == "foo bar baz\n"
      f.read.should == ''
      f.close
    end

    it 'reads the entire file, even if there are null characters' do
      f = File.new('examples/icon.png')
      content = f.read
      content.bytesize.should == 13_750
    end

    it 'reads specified number of bytes' do
      f = File.new('test/support/file.txt')
      f.read(4).should == 'foo '
      f.read(4).should == 'bar '
      f.read(10).should == "baz\n"
      f.read(4).should be_nil
      f.close
    end

    it 'reads the specified number of bytes, even if there are null characters' do
      f = File.new('examples/icon.png')
      content = f.read(1000)
      content.bytesize.should == 1000
    end
  end

  describe '#write' do
    it 'writes to the file using an integer mode' do
      f = File.new('test/tmp/file_write_test.txt', File::CREAT | File::WRONLY | File::TRUNC)
      f.write('write ')
      f.close
      f = File.new('test/tmp/file_write_test.txt', File::CREAT | File::WRONLY | File::APPEND)
      f.write('append')
      f.close
      f = File.new('test/tmp/file_write_test.txt')
      f.read.should == 'write append'
      f.close
    end

    it 'writes to the file using a string mode' do
      f = File.new('test/tmp/file_write_test.txt', 'w')
      f.write('write ')
      f.close
      f = File.new('test/tmp/file_write_test.txt', 'a')
      f.write('append')
      f.close
      f = File.new('test/tmp/file_write_test.txt')
      f.read.should == 'write append'
      f.close
    end
  end

  describe '#seek' do
    it 'seeks to an absolute position' do
      f = File.new('test/support/file.txt')
      f.seek(4)
      f.seek(4).should == 0
      f.read(3).should == 'bar'
      f.seek(8, :SET)
      f.read(3).should == 'baz'
      f.seek(4, IO::SEEK_SET)
      f.read(3).should == 'bar'
      f.close
    end

    it 'seeks to an offset position from current' do
      f = File.new('test/support/file.txt')
      f.seek(4)
      f.seek(4, :CUR).should == 0
      f.read(3).should == 'baz'
      f.seek(4)
      f.seek(-4, IO::SEEK_CUR)
      f.read(3).should == 'foo'
      f.close
    end

    it 'seeks to an offset position from end' do
      f = File.new('test/support/file.txt')
      f.seek(-4, :END).should == 0
      f.read(3).should == 'baz'
      f.seek(-8, IO::SEEK_END)
      f.read(3).should == 'bar'
      f.close
    end
  end

  describe '#rewind' do
    it 'seeks to the beginning' do
      f = File.new('test/support/file.txt')
      f.read.should == "foo bar baz\n"
      f.rewind
      f.read.should == "foo bar baz\n"
      f.close
    end
  end

  describe '#fileno' do
    it 'returns the file descriptor number' do
      f = File.new('test/support/file.txt')
      f.fileno.should be_kind_of(Integer)
      f.close
    end
  end

  describe '#close' do
    it 'closes the file' do
      f = File.open('test/support/file.txt')
      f.close
      -> { f.close }.should_not raise_error(nil)
      -> { f.read }.should raise_error(IOError, 'closed stream')
    end
  end

  describe '.expand_path' do
    it 'returns the absolute path given a relative one' do
      File.expand_path('test/spec_helper.rb').should =~ %r{^/.*natalie/test/spec_helper\.rb$}
      File.expand_path('/spec_helper.rb').should == '/spec_helper.rb'
      File.expand_path('../spec_helper.rb', __dir__).should =~ %r{^/.*natalie/test/spec_helper\.rb$}
      File.expand_path('..', __dir__).should =~ %r{^/.*natalie/test$}
      File.expand_path('.', __dir__).should =~ %r{^/.*natalie/test/natalie$}
      File.expand_path('/foo/./bar').should == '/foo/bar'
      File.expand_path('/foo/bar/.').should == '/foo/bar'
      File.expand_path('/foo/bar', '/baz').should == '/foo/bar'
    end
  end

  describe '.unlink' do
    it 'deletes the given file path' do
      path = File.expand_path('../tmp/file_to_delete.txt', __dir__)
      File.open(path, 'w') { |f| f.write('hello world') }
      File.unlink(path)
      -> { File.open(path, 'r') }.should raise_error(Errno::ENOENT)
      -> { File.unlink(path) }.should raise_error(Errno::ENOENT)
    end
  end

  describe '.exist?' do
    it 'returns true if the path exists' do
      File.exist?(__dir__).should be_true
      File.exist?(__FILE__).should be_true
      File.exist?('should_not_exist').should be_false
    end
  end

  describe '.dirname' do
    it 'returns the directory of a given path sans filename' do
      File.dirname('foo/bar.txt').should == 'foo'
      File.dirname('/foo/bar/baz.txt').should == '/foo/bar'
      File.dirname('/foo/bar/baz.txt/').should == '/foo/bar'
      File.dirname('/foo/bar/baz').should == '/foo/bar'
      File.dirname('/foo/bar/').should == '/foo'
      File.dirname('/foo/bar/ ').should == '/foo/bar'
      File.dirname('/foo/bar').should == '/foo'
      File.dirname('  /foo/bar').should == '  /foo'
      File.dirname('../foo/bar').should == '../foo'
      File.dirname('../foo/bar/baz.md').should == '../foo/bar'
      File.dirname('   ../foo/bar/baz.md  ').should == '   ../foo/bar'
      File.dirname('').should == '.'
      File.dirname(' ').should == '.'
      File.dirname('/').should == '/'
      File.dirname('/  ').should == '/'
      File.dirname('  /').should == '.'
      File.dirname('  /  ').should == '  '
      File.dirname('./').should == '.'
      File.dirname('./  ').should == '.'
      File.dirname('../').should == '.'
      File.dirname('../  ').should == '..'
      File.dirname('../../').should == '..'
    end
  end

  describe '.chmod' do
    it 'allows a single mode argument and no files' do
      File.chmod(0777).should == 0
    end
  end

  describe '#inspect' do
    it 'should include the filename' do
      f = File.new('test/support/file.txt')
      f.inspect.should.include?('test/support/file.txt')
      f.inspect.should_not.include?('(closed)')

      f2 = File.new(f.fileno)
      f2.autoclose = false
      f2.inspect.should.include?("fd #{f.fileno}")
      f2.inspect.should_not.include?('(closed)')

      f.close
      f.inspect.should.include?('test/support/file.txt')
      f.inspect.should.include?('(closed)')

      f = File.new('test/support/file.txt')
      f.autoclose = false
      f2 = File.new(f.fileno)
      f2.close
      f2.inspect.should_not.include?("fd #{f.fileno}")
      f2.inspect.should.include?('(closed)')
    end
  end

  describe '.lutime' do
    it 'raises an ArgumentError for 1 argument' do
      -> { File.lutime(Time.now) }.should raise_error(ArgumentError, 'wrong number of arguments (given 1, expected 2+)')
    end

    it 'does work with 2 arguments, even though it cannot do anything' do
      File.lutime(Time.now, Time.now).should == 0
    end

    it 'raises a TypeError if any of the first two arguments is not a Time' do
      -> { File.lutime(Time.now, :b) }.should raise_error(TypeError, "can't convert Symbol into time")
      -> { File.lutime(false, Time.now) }.should raise_error(TypeError, "can't convert FalseClass into time")
    end

    it 'does accept nil arguments as time' do
      -> { File.lutime(nil, nil) }.should_not raise_error
    end

    it 'raises an ENOENT if file does not exist' do
      filename = tmp('specs_lutime_file')
      rm_r(filename)
      -> { File.lutime(nil, nil, filename) }.should raise_error(Errno::ENOENT)
    end

    it 'raises a TypeError if the filename is not a String' do
      -> { File.lutime(nil, nil, :foo) }.should raise_error(TypeError, 'no implicit conversion of Symbol into String')
    end

    it 'tries to call #to_str on the filename' do
      filename = tmp('specs_lutime_file')
      touch(filename)
      to_str = mock(:to_str)
      to_str.should_receive(:to_str).and_return(filename)
      File.lutime(nil, nil, to_str)
    ensure
      rm_r(filename)
    end

    it 'raises a TypeError if the result of #to_str is not a String' do
      to_str = mock(:to_str)
      to_str.should_receive(:to_str).and_return(:not_a_string)
      -> { File.lutime(nil, nil, to_str) }.should raise_error(
                   TypeError,
                   "can't convert MockObject to String (MockObject#to_str gives Symbol)",
                 )
    end

    it 'supports multiple file arguments' do
      filename1 = tmp('specs_lutime_file')
      filename2 = tmp('specs_lutime_file2')
      touch(filename1)
      touch(filename2)
      File.lutime(nil, nil, filename1, filename2).should == 2
    ensure
      rm_r(filename1, filename2)
    end
  end
end
