describe :time_params, shared: true do
  it "accepts 1 argument (year)" do
    Time.send(@method, 2000).should ==
      Time.send(@method, 2000, 1, 1, 0, 0, 0)
  end

  it "accepts 2 arguments (year, month)" do
    Time.send(@method, 2000, 2).should ==
      Time.send(@method, 2000, 2, 1, 0, 0, 0)
  end

  it "accepts 3 arguments (year, month, day)" do
    Time.send(@method, 2000, 2, 3).should ==
      Time.send(@method, 2000, 2, 3, 0, 0, 0)
  end

  it "accepts 4 arguments (year, month, day, hour)" do
    Time.send(@method, 2000, 2, 3, 4).should ==
      Time.send(@method, 2000, 2, 3, 4, 0, 0)
  end

  it "accepts 5 arguments (year, month, day, hour, minute)" do
    Time.send(@method, 2000, 2, 3, 4, 5).should ==
      Time.send(@method, 2000, 2, 3, 4, 5, 0)
  end

  it "accepts a too big day of the month by going to the next month" do
    Time.send(@method, 1999, 2, 31).should ==
      Time.send(@method, 1999, 3, 3)
  end

  it "raises a TypeError if the year is nil" do
    NATFIXME 'Implement Time.utc', condition: @method == :utc, exception: SpecFailedException, message: /but instead raised nothing/ do
      -> { Time.send(@method, nil) }.should raise_error(TypeError)
    end
  end

  it "accepts nil month, day, hour, minute, and second" do
    Time.send(@method, 2000, nil, nil, nil, nil, nil).should ==
      Time.send(@method, 2000)
  end

  it "handles a String year" do
    Time.send(@method, "2000").should ==
      Time.send(@method, 2000)
  end

  it "coerces the year with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, m).should == Time.send(@method, 1)
  end

  it "handles a String month given as a numeral" do
    Time.send(@method, 2000, "12").should ==
      Time.send(@method, 2000, 12)
  end

  it "handles a String month given as a short month name" do
    Time.send(@method, 2000, "dec").should ==
      Time.send(@method, 2000, 12)
  end

  it "coerces the month with #to_str" do
    (obj = mock('12')).should_receive(:to_str).and_return("12")
    Time.send(@method, 2008, obj).should ==
      Time.send(@method, 2008, 12)
  end

  it "coerces the month with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, m).should == Time.send(@method, 2008, 1)
  end

  it "handles a String day" do
    Time.send(@method, 2000, 12, "15").should ==
      Time.send(@method, 2000, 12, 15)
  end

  it "coerces the day with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, m).should == Time.send(@method, 2008, 1, 1)
  end

  it "handles a String hour" do
    Time.send(@method, 2000, 12, 1, "5").should ==
      Time.send(@method, 2000, 12, 1, 5)
  end

  it "coerces the hour with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, 1, m).should == Time.send(@method, 2008, 1, 1, 1)
  end

  it "handles a String minute" do
    Time.send(@method, 2000, 12, 1, 1, "8").should ==
      Time.send(@method, 2000, 12, 1, 1, 8)
  end

  it "coerces the minute with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, 1, 0, m).should == Time.send(@method, 2008, 1, 1, 0, 1)
  end

  it "handles a String second" do
    Time.send(@method, 2000, 12, 1, 1, 1, "8").should ==
      Time.send(@method, 2000, 12, 1, 1, 1, 8)
  end

  it "coerces the second with #to_int" do
    m = mock(:int)
    m.should_receive(:to_int).and_return(1)
    Time.send(@method, 2008, 1, 1, 0, 0, m).should == Time.send(@method, 2008, 1, 1, 0, 0, 1)
  end

  it "interprets all numerals as base 10" do
    Time.send(@method, "2000", "08", "08", "08", "08", "08").should == Time.send(@method, 2000, 8, 8, 8, 8, 8)
    Time.send(@method, "2000", "09", "09", "09", "09", "09").should == Time.send(@method, 2000, 9, 9, 9, 9, 9)
  end

  it "handles fractional seconds as a Float" do
    t = Time.send(@method, 2000, 1, 1, 20, 15, 1.75)
    t.sec.should == 1
    NATFIXME 'it handles fractional seconds as a Float', condition: @method == :new, exception: SpecFailedException do
      t.usec.should == 750000
    end
  end

  it "handles fractional seconds as a Rational" do
    t = Time.send(@method, 2000, 1, 1, 20, 15, Rational(99, 10))
    t.sec.should == 9
    NATFIXME 'it handles fractional seconds as a Rational', condition: @method == :new, exception: SpecFailedException do
      t.usec.should == 900000
    end
  end

  it "handles years from 0 as such" do
    0.upto(2100) do |year|
      t = Time.send(@method, year)
      t.year.should == year
    end
  end

  it "accepts various year ranges" do
    NATFIXME 'Incorrect result on MacOS', condition: RUBY_PLATFORM.include?('darwin'), exception: SpecFailedException do
      Time.send(@method, 1801, 12, 31, 23, 59, 59).wday.should == 4
    end
    Time.send(@method, 3000, 12, 31, 23, 59, 59).wday.should == 3
  end

  it "raises an ArgumentError for out of range month" do
    # For some reason MRI uses a different message for month in 13-15 and month>=16
    -> {
      Time.send(@method, 2008, 16, 31, 23, 59, 59)
    }.should raise_error(ArgumentError, /(mon|argument) out of range/)
  end

  it "raises an ArgumentError for out of range day" do
    -> {
      Time.send(@method, 2008, 12, 32, 23, 59, 59)
    }.should raise_error(ArgumentError)
  end

  it "raises an ArgumentError for out of range hour" do
    -> {
      Time.send(@method, 2008, 12, 31, 25, 59, 59)
    }.should raise_error(ArgumentError)
  end

  it "raises an ArgumentError for out of range minute" do
    -> {
      Time.send(@method, 2008, 12, 31, 23, 61, 59)
    }.should raise_error(ArgumentError)
  end

  it "raises an ArgumentError for out of range second" do
    # For some reason MRI uses different messages for seconds 61-63 and seconds >= 64
    -> {
      Time.send(@method, 2008, 12, 31, 23, 59, 61)
    }.should raise_error(ArgumentError, /(sec|argument) out of range/)
    -> {
      Time.send(@method, 2008, 12, 31, 23, 59, -1)
    }.should raise_error(ArgumentError, "argument out of range")
  end

  it "raises ArgumentError when given 8 arguments" do
    -> { Time.send(@method, *[0]*8) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError when given 9 arguments" do
    -> { Time.send(@method, *[0]*9) }.should raise_error(ArgumentError)
  end

  it "raises ArgumentError when given 11 arguments" do
    -> { Time.send(@method, *[0]*11) }.should raise_error(ArgumentError)
  end

  it "returns subclass instances" do
    c = Class.new(Time)
    NATFIXME "Implement Time.#{@method}", exception: SpecFailedException do
      c.send(@method, 2008, "12").should be_an_instance_of(c)
    end
  end
end

describe :time_params_10_arg, shared: true do
  it "handles string arguments" do
    NATFIXME "Implement Time.#{@method}", exception: ArgumentError, message: 'wrong number of arguments (given 10, expected 1..7)' do
      Time.send(@method, "1", "15", "20", "1", "1", "2000", :ignored, :ignored,
                :ignored, :ignored).should ==
        Time.send(@method, 1, 15, 20, 1, 1, 2000, :ignored, :ignored, :ignored, :ignored)
    end
  end

  it "handles float arguments" do
    NATFIXME "Implement Time.#{@method}", exception: ArgumentError, message: 'wrong number of arguments (given 10, expected 1..7)' do
      Time.send(@method, 1.0, 15.0, 20.0, 1.0, 1.0, 2000.0, :ignored, :ignored,
                :ignored, :ignored).should ==
        Time.send(@method, 1, 15, 20, 1, 1, 2000, :ignored, :ignored, :ignored, :ignored)
    end
  end

  it "raises an ArgumentError for out of range values" do
    -> {
      Time.send(@method, 61, 59, 23, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
    }.should raise_error(ArgumentError) # sec

    -> {
      Time.send(@method, 59, 61, 23, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
    }.should raise_error(ArgumentError) # min

    -> {
      Time.send(@method, 59, 59, 25, 31, 12, 2008, :ignored, :ignored, :ignored, :ignored)
    }.should raise_error(ArgumentError) # hour

    -> {
      Time.send(@method, 59, 59, 23, 32, 12, 2008, :ignored, :ignored, :ignored, :ignored)
    }.should raise_error(ArgumentError) # day

    -> {
      Time.send(@method, 59, 59, 23, 31, 13, 2008, :ignored, :ignored, :ignored, :ignored)
    }.should raise_error(ArgumentError) # month
  end
end

describe :time_params_microseconds, shared: true do
  it "handles microseconds" do
    t = Time.send(@method, 2000, 1, 1, 20, 15, 1, 123)
    t.usec.should == 123
  end

  it "raises an ArgumentError for out of range microsecond" do
    -> { Time.send(@method, 2000, 1, 1, 20, 15, 1, 1000000) }.should raise_error(ArgumentError)
  end

  it "handles fractional microseconds as a Float" do
    NATFIXME "Implement Time.#{@method}", exception: TypeError, message: "can't convert Float into an exact number" do
      t = Time.send(@method, 2000, 1, 1, 20, 15, 1, 1.75)
      t.usec.should == 1
      t.nsec.should == 1750
    end
  end

  it "handles fractional microseconds as a Rational" do
    t = Time.send(@method, 2000, 1, 1, 20, 15, 1, Rational(99, 10))
    t.usec.should == 9
    t.nsec.should == 9900
  end

  it "ignores fractional seconds if a passed whole number of microseconds" do
    t = Time.send(@method, 2000, 1, 1, 20, 15, 1.75, 2)
    t.sec.should == 1
    t.usec.should == 2
    t.nsec.should == 2000
  end

  it "ignores fractional seconds if a passed fractional number of microseconds" do
    t = Time.send(@method, 2000, 1, 1, 20, 15, 1.75, Rational(99, 10))
    t.sec.should == 1
    t.usec.should == 9
    t.nsec.should == 9900
  end
end
