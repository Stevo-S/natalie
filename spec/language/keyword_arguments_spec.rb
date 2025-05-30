require_relative '../spec_helper'

describe "Keyword arguments" do
  def target(*args, **kwargs)
    [args, kwargs]
  end

  it "are separated from positional arguments" do
    def m(*args, **kwargs)
      [args, kwargs]
    end

    empty = {}
    m(**empty).should == [[], {}]
    m(empty).should == [[{}], {}]

    m(a: 1).should == [[], {a: 1}]
    m({a: 1}).should == [[{a: 1}], {}]
  end

  it "when the receiving method has not keyword parameters it treats kwargs as positional" do
    def m(*a)
      a
    end

    m(a: 1).should == [{a: 1}]
    m({a: 1}).should == [{a: 1}]
  end

  context "empty kwargs are treated as if they were not passed" do
    it "when calling a method" do
      def m(*a)
        a
      end

      empty = {}
      m(**empty).should == []
      m(empty).should == [{}]
    end

    it "when yielding to a block" do
      def y(*args, **kwargs)
        yield(*args, **kwargs)
      end

      empty = {}
      y(**empty) { |*a| a }.should == []
      y(empty) { |*a| a }.should == [{}]
    end
  end

  it "extra keywords are not allowed without **kwrest" do
    def m(*a, kw:)
      a
    end

    m(kw: 1).should == []
    -> { m(kw: 1, kw2: 2) }.should raise_error(ArgumentError, 'unknown keyword: :kw2')
    -> { m(kw: 1, true => false) }.should raise_error(ArgumentError, 'unknown keyword: true')
    -> { m(kw: 1, a: 1, b: 2, c: 3) }.should raise_error(ArgumentError, 'unknown keywords: :a, :b, :c')
  end

  it "raises ArgumentError exception when required keyword argument is not passed" do
    def m(a:, b:, c:)
      [a, b, c]
    end

    -> { m(a: 1, b: 2) }.should raise_error(ArgumentError, /missing keyword: :c/)
    -> { m() }.should raise_error(ArgumentError, /missing keywords: :a, :b, :c/)
  end

  it "raises ArgumentError for missing keyword arguments even if there are extra ones" do
    def m(a:)
      a
    end

    -> { m(b: 1) }.should raise_error(ArgumentError, /missing keyword: :a/)
  end

  it "handle * and ** at the same call site" do
    def m(*a)
      a
    end

    m(*[], **{}).should == []
    m(*[], 42, **{}).should == [42]
  end

  context "**" do
    ruby_version_is "3.3" do
      it "copies a non-empty Hash for a method taking (*args)" do
        def m(*args)
          args[0]
        end

        h = {a: 1}
        m(**h).should_not.equal?(h)
        h.should == {a: 1}
      end
    end

    it "copies the given Hash for a method taking (**kwargs)" do
      def m(**kw)
        kw
      end

      empty = {}
      m(**empty).should == empty
      m(**empty).should_not.equal?(empty)

      h = {a: 1}
      m(**h).should == h
      m(**h).should_not.equal?(h)
    end
  end

  context "delegation" do
    it "works with (*args, **kwargs)" do
      def m(*args, **kwargs)
        target(*args, **kwargs)
      end

      empty = {}
      m(**empty).should == [[], {}]
      m(empty).should == [[{}], {}]

      m(a: 1).should == [[], {a: 1}]
      m({a: 1}).should == [[{a: 1}], {}]
    end

    it "works with proc { |*args, **kwargs| }" do
      m = proc do |*args, **kwargs|
        target(*args, **kwargs)
      end

      empty = {}
      m.(**empty).should == [[], {}]
      m.(empty).should == [[{}], {}]

      m.(a: 1).should == [[], {a: 1}]
      m.({a: 1}).should == [[{a: 1}], {}]

      # no autosplatting for |*args, **kwargs|
      m.([1, 2]).should == [[[1, 2]], {}]
    end

    it "works with -> (*args, **kwargs) {}" do
      m = -> *args, **kwargs do
        target(*args, **kwargs)
      end

      empty = {}
      m.(**empty).should == [[], {}]
      m.(empty).should == [[{}], {}]

      m.(a: 1).should == [[], {a: 1}]
      m.({a: 1}).should == [[{a: 1}], {}]
    end

    it "works with (...)" do
      instance_eval <<~DEF
      def m(...)
        target(...)
      end
      DEF

      empty = {}
      m(**empty).should == [[], {}]
      m(empty).should == [[{}], {}]

      m(a: 1).should == [[], {a: 1}]
      m({a: 1}).should == [[{a: 1}], {}]
    end

    it "works with call(*ruby2_keyword_args)" do
      class << self
        ruby2_keywords def m(*args)
          target(*args)
        end
      end

      empty = {}
      m(**empty).should == [[], {}]
      Hash.ruby2_keywords_hash?(empty).should == false
      NATFIXME 'it works with call(*ruby2_keyword_args)', exception: SpecFailedException do
        m(empty).should == [[{}], {}]
      end
      Hash.ruby2_keywords_hash?(empty).should == false

      NATFIXME 'it works with call(*ruby2_keyword_args)', exception: SpecFailedException do
        m(a: 1).should == [[], {a: 1}]
        m({a: 1}).should == [[{a: 1}], {}]
      end

      kw = {a: 1}

      NATFIXME 'it works with call(*ruby2_keyword_args)', exception: SpecFailedException do
        m(**kw).should == [[], {a: 1}]
        m(**kw)[1].should == kw
      end
      m(**kw)[1].should_not.equal?(kw)
      Hash.ruby2_keywords_hash?(kw).should == false
      Hash.ruby2_keywords_hash?(m(**kw)[1]).should == false

      NATFIXME 'it works with call(*ruby2_keyword_args)', exception: SpecFailedException do
        m(kw).should == [[{a: 1}], {}]
        m(kw)[0][0].should.equal?(kw)
      end
      Hash.ruby2_keywords_hash?(kw).should == false
    end

    it "works with super(*ruby2_keyword_args)" do
      parent = Class.new do
        def m(*args, **kwargs)
          [args, kwargs]
        end
      end

      child = Class.new(parent) do
        ruby2_keywords def m(*args)
          super(*args)
        end
      end

      obj = child.new

      empty = {}
      NATFIXME 'it works with super(*ruby2_keyword_args)', exception: NoMethodError, message: /no superclass method [`']m'/ do
        obj.m(**empty).should == [[], {}]
        Hash.ruby2_keywords_hash?(empty).should == false
        obj.m(empty).should == [[{}], {}]
        Hash.ruby2_keywords_hash?(empty).should == false

        obj.m(a: 1).should == [[], {a: 1}]
        obj.m({a: 1}).should == [[{a: 1}], {}]

        kw = {a: 1}

        obj.m(**kw).should == [[], {a: 1}]
        obj.m(**kw)[1].should == kw
        obj.m(**kw)[1].should_not.equal?(kw)
        Hash.ruby2_keywords_hash?(kw).should == false
        Hash.ruby2_keywords_hash?(obj.m(**kw)[1]).should == false

        obj.m(kw).should == [[{a: 1}], {}]
        obj.m(kw)[0][0].should.equal?(kw)
        Hash.ruby2_keywords_hash?(kw).should == false
      end
    end

    it "works with zsuper" do
      parent = Class.new do
        def m(*args, **kwargs)
          [args, kwargs]
        end
      end

      child = Class.new(parent) do
        ruby2_keywords def m(*args)
          super
        end
      end

      obj = child.new

      empty = {}
      NATFIXME 'it works with zsuper', exception: NoMethodError, message: /no superclass method [`']m'/ do
        obj.m(**empty).should == [[], {}]
        Hash.ruby2_keywords_hash?(empty).should == false
        obj.m(empty).should == [[{}], {}]
        Hash.ruby2_keywords_hash?(empty).should == false

        obj.m(a: 1).should == [[], {a: 1}]
        obj.m({a: 1}).should == [[{a: 1}], {}]

        kw = {a: 1}

        obj.m(**kw).should == [[], {a: 1}]
        obj.m(**kw)[1].should == kw
        obj.m(**kw)[1].should_not.equal?(kw)
        Hash.ruby2_keywords_hash?(kw).should == false
        Hash.ruby2_keywords_hash?(obj.m(**kw)[1]).should == false

        obj.m(kw).should == [[{a: 1}], {}]
        obj.m(kw)[0][0].should.equal?(kw)
        Hash.ruby2_keywords_hash?(kw).should == false
      end
    end

    it "works with yield(*ruby2_keyword_args)" do
      class << self
        def y(args)
          yield(*args)
        end

        ruby2_keywords def m(*outer_args)
          y(outer_args, &-> *args, **kwargs { target(*args, **kwargs) })
        end
      end

      empty = {}
      m(**empty).should == [[], {}]
      Hash.ruby2_keywords_hash?(empty).should == false
      NATFIXME 'it works with yield(*ruby2_keyword_args)', exception: SpecFailedException do
        m(empty).should == [[{}], {}]
      end
      Hash.ruby2_keywords_hash?(empty).should == false

      NATFIXME 'it works with yield(*ruby2_keyword_args)', exception: SpecFailedException do
        m(a: 1).should == [[], {a: 1}]
        m({a: 1}).should == [[{a: 1}], {}]
      end

      kw = {a: 1}

      NATFIXME 'it works with yield(*ruby2_keyword_args)', exception: SpecFailedException do
        m(**kw).should == [[], {a: 1}]
        m(**kw)[1].should == kw
      end
      m(**kw)[1].should_not.equal?(kw)
      Hash.ruby2_keywords_hash?(kw).should == false
      Hash.ruby2_keywords_hash?(m(**kw)[1]).should == false

      NATFIXME 'it works with yield(*ruby2_keyword_args)', exception: SpecFailedException do
        m(kw).should == [[{a: 1}], {}]
        m(kw)[0][0].should.equal?(kw)
      end
      Hash.ruby2_keywords_hash?(kw).should == false
    end

    it "does not work with (*args)" do
      class << self
        def m(*args)
          target(*args)
        end
      end

      empty = {}
      m(**empty).should == [[], {}]
      m(empty).should == [[{}], {}]

      m(a: 1).should == [[{a: 1}], {}]
      m({a: 1}).should == [[{a: 1}], {}]
    end

    describe "omitted values" do
      it "accepts short notation 'key' for 'key: value' syntax" do
        def m(a:, b:)
          [a, b]
        end

        a = 1
        b = 2

        NATFIXME "accepts short notation 'key' for 'key: value' syntax", exception: SpecFailedException do
          m(a:, b:).should == [1, 2]
        end
      end
    end

    it "does not work with call(*ruby2_keyword_args) with missing ruby2_keywords in between" do
      class << self
        def n(*args) # Note the missing ruby2_keywords here
          target(*args)
        end

        ruby2_keywords def m(*args)
          n(*args)
        end
      end

      empty = {}
      m(**empty).should == [[], {}]
      NATFIXME 'it does not work with call(*ruby2_keyword_args) with missing ruby2_keywords in between', exception: SpecFailedException do
        m(empty).should == [[{}], {}]
      end

      m(a: 1).should == [[{a: 1}], {}]
      NATFIXME 'it does not work with call(*ruby2_keyword_args) with missing ruby2_keywords in between', exception: SpecFailedException do
        m({a: 1}).should == [[{a: 1}], {}]
      end
    end
  end

  context "in define_method(name, &proc)" do
    # This tests that a free-standing proc used in define_method and converted to ruby2_keywords adopts that logic.
    # See jruby/jruby#8119 for a case where aggressive JIT optimization broke later ruby2_keywords changes.
    it "works with ruby2_keywords" do
      m = Class.new do
        def bar(a, foo: nil)
          [a, foo]
        end

        # define_method and ruby2_keywords using send to avoid peephole optimizations
        def self.setup
          pr = make_proc
          send :define_method, :foo, &pr
          send :ruby2_keywords, :foo
        end

        # create proc in isolated method to force jit compilation on some implementations
        def self.make_proc
          proc { |a, *args| bar(a, *args) }
        end
      end

      m.setup

      NATFIXME 'it works with ruby2_keywords', exception: ArgumentError, message: 'wrong number of arguments (given 2, expected 1)' do
        m.new.foo(1, foo:2).should == [1, 2]
      end
    end
  end
end
