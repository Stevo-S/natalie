require_relative './base_instruction'

module Natalie
  class Compiler
    class AutoloadConstInstruction < BaseInstruction
      def initialize(name:, path:)
        @name = name
        @path = path
      end

      def has_body?
        true
      end

      def to_s
        "autoload_const #{@name}, #{@path.inspect}"
      end

      def generate(transform)
        body = transform.fetch_block_of_instructions(expected_label: :autoload_const)
        fn = transform.temp("autoload_const_#{@name}_fn")
        transform.with_new_scope(body) do |t|
          fn_code = []
          fn_code << "Value #{fn}(Env *env, Value self, Args &&args = {}, Block *block = nullptr) {"
          fn_code << t.transform('return')
          fn_code << '}'
          transform.top(fn_code)
        end
        transform.exec("Object::const_set(self, #{transform.intern(@name)}, #{fn}, new StringObject(#{@path.inspect}))")
        transform.push_nil
      end

      def execute(vm)
        raise 'todo'
      end
    end
  end
end
