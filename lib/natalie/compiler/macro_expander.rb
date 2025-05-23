module Natalie
  class Compiler
    class MacroExpander
      include ComptimeValues

      class MacroError < StandardError
      end
      class LoadPathMacroError < MacroError
      end

      def initialize(load_path:, interpret:, compiler_context:, log_load_error:)
        @load_path = load_path
        @interpret = interpret
        @compiler_context = compiler_context
        @inline_cpp_enabled = @compiler_context[:inline_cpp_enabled]
        @log_load_error = log_load_error
        @required_ruby_files = @compiler_context[:required_ruby_files]
      end

      attr_reader :node, :load_path, :depth

      # Eval-like calls that can take a static string or a block
      EVALISH_STRING_TO_BLOCK = %i[class_eval instance_eval module_eval].freeze

      MACROS = %i[
        autoload
        eval
        include_str!
        load
        nat_ignore_require
        nat_ignore_require_relative
        require
        require_relative
      ].concat(EVALISH_STRING_TO_BLOCK).freeze

      def expand(call_node, locals:, depth:, file:)
        if (macro_name = get_macro_name(call_node))
          run_macro(macro_name, call_node, current_path: file.path, locals: locals, depth: depth)
        else
          call_node
        end
      end

      private

      def get_macro_name(node)
        if node.type == :call_node && node.receiver.nil?
          if EVALISH_STRING_TO_BLOCK.include?(node.name)
            :evalish_string_to_block
          elsif MACROS.include?(node.name)
            node.name
          elsif @macros_enabled
            if node.name == :macro!
              node.name
            elsif @macros.key?(node.name)
              :user_macro
            end
          end
        else
          get_hidden_macro_name(node)
        end
      end

      # "Hidden macros" are just regular-looking Ruby code we intercept at compile-time.
      # We will try to support common Ruby idioms here that cannot be done at runtime.
      def get_hidden_macro_name(node)
        if node.type == :call_node && node.receiver&.type == :global_variable_read_node &&
             %i[$LOAD_PATH $:].include?(node.receiver.name) && %i[<< unshift].include?(node.name)
          :update_load_path
        elsif node.type == :call_node && EVALISH_STRING_TO_BLOCK.include?(node.name) && node.block.nil? &&
              node.arguments&.arguments&.size == 1 && compile_time_string?(node.arguments.arguments.first)
          :evalish_string_to_block
        end
      end

      def run_macro(macro_name, expr, current_path:, locals:, depth:)
        send("macro_#{macro_name}", expr: expr, current_path: current_path, locals: locals, depth: depth)
      end

      def macro_user_macro(expr:, **)
        _, _, name = expr
        macro = @macros[name]
        VM.compile_and_run(macro, path: 'macro')
      end

      def macro_macro!(expr:, **)
        _, call, _, block = expr
        _, name = call.last
        @macros[name] = block
        nothing(expr)
      end

      EXTENSIONS_TO_TRY = ['.rb', '.cpp', ''].freeze

      def macro_autoload(expr:, current_path:, **)
        args = expr.arguments&.arguments || []
        const_node, path_node = args
        const = comptime_symbol(const_node, path: current_path)
        begin
          path = comptime_string(path_node, path: current_path)
        rescue ArgumentError
          return(
            drop_load_error(
              "cannot load such file #{path_node.inspect} at #{current_path}##{expr.location.start_line}",
              location: expr.location,
            )
          )
        end

        full_path =
          EXTENSIONS_TO_TRY.lazy.filter_map { |ext| find_full_path(path + ext, base: Dir.pwd, search: true) }.first

        unless full_path
          return(
            drop_load_error(
              "cannot load such file #{path} at #{current_path}##{expr.location.start_line}",
              location: expr.location,
            )
          )
        end

        body = load_file(full_path, require_once: true, location: location(expr))
        [:autoload_const, const, path, body]
      end

      def macro_require(expr:, current_path:, **)
        args = expr.arguments&.arguments || []
        name = comptime_string(args.first, path: current_path)
        return nothing(expr) if name == 'tempfile' && interpret? # FIXME: not sure how to handle this actually
        if name == 'natalie/inline'
          @inline_cpp_enabled[current_path] = true
          return nothing(expr)
        end
        EXTENSIONS_TO_TRY.each do |extension|
          if (full_path = find_full_path(name + extension, base: Dir.pwd, search: true))
            return load_file(full_path, require_once: true, location: location(expr))
          end
        end
        drop_load_error(
          "cannot load such file #{name} at #{current_path}##{expr.location.start_line}",
          location: expr.location,
        )
      end

      def macro_require_relative(expr:, current_path:, **)
        args = expr.arguments&.arguments || []
        name = comptime_string(args.first, path: current_path)
        base = File.dirname(current_path)
        EXTENSIONS_TO_TRY.each do |extension|
          if (full_path = find_full_path(name + extension, base: base, search: false))
            lf = load_file(full_path, require_once: true, location: location(expr))
            return lf
          end
        end
        drop_load_error(
          "cannot load such file #{name} at #{current_path}##{expr.location.start_line}",
          location: expr.location,
        )
      end

      def macro_load(expr:, current_path:, **)
        args = expr.arguments&.arguments || []
        path = comptime_string(args.first, path: current_path)
        full_path = find_full_path(path, base: Dir.pwd, search: true)
        return load_file(full_path, require_once: false, location: location(expr)) if full_path
        drop_load_error("cannot load such file -- #{path}", location: expr.location)
      end

      def macro_eval(expr:, current_path:, locals:, **)
        args = expr.arguments&.arguments || []
        node = args.first
        $stderr.puts 'FIXME: binding passed to eval() will be ignored.' if args.size > 1
        if compile_time_string?(node)
          begin
            result = Natalie::Parser.new(string_node_to_string(node), current_path, locals: locals)
            if result.warnings.empty?
              result.ast
            else
              [:compile_time_warning, result.warnings, "(eval at #{current_path}:#{node.start_line})", result.ast]
            end
          rescue Parser::ParseError => e
            drop_error(:SyntaxError, e.message, location: node.location)
          end
        else
          drop_error(:TypeError, 'eval() only works on static strings', location: node.location)
        end
      end

      def macro_nat_ignore_require(expr:, current_path:)
        Prism.false_node(location: nil) # Script has not been loaded
      end

      def macro_nat_ignore_require_relative(expr:, current_path:)
        Prism.false_node(location: nil) # Script has not been loaded
      end

      def macro_include_str!(expr:, current_path:, **)
        args = expr.arguments&.arguments || []
        name = comptime_string(args.first, path: current_path)
        if (full_path = find_full_path(name, base: File.dirname(current_path), search: false))
          Prism.string_node(unescaped: File.read(full_path), location: expr)
        else
          raise IOError, "cannot find file #{name} at #{current_path}##{node.location.start_line}"
        end
      end

      # $LOAD_PATH << some_expression
      # $LOAD_PATH.unshift(some_expression)
      def macro_update_load_path(expr:, current_path:, depth:, **)
        if depth > 1
          if expr.is_a?(::Prism::Node)
            name = expr.receiver.name
          else
            name = expr.receiver[1] # receiver is $(gvar, :$LOAD_PATH)
          end
          return(
            drop_error(
              :LoadError,
              "Cannot manipulate #{name} at runtime (#{current_path}##{expr.location.start_line})",
              location: expr.location,
            )
          )
        end

        path_to_add =
          VM.compile_and_run(
            ::Prism::StatementsNode.new(nil, nil, location(expr), 0, expr.arguments&.arguments),
            path: current_path,
          )

        unless path_to_add.is_a?(String) && File.directory?(path_to_add)
          raise LoadPathMacroError, "#{path_to_add.inspect} is not a directory"
        end

        load_path << path_to_add
        Prism.nil_node(location: expr.location)
      end

      def macro_evalish_string_to_block(expr:, current_path:, depth:, locals:, **)
        return expr unless compile_time_string?(expr.arguments&.child_nodes&.first)

        result = Natalie::Parser.new(string_node_to_string(expr.arguments.child_nodes.first), current_path, locals:)
        block =
          Prism::BlockNode.new(
            result.ast.child_nodes.first,
            nil,
            expr.arguments.location,
            0,
            nil,
            nil,
            result.ast.statements,
            expr.arguments.child_nodes.first.opening_loc,
            expr.arguments.child_nodes.first.closing_loc,
          )
        output = expr.copy(arguments: nil, block:)
        output = [
          :compile_time_warning,
          result.warnings,
          "(eval at #{current_path}:#{expr.start_line})",
          output,
        ] unless result.warnings.empty?
        output
      rescue Parser::ParseError => e
        drop_error(:SyntaxError, e.message, location: expr.location)
      end

      def interpret?
        !!@interpret
      end

      def find_full_path(path, base:, search:)
        if path.start_with?(File::SEPARATOR)
          path if File.file?(path)
        elsif path.start_with?('.' + File::SEPARATOR)
          path = File.expand_path(path, base)
          path if File.file?(path)
        elsif search
          find_file_in_load_path(path)
        else
          path = File.expand_path(path, base)
          path if File.file?(path)
        end
      end

      def find_file_in_load_path(path)
        load_path.map { |d| File.expand_path(File.join(d, path)) }.detect { |p| File.file?(p) }
      end

      def load_file(path, require_once:, location:)
        return load_cpp_file(path, require_once: require_once, location: location) if path =~ /\.cpp$/

        raise "Expected an absolute path, but got: #{path.inspect}" unless File.absolute_path?(path)

        unless @required_ruby_files[path]
          code = File.read(path)
          parser = Natalie::Parser.new(code, path)
          @required_ruby_files[path] = LoadedFile.new(path: path, ast: parser.ast, encoding: parser.encoding)
        end

        [:load_file, path, require_once]
      end

      def load_cpp_file(path, require_once:, location:)
        name = File.split(path).last.split('.').first
        return Prism.false_node(location: nil) if @compiler_context[:required_cpp_files][path]
        @compiler_context[:required_cpp_files][path] = name
        cpp_source = File.read(path)
        init_function = "Value init_#{name}(Env *env, Value self)"
        unless cpp_source.include?(init_function)
          puts "Expected #{path} to contain function: `#{init_function}`"
          raise CompileError, "could not load #{name}"
        end
        ::Prism::StatementsNode.new(
          nil,
          nil,
          location,
          0,
          [
            Prism.call_node(
              receiver: nil,
              name: :__internal_inline_code__,
              arguments: [Prism.string_node(unescaped: "#include \"#{File.absolute_path(path)}\"", location: location)],
              location: location,
            ),
            ::Prism.true_node(location: location),
          ],
        )
      end

      def drop_error(exception_class, message, location:, print_warning: false)
        warn(message) if print_warning
        Prism.call_node(
          receiver: nil,
          name: :raise,
          arguments: [
            Prism.constant_read_node(name: exception_class, location: location),
            Prism.string_node(unescaped: message, location: location),
          ],
          location: location,
        )
      end

      def drop_load_error(message, location:)
        drop_error(:LoadError, message, print_warning: @log_load_error, location: location)
      end

      def nothing(expr)
        ::Prism::StatementsNode.new(nil, nil, location(expr), 0, [])
      end

      def location(expr)
        case expr
        when ::Prism::Node
          expr.location
        else
          raise "unknown node type: #{expr.inspect}"
        end
      end

      def compile_time_string?(expr)
        expr&.type == :string_node ||
          expr&.type == :interpolated_string_node && expr.parts.all? { |subexpr| subexpr.type == :string_node }
      end

      def string_node_to_string(expr)
        case expr.type
        when :string_node
          return expr.unescaped
        when :interpolated_string_node
          return expr.parts.map(&:unescaped).join if expr.parts.all? { |subexpr| subexpr.type == :string_node }
        end
        raise "Not a compile time string: #{expr.location.slice}"
      end
    end
  end
end
