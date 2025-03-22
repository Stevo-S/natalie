require_relative '../spec_helper'

describe 'while' do
  it 'works as a pre-condition' do
    r = []
    x = 10
    while x != 0
      r << x
      x = x - 1
    end
    r.should == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  end

  it 'works as a post-condition' do
    r = []
    x = 10
    begin
      r << x
      x = x - 1
    end while x != 0
    r.should == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  end

  it 'works with an assignment in pre-condition' do
    foo = 2
    while (x = foo)
      y = 3
      foo = nil
    end
    x.should == nil
    y.should == 3
  end

  it 'works with an assignment in post-condition' do
    foo = 2
    begin
      y = 3
      foo = nil
    end while (x = foo)
    x.should == nil
    y.should == 3
  end

  it 'returns the value of a break, or nil if no break' do
    x = 1
    result = (break :foo while true)
    result.should == :foo

    x = 1
    result = (x -= 1 while x > 0)
    result.should == nil

    result =
      while false
      end
    result.should == nil
  end
end

describe 'until' do
  it 'works as a pre-condition' do
    r = []
    x = 10
    until x == 0
      r << x
      x = x - 1
    end
    r.should == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  end

  it 'works as a post-condition' do
    r = []
    x = 10
    begin
      r << x
      x = x - 1
    end until x == 0
    r.should == [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
  end

  it 'works with an assignment in pre-condition' do
    y = nil
    foo = 2
    until (x = foo)
      y = 3
    end
    x.should == 2
    y.should == nil
  end

  it 'works with an assignment in post-condition' do
    foo = 2
    begin
      y = 3
    end until (x = foo)
    x.should == 2
    y.should == 3
  end

  it 'returns the value of a break, or nil if no break' do
    x = 1
    result = (break :foo until false)
    result.should == :foo

    x = 1
    result = (x -= 1 until x == 0)
    result.should == nil

    result =
      until true
      end
    result.should == nil
  end
end

describe 'each' do
  it 'can set variables outside the block' do
    x = 0
    [1, 2, 3].each { |i| x = i }
    x.should == 3
  end
end

describe 'for' do
  it 'sets the bound variable outside the scope of the loop' do
    x = 0
    for i in [1, 2, 3]
      x = i
    end
    i.should == 3
    x.should == 3
  end

  it 'can destructure its arguments' do
    results = []
    for a, b in { x: 1, y: 2 }
      results << [a, b]
    end
    results.should == [[:x, 1], [:y, 2]]
    a.should == :y
    b.should == 2

    for a, (b, (c, d)) in [[1, [2, [3, 4]]]]
      results = [a, b, c, d]
    end
    results.should == [1, 2, 3, 4]
  end

  # FIXME: Natalie cannot compile this yet
  #it 'can set all types of variables and constants as index' do
  #  module M; end
  #  ary = [[1, 2, 3, 4, 5, 6, 7]]
  #  for (foo, @foo, @@foo, $foo, Foo, M::Foo, ::Bar) in foo
  #  end
  #  foo.should == 1
  #  @foo.should == 2
  #  @@foo.should == 3
  #  $foo.should == 4
  #  Foo.should == 5
  #  M::Foo.should == 6
  #  ::Bar.should == 7
  #end
end

describe 'loop' do
  it 'can be invoked' do
    s = false
    loop do
      s = true
      break
    end
    s.should == true
  end

  it 'loops' do
    x = 0
    loop do
      x += 1
      break if x > 3
    end
    x.should == 4
  end

  it 'can handle break expr' do
    x = 0
    s =
      loop do
        x += 1
        break 'hello' if x > 3
      end
    s.should == 'hello'
    x.should == 4
  end

  it 'returns an Enumerator when no block is given' do
    x = 0
    e = loop
    e.should be_kind_of(Enumerator)
    e.each do
      x += 1
      break if x > 3
    end
    x.should == 4
  end
end
