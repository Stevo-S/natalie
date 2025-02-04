require_relative './base_instruction'
require_relative '../comptime_values'

module Natalie
  class Compiler
    class InlineCppInstruction < BaseInstruction
      include ComptimeValues

      def initialize(exp)
        super()
        @exp = exp
      end

      attr_reader :exp

      def to_s
        "inline_cpp #{exp.name}"
      end

      def generate(transform)
        if exp.is_a?(::Prism::CallNode)
          name = exp.name
          rest = exp.arguments&.arguments || []
        else
          raise "unexpected node passed to InlineCppInstruction: #{exp.inspect}"
        end

        generator = "generate_#{name.to_s.gsub(/__/, '')}"
        send(generator, transform, *rest)
      end

      def execute(_vm)
        raise 'todo'
      end

      private

      def generate_bind_method(transform, ruby_name, cpp_name = ruby_name, arity = -1)
        ruby_name = comptime_symbol(ruby_name)
        cpp_name = comptime_symbol(cpp_name)
        arity = arity.value unless arity.is_a?(Integer)
        transform.exec_and_push(
          :method,
          "Object::define_method(env, self, #{ruby_name.to_s.inspect}_s, #{cpp_name}, #{arity})",
        )
      end

      def generate_bind_static_method(transform, ruby_name, cpp_name = ruby_name, arity = -1)
        ruby_name = comptime_symbol(ruby_name)
        cpp_name = comptime_symbol(cpp_name)
        arity = arity.value unless arity.is_a?(Integer)
        transform.exec_and_push(
          :method,
          "Object::define_method(env, self->klass(), #{ruby_name.to_s.inspect}_s, #{cpp_name}, #{arity})",
        )
      end

      def generate_cxx_flags(transform, flags)
        flags = comptime_string(flags)
        transform.add_cxx_flags(flags)
        transform.push_nil
      end

      def generate_call(transform, fn_name, *args)
        fn_name = comptime_string(fn_name)
        fn = transform.inline_functions.fetch(fn_name)

        cast_value_to_cpp = lambda do |_, type|
          value = transform.pop # Pass1 already did the work to push the value onto the stack
          case type
          when 'double'
            "#{value}->as_float()->to_double()"
          when 'int'
            "#{value}.integer().to_nat_int_t()"
          when 'bool'
            "#{value}.is_truthy()"
          when 'Value'
            value
          else
            raise "I don't yet know how to cast arg type #{type}"
          end
        end

        cast_value_from_cpp = lambda do |value, type|
          case type
          when 'double'
            "Value(new FloatObject { #{value} })"
          when 'Value'
            value
          else
            raise "I don't yet know how to cast return type #{type}"
          end
        end

        casted_args = []

        if fn[:args][0] == 'Env *'
          # Push the env directly. This allows us to omit it from the __call__
          # macro call.
          casted_args << 'env'
        end

        args.each_with_index do |arg, index|
          if fn[:args][0] == 'Env *'
            index += 1
          end

          type = fn[:args][index]
          casted_args << cast_value_to_cpp.(arg, type)
        end

        transform.exec_and_push(
          :call_result,
          cast_value_from_cpp.(
            "#{fn_name}(#{casted_args.join(', ')})",
            fn[:return_type],
          ),
        )
      end

      def generate_constant(transform, name, type, value = name)
        name = comptime_string(name)
        type = comptime_string(type)
        value = comptime_string(value)

        code = case type
               when 'int', 'unsigned short'
                 "Object::const_set(env, self, \"#{name}\"_s, Value::integer(#{value}))"
               when 'bigint'
                 "Object::const_set(env, self, \"#{name}\"_s, IntegerObject::create(Integer(BigInt(#{value}))));"
               else
                 raise "I don't yet know how to handle constant of type #{type.inspect}"
               end

        transform.exec("#ifdef #{value}")
        transform.exec(code)
        transform.exec('#endif')
        transform.push_nil
      end

      def generate_define_method(transform, name, args, body = nil)
        if body.nil?
          body = args
          args = nil
        end
        name = comptime_symbol(name)
        fn = transform.temp("defn_#{name}")
        output = []
        output << "Value #{fn}(Env *env, Value self, Args &&args, Block *block) {"
        if args
          args = args.elements
          output << "args.ensure_argc_is(env, #{args.size});"
          args.each_with_index do |arg, i|
            output << "Value #{comptime_symbol(arg)} = args[#{i}];"
          end
        end
        output << comptime_string(body)
        output << '}'
        transform.top(output)
        transform.exec("self->as_module()->define_method(env, #{transform.intern(name)}, #{fn}, -1)")
        transform.push(transform.intern(name))
      end

      def generate_function(transform, name, args, return_type)
        name = comptime_string(name)
        args = comptime_array_of_strings(args)
        return_type = comptime_string(return_type)
        transform.inline_functions[name] = {
          args: args,
          return_type: return_type,
        }
        transform.push_nil
      end

      def generate_inline(transform, body)
        body = comptime_string(body)
        env = transform.env
        env = env.fetch(:outer) while env[:hoist]
        if env[:outer].nil? || env[:main]
          transform.top body
        else
          transform.exec body
        end
        transform.push_nil
      end

      def generate_internal_inline_code(transform, body)
        body = comptime_string(body)
        transform.top body
        transform.push_nil
      end

      def generate_ld_flags(transform, flags)
        flags = comptime_string(flags)
        transform.add_ld_flags(flags)
        transform.push_nil
      end
    end
  end
end
