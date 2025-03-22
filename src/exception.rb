class NoMemoryError < Exception
end

class ScriptError < Exception
end
class LoadError < ScriptError
end
class NotImplementedError < ScriptError
end
class SyntaxError < ScriptError
end
# end ScriptError subclasses

class SecurityError < Exception
end

class SignalException < Exception
  attr_reader :signo, :signm
  def initialize(signal, message = nil)
    signal = signal.to_s if signal.is_a?(Symbol)
    case signal
    when Integer
      signo, signm = signal, Signal.signame(signal)
      raise ArgumentError, "invalid signal number (#{signo})" if signm.nil?
    when String
      raise ArgumentError, 'wrong number of arguments (given 2, expected 1)' if message
      signal = signal.delete_prefix('SIG')
      signo, signm = Signal.list[signal], signal
      raise ArgumentError, "unsupported signal `SIG#{signal}'" if signo.nil?
    else
      raise ArgumentError, "bad signal type #{signal.class}"
    end

    @signo = signo
    @signm = message || "SIG#{signm}"
    super(@signm)
  end
end
class Interrupt < SignalException
end
# end SignalException subclasses

class StandardError < Exception
end
class ArgumentError < StandardError
end
class UncaughtThrowError < ArgumentError
  attr_reader :tag, :value
  def initialize(tag, value, message = nil)
    super(message)
    @tag = tag
    @value = value
  end
end
# end ArgumentError subclasses
class EncodingError < StandardError
end
class FiberError < StandardError
end
class IndexError < StandardError
end
class StopIteration < IndexError
  attr_reader :result
end
class ClosedQueueError < StopIteration
end
# end StopIteration subclasses
class KeyError < IndexError
  attr_reader :receiver, :key
  def initialize(message = nil, receiver: nil, key: nil)
    super(message)
    @receiver = receiver
    @key = key
  end
end
# end IndexError subclasses

class NameError < StandardError
  attr_reader :name, :receiver
  def initialize(message = nil, name = nil, receiver: nil)
    super(message)
    @name = name
    @receiver = receiver
  end
  def local_variables
    [] # documented as "for internal use only"
  end
end
class NoMethodError < NameError
  attr_reader :args, :private_call?
  def initialize(message = nil, name = nil, args = nil, priv = false, receiver: nil)
    super(message, name, receiver: receiver)
    # Set instance variables on NoMethodError but not NameError
    @args = args
    instance_variable_set('@private_call?', !!priv)
  end
end
# end NameError subclasses

class NoMatchingPatternError < StandardError
end

class IOError < StandardError
end
class EOFError < IOError
end
# end IOError subclasses

class RangeError < StandardError
end
class FloatDomainError < RangeError
end
# end RangeError subclasses

class RegexpError < StandardError
end
class RuntimeError < StandardError
end
class FrozenError < RuntimeError
  attr_reader :receiver
  def initialize(message = nil, receiver: nil)
    super(message)
    @receiver = receiver
  end
end
# end RuntimeError subclasses

class TypeError < StandardError
end
class ZeroDivisionError < StandardError
end

class LocalJumpError < StandardError
  attr_reader :exit_value
end

class ThreadError < StandardError
end
# end StandardError subclasses

class Encoding
  class InvalidByteSequenceError < EncodingError
  end
  class UndefinedConversionError < EncodingError
  end
  class ConverterNotFoundError < EncodingError
  end
  class CompatibilityError < EncodingError
  end
end

class SystemExit < Exception
  def initialize(*args)
    @status = 0
    if args.size == 0
      super()
    elsif args.size == 1
      if args.first.is_a?(Integer)
        super()
        @status = args.first
      elsif args.first.is_a?(TrueClass) || args.first.is_a?(FalseClass)
        super()
        @status = args.first ? 0 : 1
      else
        super(args.first)
      end
    elsif args.size == 2
      if args.first.is_a?(Integer)
        super(args.last)
        @status = args.first
      elsif args.first.is_a?(TrueClass) || args.first.is_a?(FalseClass)
        super(args.last)
        @status = args.first ? 0 : 1
      else
        super(*args)
      end
    else
      raise ArgumentError, "wrong number of arguments (given #{args.size}, expected 0..2)"
    end
  end

  attr_reader :status

  def success?
    @status.zero?
  end
end

class SystemStackError < Exception
end
