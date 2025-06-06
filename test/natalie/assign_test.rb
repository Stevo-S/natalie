require_relative '../spec_helper'

class ArrayLike
  def initialize(*values)
    @values = values
  end

  attr_reader :values

  def to_ary
    @values
  end

  def ==(other)
    other.is_a?(ArrayLike) && @values == other.values
  end
end

class BadArrayLike < ArrayLike
  def to_ary
    :bad
  end
end

class NilArrayLike < ArrayLike
  def to_ary
    nil
  end
end

class CanRefIndex
  def initialize(*values)
    @values = values
  end

  attr_reader :values

  def ==(other)
    other.is_a?(CanRefIndex) && @values == other.values
  end

  def [](index)
    @values[index]
  end
end

class AttrAssign
  attr_accessor :foo
end

class MultiAssign
  attr_reader :values

  def []=(x, y, z)
    @values = { x:, y:, z: }
  end
end

module ConstantHolder
end

describe 'assignment' do
  it 'does single assignment' do
    a = 1
    a.should == 1
    [1].each { |b| b.should == 1 }
  end

  it 'does multiple assignment from an array for local variables' do
    a, b = [1, 2]
    a.should == 1
    b.should == 2
    a, b = [3, 4]
    a.should == 3
    b.should == 4
    a, b = [5, 6, 7]
    a.should == 5
    b.should == 6
    a, b, c = [8, 9]
    a.should == 8
    b.should == 9
    c.should == nil
    [[1, 2]].each do |a, b|
      a.should == 1
      b.should == 2
    end
    [[3, 4]].each do |a, b, c|
      a.should == 3
      b.should == 4
      c.should == nil
    end
    a, = [10, 11]
    a.should == 10
  end

  it 'does multiple assignment from an array for constants' do
    A, ConstantHolder::B, ::ConstantHolder::C, ::D = [1, 2, 3, 4]
    A.should == 1
    ConstantHolder::B.should == 2
    ConstantHolder::C.should == 3
    ::D.should == 4
  end

  it 'does multiple assignment from an array for instance variables' do
    @a, @b, @c = [1, 2, 3]
    @a.should == 1
    @b.should == 2
    @c.should == 3
  end

  it 'does multiple assignment from an array for global variables' do
    $a, $b, $c = [1, 2, 3]
    $a.should == 1
    $b.should == 2
    $c.should == 3
  end

  it 'does multiple assignment from an array-like object' do
    a, b = ArrayLike.new(1, 2)
    a.should == 1
    b.should == 2
    a, b = ArrayLike.new(3, 4)
    a.should == 3
    b.should == 4
    a, b = ArrayLike.new(5, 6, 7)
    a.should == 5
    b.should == 6
    a, b, c = ArrayLike.new(8, 9)
    a.should == 8
    b.should == 9
    c.should == nil
    [ArrayLike.new(1, 2)].each do |a, b|
      a.should == 1
      b.should == 2
    end
    [ArrayLike.new(3, 4)].each do |a, b, c|
      a.should == 3
      b.should == 4
      c.should == nil
    end
  end

  it 'does multiple assignment for attributes' do
    h = { foo: 1, bar: 2 }
    h[:foo], h[:bar] = h[:bar], h[:foo]
    h.should == { bar: 1, foo: 2 }
  end

  it 'does not error when an object responds to to_ary but returns nil' do
    bal = NilArrayLike.new(1, 2)
    a, b = bal
    a.should == bal
    b.should == nil
    [bal].each do |a, b, c|
      a.should == bal
      b.should == nil
      c.should == nil
    end
    [bal].each do |(a, b, c)|
      a.should == bal
      b.should == nil
      c.should == nil
    end
  end

  it 'errors when an object responds to to_ary but returns a non-array' do
    if RUBY_PLATFORM == 'ruby'
      bal = BadArrayLike.new(1, 2)
      -> { a, b = bal }.should raise_error(TypeError)
      -> { [bal].each { |a, b, c| } }.should raise_error(TypeError)
      -> { [bal].each { |(a, b, c)| } }.should raise_error(TypeError)
    end
  end

  it 'fills in extra variables with nil when the value is not array-like' do
    o = Object.new
    a, b = o
    a.should == o
    b.should == nil
  end

  it 'does not modify original array on multi assign' do
    ary = [1, 2, 3]
    a, b = ary
    c, d = ary
    a.should == 1
    b.should == 2
    c.should == 1
    d.should == 2

    ary = [0, [4, 5, 6]]
    _, (a, b) = ary
    _, (c, d) = ary
    a.should == 4
    b.should == 5
    c.should == 4
    d.should == 5
  end

  it 'can optionally assign a variable with ||=' do
    a ||= 1
    a.should == 1
    (a ||= 2).should == 1
    a.should == 1
    (a += 1).should == 2
    a.should == 2

    b = nil
    b ||= 2
    b.should == 2
    b ||= 3
    b.should == 2
    b -= 1
    b.should == 1

    c = false
    c ||= 3
    c.should == 3
    c ||= 4
    c.should == 3
    c *= 2
    c.should == 6

    d = true
    d ||= 4
    d.should == true
    d ||= 5
    d.should == true

    def e
      :e
    end

    h = {}
    (h[e] ||= 5).should == 5
    h[e].should == 5
    h[e] ||= 6
    h[e].should == 5
    (h[e] += 1).should == 6
    h[e].should == 6
    h[e] -= 1
    h[e].should == 5
    h[:f] ||= begin
      1
      2
      3
    end
    h[:f].should == 3

    index = h[:e] ||= h.size
    index.should == 5

    (@i ||= 1).should == 1
    @i.should == 1
    (@i ||= 2).should == 1
    @i.should == 1
    (@i &&= 3).should == 3
    @i.should == 3
    @i = nil
    (@i &&= 3).should == nil
    @i.should == nil
    @i = 3
    (@i += 1).should == 4
    @i.should == 4

    ($j ||= 1).should == 1
    $j.should == 1
    ($j ||= 2).should == 1
    $j.should == 1
    ($j &&= 3).should == 3
    $j.should == 3
    $j = nil
    ($j &&= 3).should == nil
    $j.should == nil
    $j = 3
    ($j += 1).should == 4
    $j.should == 4

    class ClassVariableHolder
      def test
        (@@k ||= 1).should == 1
        @@k.should == 1
        (@@k ||= 2).should == 1
        @@k.should == 1
        (@@k &&= 3).should == 3
        @@k.should == 3
        @@k = nil
        (@@k &&= 3).should == nil
        @@k.should == nil
        @@k = 3
        (@@k += 1).should == 4
        @@k.should == 4
      end
    end
    ClassVariableHolder.new.test
  end

  it 'can optionally assign in a when branch' do
    text = nil
    case 1
    when 1
      text ||= 'test'
    end
    text.should == 'test'
  end

  it 'can optionally call an attr writer with ||=' do
    a = AttrAssign.new
    (a.foo ||= 'foo').should == 'foo'
    a.foo.should == 'foo'

    (a.foo ||= 'bar').should == 'foo'
    a.foo.should == 'foo'
  end

  it 'can optionally call an attr writer with &&=' do
    a = AttrAssign.new
    (a.foo &&= 'foo').should == nil
    a.foo.should == nil

    a.foo = 'foo'

    (a.foo &&= 'bar').should == 'bar'
    a.foo.should == 'bar'
  end

  it 'can optionally update a ref with ||=' do
    a = [1]
    (a[0] ||= 'foo').should == 1
    a[0].should == 1

    (a[10] ||= 'bar').should == 'bar'
    a[10].should == 'bar'
  end

  it 'can optionally update a ref with &&=' do
    a = [1]
    (a[0] &&= 'foo').should == 'foo'
    a[0].should == 'foo'

    (a[1] &&= 'bar').should == nil
    a[1].should == nil
  end

  it 'can optionally override a variable with &&=' do
    (a &&= 1).should == nil
    a.should == nil

    b = 1
    (b &&= 2).should == 2
    b.should == 2
  end

  it 'can add to an attr with +=' do
    a = AttrAssign.new
    a.foo = 1
    (a.foo += 2).should == 3
    a.foo.should == 3
  end

  it 'can subtract from an attr with -=' do
    a = AttrAssign.new
    a.foo = 3
    a.foo -= 2
    a.foo.should == 1
  end

  it 'can multiply an attr with *=' do
    a = AttrAssign.new
    a.foo = 2
    a.foo *= 3
    a.foo.should == 6
  end

  it 'can divide an attr with /=' do
    a = AttrAssign.new
    a.foo = 6
    a.foo /= 3
    a.foo.should == 2
  end

  it 'assigns instance variables' do
    @a, b = 1, 2
    @a.should == 1
    b.should == 2
  end

  it 'assigns global variables' do
    a, $b = 1, 2
    a.should == 1
    $b.should == 2
  end

  it 'assigns constants' do
    a, Foo = 1, 2
    a.should == 1
    Foo.should == 2
  end

  it 'does nested multiple assignment from an array' do
    (s, t), u = [[1, 2], 3]
    s.should == 1
    t.should == 2
    u.should == 3
    (a, (b, c)), d, (e, (f, g)) = [[10, 20], 30, [[40, 50], 60]]
    a.should == 10
    b.should == 20
    c.should == nil
    d.should == 30
    e.should == [40, 50]
    f.should == 60
    g.should == nil
    x, y, z = [[4, 5], 6, 7]
    x.should == [4, 5]
    y.should == 6
    z.should == 7
  end

  it 'does nested multiple assignment of instance variables, globals, and constants' do
    (s, @t), ($u, Apple) = [[1, 2], [3, 4]]
    s.should == 1
    @t.should == 2
    $u.should == 3
    Apple.should == 4
  end

  it 'support multiple assignments with splat arrays of multiple arguments' do
    ma1 = MultiAssign.new
    ma2 = MultiAssign.new
    arr = [3, 4]
    ma1[*[1, 2]], ma2[*arr] = :a, :b
    ma1.values.should == { x: 1, y: 2, z: :a }
    ma2.values.should == { x: 3, y: 4, z: :b }
  end

  it 'does not destructure another type of object' do
    one_two = CanRefIndex.new([1, 2])
    one_two_three = CanRefIndex.new([one_two, 3])
    (a, b), c = one_two_three
    a.should == one_two_three
    b.should == nil
    c.should == nil

    one_two = ArrayLike.new([1, 2])
    (s, t), u = ArrayLike.new([one_two, 3])
    s.should == one_two
    t.should == 3
    u.should == nil
  end

  it 'destructures splat variables at the end' do
    (a, *@b), *c = [[1, 2, 3], 4, 5]
    a.should == 1
    @b.should == [2, 3]
    c.should == [4, 5]
  end

  it 'destructures splat variables at the beginning' do
    (*a, b), c = [[1, 2, 3], 4]
    a.should == [1, 2]
    b.should == 3
  end

  it 'destructures splat variables in the middle' do
    (a, *b, c), d = [[1, 2, 3, 4, 5], 6]
    a.should == 1
    b.should == [2, 3, 4]
    c.should == 5
    d.should == 6
  end

  it 'handles nameless splat' do
    a, *, c = [1, 4]
    a.should == 1
    c.should == 4
    a, *, c = [1, 2, 3, 4]
    a.should == 1
    c.should == 4
  end

  it 'captures variables that are in the process of being set' do
    def foo(x)
      x.call
    end

    ran = false

    # x gets captured
    x =
      foo(
        -> do
          ran = true
          x
        end,
      )

    x.should be_nil
    ran.should be_true
  end

  it 'returns the value assigned, even if the setter returns something else' do
    o = Object.new
    def o.foo=(x)
      :bar
    end
    def o.[]=(*args)
      :baz
    end
    (o.foo = 1).should == 1
    (o[:foo] = 2).should == 2
    ary = %w[a b]
    (o[*ary] = 3).should == 3
  end
end
