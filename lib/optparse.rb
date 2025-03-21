# NOTE: This library is not internally compatible with the optparse library in MRI.
# since the API for OptionParser::Switch is changed. Though, you probably shouldn't
# be using it directly anyway.
class OptionParser
  class Switch
    attr_accessor :short_name, :long_name, :value_label, :value_type, :description, :value

    def initialize(short_name:, long_name:, block:, value_label: nil, description: nil, options: nil)
      @short_name = short_name&.sub(/^-/, '')&.to_sym
      @long_name = long_name&.sub(/^--/, '')&.to_sym
      @value_label = value_label
      @value_type =
        if value_label =~ /^\[.+\]$/
          :optional
        elsif value_label
          :required
        end
      @description = description
      @block = block
      @options = options
    end

    def match?(arg)
      name = arg.split('=', 2).first || ''
      name[0...2] == "-#{short_name}" || name == "--#{long_name}"
    end

    def consume!(args)
      arg = args.shift
      if arg.size > 2 && arg[0] == '-' && arg[1] != '-'
        _arg, @value = arg[0...2], arg[2..]
      else
        _arg, @value = arg.split('=', 2)
      end
      @value = args.shift if @value.nil? && consume_value?(args.first)
      @value = true if @value.nil?
      @block.call(@value) if @block
    end

    COL_SIZE = 33

    def help
      summary = [short_name_formatted, long_name_formatted].compact.join(', ')
      summary << " #{value_label}" if value_label
      out = [summary.ljust(COL_SIZE) + description]
      @options.each { |value, value_description| out << "    #{value}".ljust(COL_SIZE) + value_description } if @options
      out.map { |line| '    ' + line }.join("\n")
    end

    private

    def consume_value?(arg)
      %i[required optional].include?(value_type) && arg !~ /^\-/
    end

    def short_name_formatted
      "-#{short_name}" if short_name
    end

    def long_name_formatted
      "--#{long_name}" if long_name
    end
  end

  class PathChecker
    def initialize(block: nil)
      @block = block
    end

    attr_reader :value

    def match?(arg)
      return false if arg.start_with?('-')

      File.exist?(arg)
    end

    def consume!(args)
      @value = args.shift
      @block.call(@value) if @block
    end

    def long_name
      'path'
    end
    alias short_name long_name

    def help
    end
  end

  def initialize
    parser = self
    @base_switches = [
      Switch.new(
        short_name: '-h',
        long_name: '--help',
        block: ->(*) do
          print parser.help
          exit
        end,
      ),
      Switch.new(
        short_name: '-v',
        long_name: '--version',
        block: ->(*) do
          puts parser.version
          exit
        end,
      ),
    ]
    @switches = []
    @parsing_enabled = true
    yield self if block_given?
  end

  attr_accessor :banner, :program_name
  attr_writer :version

  def on(*args, options: nil, &block)
    short_name, short_value = args.grep(/^\-[^\-]/).first&.split(/[ =]/, 2)
    long_name, long_value = args.grep(/^\-\-/).first&.split(/[ =]/, 2)
    value_label = short_value || long_value
    description = args.grep_v(/^\-/).first
    @switches << Switch.new(
      short_name: short_name,
      long_name: long_name,
      value_label: value_label,
      description: description,
      block: block,
      options: options,
    )
  end

  def on_path(&block)
    @switches << PathChecker.new(block: block)
  end

  def parse(argv = ARGV, into: {})
    parse!(argv.dup, into: into)
  end

  def parse!(argv = ARGV, into: {})
    matched = []
    position_argv = []
    while argv.any? && @parsing_enabled
      if argv.first == '--'
        argv.shift
        position_argv << argv.shift while argv.any?
      elsif (switch = all_switches.detect { |s| s.match?(argv.first) })
        switch.consume!(argv)
        matched << switch
      else
        position_argv << argv.shift
      end
    end
    matched.each { |switch| into[switch.long_name || switch.short_name] = switch.value }
    position_argv.each { |a| argv << a }
    argv
  end

  def stop_parsing!
    @parsing_enabled = false
  end

  def help
    out = [banner]
    @switches.each do |switch|
      text = switch.help
      out << text if text
    end
    out.join("\n") + "\n"
  end

  def version
    "#{@program_name || $0} #{@version || 'unknown'}"
  end

  alias to_s help

  private

  def all_switches
    @base_switches + @switches
  end
end
