# skip-ruby

require_relative '../spec_helper'

describe 'NATFIXME' do
  # Reference expectation check, not testing NATFIXME
  it 'fails spec outside natfixme' do
    a = 5
    -> { a.should == 6 }.should raise_error(SpecFailedException)
  end

  it 'hides a failing block' do
    NATFIXME 'Descriptive message' do
      raise 'fake error which will be hidden'
    end
  end

  it 'hides a failing block with exception' do
    NATFIXME "can't load a missing thing", exception: LoadError do
      load '/tmp/xyzzy.eW91dmVfYmVlbl9lYXRlbl9ieV9hX2dydWUK'
    end
  end

  it 'hides a failing block with exception and message' do
    s = '567879'
    NATFIXME 'Pending String#foo', exception: NoMethodError, message: /method.*foo/ do
      s.foo.should == 'foo567879'
    end
  end

  it 'raises when the block passes' do
    -> do
      NATFIXME 'Pending String#sub' do
        s = '567879'.sub(/9/, '9')
        s.should == '567879'
      end
    end.should raise_error(NatalieFixMeException)
  end

  it 'raises when the block raises but with the wrong exception' do
    -> do
      NATFIXME "can't load a missing thing", exception: ZeroDivisionError do
        load '/tmp/xyzzy.eW91dmVfYmVlbl9lYXRlbl9ieV9hX2dydWUK'
      end
    end.should raise_error(NatalieFixMeException)
  end

  it 'raises when the block raises but with the wrong message' do
    -> do
      NATFIXME "can't load a missing thing", exception: ZeroDivisionError, message: 'divided by ZERO' do
        1 / 0
      end
    end.should raise_error(NatalieFixMeException)
  end

  it 'can be skipped with a condition' do
    x = 0
    NATFIXME 'Division by 0', exception: ZeroDivisionError, condition: x == 0 do
      1 / x
    end

    x = 1
    NATFIXME 'Division by 0', exception: ZeroDivisionError, condition: x == 0 do
      1 / x
    end
  end
end
