require_relative '../spec_helper'

describe 'float' do
  it 'transforms high floats to infinity' do
    1e1020.should == Float::INFINITY
    (-1e1020).should == -Float::INFINITY
  end

  describe '#==' do
    it 'compares with bignums' do
      1124000727777607680000.0.should == 1_124_000_727_777_607_680_000
    end
  end

  describe '#**' do
    it 'raises to a power' do
      (2.2**3).should be_close(10.648, TOLERANCE)
    end
  end

  describe '#to_r' do
    it 'returns a rational' do
      2.0.to_r.should == Rational(2, 1)
      2.5.to_r.should == Rational(5, 2)
      -0.75.to_r.should == Rational(-3, 4)
      0.0.to_r.should == Rational(0, 1)
      0.3.to_r.should == Rational(5_404_319_552_844_595, 18_014_398_509_481_984)
    end
  end

  describe 'Float()' do
    ruby_version_is ''...'3.4' do
      it 'cannot parse 10.' do
        -> { Float('10.') }.should raise_error(ArgumentError, 'invalid value for Float(): "10."')
      end

      it 'raises an error for invalid inputs' do
        -> { Float('') }.should raise_error(ArgumentError, 'invalid value for Float(): ""')
        %w[x . 5x 0b1 10e10.5 10__10 10.10__10].each do |input|
          -> { Float(input) }.should raise_error(ArgumentError, "invalid value for Float(): #{input.inspect}")
        end
      end
    end

    ruby_version_is '3.4' do
      it 'can parse 10.' do
        Float('10.').should == 10.0
      end

      it 'raises an error for invalid inputs' do
        -> { Float('') }.should raise_error(ArgumentError, 'invalid value for Float(): ""')
        %w[x . 5x 0b1 10e10.5 10__10 10.10__10].each do |input|
          -> { Float(input) }.should raise_error(ArgumentError, "invalid value for Float(): #{input.inspect}")
        end
      end
    end
  end
end
