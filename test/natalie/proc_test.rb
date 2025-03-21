require_relative '../spec_helper'

describe 'Proc' do
  describe '.new' do
    it 'creates a new Proc object' do
      p = Proc.new { 'hello from proc' }
      p.should be_kind_of(Proc)
    end
  end

  describe 'proc method' do
    it 'creates a new Proc object' do
      p = proc { 'hello from proc' }
      p.should be_kind_of(Proc)
    end
  end

  describe 'lambda method' do
    it 'creates a new Proc object' do
      p = lambda { 'hello from proc' }
      p.should be_kind_of(Proc)
    end

    ruby_version_is ''...'3.3' do
      it 'creates a new Proc object from a block argument' do
        def create_lambda(&block)
          lambda(&block)
        end
        result = suppress_warning { create_lambda { 1 } }
        result.should be_kind_of(Proc)
      end
    end

    ruby_version_is '3.3' do
      it 'cannot create a new Proc object from a block argument' do
        def create_lambda(&block)
          lambda(&block)
        end
        -> { create_lambda { 1 } }.should raise_error(ArgumentError, 'the lambda method requires a literal block')
      end
    end
  end

  describe '-> operator' do
    it 'creates a Proc object' do
      p = -> { 'hello from proc' }
      p.should be_kind_of(Proc)
    end
  end

  describe '#call' do
    it 'evaluates the proc and returns the result' do
      p = Proc.new { 'hello from proc' }
      p.call.should == 'hello from proc'
    end
  end

  describe '#lambda?' do
    it 'returns false if the Proc is not a lambda' do
      p = Proc.new { 'hello from proc' }
      p.lambda?.should == false
      p = proc { 'hello from proc' }
      p.lambda?.should == false
    end

    it 'returns true if the Proc is a lambda' do
      p = -> { 'hello from lambda' }
      p.lambda?.should == true
      p = lambda { 'hello from lambda' }
      p.lambda?.should == true
    end
  end

  describe '#arity' do
    it 'returns the correct number of required arguments' do
      Proc.new {}.arity.should == 0
      Proc.new { |x| }.arity.should == 1
      Proc.new { |x, y = 1| }.arity.should == 1
      Proc.new { |x, y = 1, a:| }.arity.should == 2
      Proc.new { |x, y = 1, a: nil, b:| }.arity.should == 2
      Proc.new { |x, y = 1, a: nil, b: nil| }.arity.should == 1
    end
  end

  describe '#to_proc' do
    it 'returns self' do
      p = Proc.new {}
      p.to_proc.object_id.should == p.object_id
      p.to_proc.lambda?.should == false
      l = -> {}
      l.to_proc.object_id.should == l.object_id # does not convert
      l.to_proc.lambda?.should == true # does not change to false
    end
  end

  describe 'passing a block to a proc' do
    it 'works' do
      block_to_proc = ->(a, b, &block) { block && block.call(a, b) }
      (block_to_proc.call(1, 2) { |a, b| [a * 2, b * 2] }).should == [2, 4]
      block_to_proc.call(1, 2).should == nil
    end
  end
end
