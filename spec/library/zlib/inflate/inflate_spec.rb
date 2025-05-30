require 'zlib'
require_relative '../../../spec_helper'

describe "Zlib::Inflate#inflate" do

  before :each do
    @inflator = Zlib::Inflate.new
  end
  it "inflates some data" do
    data = [120, 156, 99, 96, 128, 1, 0, 0, 10, 0, 1].pack('C*')
    unzipped = @inflator.inflate data
    @inflator.finish

    unzipped.should == "\000" * 10
  end

  it "inflates lots of data" do
    data = [120, 156, 237, 193, 1, 1, 0, 0] +
           [0, 128, 144, 254, 175, 238, 8, 10] +
           Array.new(31, 0) +
           [24, 128, 0, 0, 1]

    unzipped = @inflator.inflate data.pack('C*')
    @inflator.finish

    unzipped.should == "\000" * 32 * 1024
  end

  it "works in pass-through mode, once finished" do
    data = [120, 156, 99, 96, 128, 1, 0, 0, 10, 0, 1]
    @inflator.inflate data.pack('C*')
    @inflator.finish  # this is a precondition

    NATFIXME 'it works in pass-through mode, once finished', exception: SpecFailedException do
      out = @inflator.inflate('uncompressed_data')
      out << @inflator.finish
      out.should == 'uncompressed_data'

      @inflator << ('uncompressed_data') << nil
      @inflator.finish.should == 'uncompressed_data'
    end
  end

  it "has a binary encoding" do
    data = [120, 156, 99, 96, 128, 1, 0, 0, 10, 0, 1].pack('C*')
    unzipped = @inflator.inflate data
    @inflator.finish.encoding.should == Encoding::BINARY
    unzipped.encoding.should == Encoding::BINARY
  end

end

describe "Zlib::Inflate.inflate" do

  it "inflates some data" do
    data = [120, 156, 99, 96, 128, 1, 0, 0, 10, 0, 1]
    unzipped = Zlib::Inflate.inflate data.pack('C*')

    unzipped.should == "\000" * 10
  end

  it "inflates lots of data" do
    data = [120, 156, 237, 193, 1, 1, 0, 0] +
           [0, 128, 144, 254, 175, 238, 8, 10] +
           Array.new(31,0) +
           [24, 128, 0, 0, 1]

    zipped = Zlib::Inflate.inflate data.pack('C*')

    zipped.should == "\000" * 32 * 1024
  end

  it "properly handles data in chunks" do
    data = [120, 156, 75, 203, 207, 7, 0, 2, 130, 1, 69].pack('C*')
    z = Zlib::Inflate.new
    # add bytes, one by one
    result = +""
    data.each_byte { |d| result << z.inflate(d.chr)}
    result << z.finish
    NATFIXME 'it properly handles data in chunks', exception: SpecFailedException do
      result.should == "foo"
    end
  end

  it "properly handles incomplete data" do
    data = [120, 156, 75, 203, 207, 7, 0, 2, 130, 1, 69].pack('C*')[0,5]
    z = Zlib::Inflate.new
    # add bytes, one by one, but not all
    result = +""
    data.each_byte { |d| result << z.inflate(d.chr)}
    NATFIXME 'it properly handles incomplete data', exception: SpecFailedException do
      -> { result << z.finish }.should raise_error(Zlib::BufError)
    end
  end

  it "properly handles excessive data, byte-by-byte" do
    main_data = [120, 156, 75, 203, 207, 7, 0, 2, 130, 1, 69].pack('C*')
    data =  main_data * 2
    result = +""

    z = Zlib::Inflate.new
    # add bytes, one by one
    data.each_byte { |d| result << z.inflate(d.chr)}
    result << z.finish

    # the first chunk is inflated to its completion,
    # the second chunk is just passed through.
    NATFIXME 'it properly handles excessive data, byte-by-byte', exception: SpecFailedException do
      result.should == "foo" + main_data
    end
  end

  it "properly handles excessive data, in one go" do
    main_data = [120, 156, 75, 203, 207, 7, 0, 2, 130, 1, 69].pack('C*')
    data =  main_data * 2
    result = +""

    z = Zlib::Inflate.new
    result << z.inflate(data)
    result << z.finish

    # the first chunk is inflated to its completion,
    # the second chunk is just passed through.
    NATFIXME 'it properly handles excessive data, in one go', exception: SpecFailedException do
      result.should == "foo" + main_data
    end
  end
end

describe "Zlib::Inflate#inflate" do

  before do
    @zeros    = Zlib::Deflate.deflate("0" * 100_000)
    @inflator = Zlib::Inflate.new
    @chunks   = []
  end

  describe "without break" do

    before do
      @inflator.inflate(@zeros) do |chunk|
        @chunks << chunk
      end
    end

    it "inflates chunked data" do
      NATFIXME 'inflates chunked data', exception: SpecFailedException do
        @chunks.map { |chunk| chunk.size }.should == [16384, 16384, 16384, 16384, 16384, 16384, 1696]
      end
    end

    it "properly handles chunked data" do
      @chunks.all? { |chunk| chunk =~ /\A0+\z/ }.should be_true
    end
  end

  describe "with break" do

    before do
      @inflator.inflate(@zeros) do |chunk|
        @chunks << chunk
        break
      end
    end

    it "inflates chunked break" do
      NATFIXME 'support nil argumen', exception: TypeError do
        output = @inflator.inflate nil
        (100_000 - @chunks.first.length).should == output.length
      end
    end
  end
end
