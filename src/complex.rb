# frozen_string_literal: true

class Complex
  I = Complex(0, 1)

  alias imag imaginary

  def to_i
    imaginary = self.imaginary

    if (imaginary.respond_to?(:to_i) && imaginary.to_i != 0) || imaginary.is_a?(Float)
      raise RangeError, "can't convert #{self.inspect} to Integer"
    end

    self.real.to_i
  end

  def to_f
    imaginary = self.imaginary

    if (imaginary.is_a?(Float) && imaginary == 0.0) || (imaginary.respond_to?(:to_f) && imaginary.to_f != 0.0)
      raise RangeError, "can't convert #{self.inspect} to Float"
    end

    self.real.to_f
  end

  def to_s
    _to_s(:to_s)
  end

  def _to_s(method_name)
    real = self.real
    imaginary = self.imaginary

    s = +""

    if real.respond_to?(:nan?) && real.nan?
      s << "NaN"
    else
      s << real.send(method_name)
    end

    if ! imaginary.negative? && ! imaginary.to_s.include?("-")
      s << "+"
    end

    if imaginary.respond_to?(:nan?) && imaginary.nan?
      if imaginary.negative?
        s << '-'
      end

      s << "NaN"
    elsif ! imaginary.finite?
      if imaginary.negative?
        s << '-'
      end

      s << "Infinity"
    else
      s << imaginary.send(method_name)
    end

    unless ('0'..'9').cover?(s[-1])
      s << '*'
    end

    s << "i"
    s
  end
  private :_to_s

  def finite?
    self.real.finite? && self.imaginary.finite?
  end

  def infinite?
    return 1 if self.real.infinite? || self.imaginary.infinite?
  end

  def +(other)
    if other.is_a?(Complex)
      return Complex(self.real + other.real, self.imaginary + other.imaginary)
    end

    if other.is_a?(Numeric) && other.real?
      return Complex(self.real + other, self.imaginary)
    end

    if other.respond_to?(:coerce)
      first, second = other.coerce(self)
      return first + second
    end
  end

  def -(other)
    if other.is_a?(Complex)
      return Complex(self.real - other.real, self.imaginary - other.imaginary)
    end

    if other.is_a?(Numeric) && other.real?
      return Complex(self.real - other, self.imaginary)
    end

    if other.respond_to?(:coerce)
      first, second = other.coerce(self)
      return first - second
    end
  end

  def /(other)
    # z1 / z2 =  (ac + bd)     (bc - ad)
    #           ----------- + ----------- i
    #           (c^2 + d^2)   (c^2 + d^2)
    if other.is_a?(Complex)
      ac = self.real * other.real
      bd = self.imaginary * other.imaginary
      bc = self.imaginary * other.real
      ad = self.real * other.imaginary
      c2d2 = (other.real ** 2) + (other.imaginary ** 2)

      return Complex((ac + bd) / c2d2, (bc - ad) / c2d2)
    end

    if other.is_a?(Numeric) && other.real?
      real = self.real.quo(other)
      imaginary = self.imaginary.quo(other)
      if other.is_a?(Integer)
        real = real.numerator if real.denominator == 1
        imaginary = imaginary.numerator if imaginary.denominator == 1
      end
      return Complex(real, imaginary)
    end

    if other.respond_to?(:coerce)
      first, second = other.coerce(self)
      result = first.quo(second)
      result = result.numerator if result.denominator == 1
      return result
    end
  end
  alias quo /

  def fdiv(other)
    unless other.is_a?(Numeric)
      raise TypeError, "#{other.class} can't be coerced into #{self.class}"
    end

    return Complex(self.real / other.to_f, self.imaginary / other.to_f)
  end

  def *(other)
    # (a + bi) * (c + di) = (ac - bd) + (ad + bc)i
    if other.is_a?(Complex)
      ac = self.real * other.real
      bd = self.imaginary * other.imaginary
      ad = self.real * other.imaginary
      bc = self.imaginary * other.real

      return Complex(ac - bd, ad + bc)
    end

    if other.is_a?(Numeric) && other.real?
      return Complex(self.real * other, self.imaginary * other)
    end

    if other.respond_to?(:coerce)
      first, second = other.coerce(self)
      return first * second
    end
  end

  def **(n)
    if n.is_a?(Float) && n == 0.0
      return Complex(1.0, 0.0)
    elsif n.is_a?(Integer) && n == 0
      return Complex(1)
    end

    if n.is_a?(Complex)
      r = Math.sqrt(real ** 2 + imaginary ** 2)
      theta = Math.atan2(imaginary, real)
      r_n = Math.exp(n.real * Math.log(r) - n.imaginary * theta)
      theta_n = n.real * theta + n.imaginary * Math.log(r)
      Complex(r_n * Math.cos(theta_n), r_n * Math.sin(theta_n))
    elsif n.is_a?(Float) || n.is_a?(Rational) || (n.is_a?(Integer) && n.negative?)
      r = Math.sqrt(real ** 2 + imaginary ** 2)
      theta = Math.atan2(imaginary, real)
      r_n = r ** n
      theta_n = n * theta
      Complex(r_n * Math.cos(theta_n), r_n * Math.sin(theta_n))
    elsif n.is_a?(Integer)
      # NOTE: this branch is so we don't get floats in the result.
      # If you know a better formula for that, please fix!
      result = Complex(1, 0)
      n.times { result *= self }
      result
    elsif n.respond_to?(:coerce)
      first, second = n.coerce(self)
      return first ** second
    end
  end

  def -@
    Complex(-self.real, -self.imaginary)
  end

  def <=>(other)
    if other.is_a?(Complex)
      if other.imaginary == 0 && self.imaginary == 0
        return self.real <=> other.real
      else
        return nil
      end
    end

    if other.is_a?(Numeric)
      return self.real <=> other
    end
  end

  def eql?(other)
    if ! other.is_a?(Complex)
      return false
    end

    return self.real.class == other.real.class && self.imaginary.class == other.imaginary.class && self == other
  end

  def ==(other)
    if other.is_a?(Complex)
      return self.real == other.real && self.imaginary == other.imaginary
    end

    if ! other.is_a?(Numeric) && ! other.is_a?(Object)
      return false
    end

    if other.respond_to?(:real) && ! other.real?
      return other == self
    end

    if imaginary == 0
      return real == other
    end

    real = self.real
    imaginary = self.imaginary
    other_real = other.real
    other_imaginary = other.imaginary

    return (real == 0 && other_imaginary == 0) && (real == other_real) && (imaginary == other_imaginary)
  end

  def conjugate
    Complex(self.real, -self.imaginary)
  end
  alias conj conjugate

  def abs
    # r = |z| = sqrt(a^2 + b^2).
    Math.sqrt(self.real ** 2 + self.imaginary ** 2)
  end
  alias magnitude abs

  def abs2
    (self.real ** 2) + (self.imaginary ** 2)
  end

  def arg
    # θ = tan^-1(b / a)
    Math.atan2(self.imaginary, self.real)
  end
  alias angle arg
  alias phase arg

  def polar
    # Given z = a + bi, the polar form can be represented as z = r (cosθ + i sinθ)
    # where r = self.abs and θ = self.arg.
    [self.abs, self.arg]
  end

  def self.polar(abs, arg = 0)
    if abs.nil? || arg.nil?
      raise TypeError, "not a real"
    end

    # real = rcosθ
    real = abs * Math.cos(arg)

    # imaginary = rsinθ
    imaginary = abs * Math.sin(arg)

    return Complex(real, imaginary)
  end

  def rect
    self.rectangular
  end

  def rectangular
    return [self.real, self.imaginary]
  end

  def self.rectangular(real, imaginary = 0)
    if ! real.is_a?(Numeric) || ! imaginary.is_a?(Numeric)
      raise TypeError, "not a Numeric"
    end

    if ! real.real? || ! imaginary.real?
      raise TypeError, "not a real"
    end

    Complex(real, imaginary)
  end

  def self.rect(real, imaginary = 0)
    self.rectangular(real, imaginary)
  end

  def to_c
    self
  end

  def real?
    false
  end

  def inspect
    "(#{_to_s(:inspect)})"
  end

  def coerce(other)
    if other.is_a?(Complex)
      return [other, self]
    end

    if other.is_a?(Numeric) && other.real?
      return [Complex(other), self]
    end

    raise TypeError, "#{other.inspect} can't be coerced into Complex"
  end

  def denominator
    self.real.denominator.lcm(self.imag.denominator)
  end

  def numerator
    denominator = self.denominator
    real = self.real.numerator * (denominator / self.real.denominator)
    imag = self.imag.numerator * (denominator / self.imag.denominator)
    Complex(real, imag)
  end

  def to_r
    imaginary = self.imaginary
    if not _exact_zero?(imaginary)
      raise RangeError, "can't convert #{self} into Rational"
    end

    self.real.to_r
  end

  def rationalize(eps=0)
    imaginary = self.imaginary
    if not _exact_zero?(imaginary)
      raise RangeError, "can't convert #{self} into Rational"
    end

    self.real.rationalize eps
  end

  undef :i
  undef :positive?
  undef :negative?

  private
  def marshal_dump
    [self.real, self.imaginary]
  end

  def _zero?(obj)
    if obj.is_a?(Float)
      return obj == 0.0
    elsif obj.is_a?(Integer)
      return obj == 0
    elsif obj.is_a?(Rational)
      return obj.numerator == 0
    else
      return obj == 0
    end
  end

  def _exact_zero?(obj)
    not imaginary.is_a?(Float) and _zero?(imaginary)
  end
end
