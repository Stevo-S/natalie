require_relative './base_instruction'

module Natalie
  class Compiler
    # use:
    # push(new_name)
    # push(old_name)
    # alias
    class AliasGlobalInstruction < BaseInstruction
      def to_s
        'alias_global'
      end

      def generate(transform)
        old_name = transform.pop
        new_name = transform.pop
        transform.exec_and_push(
          :global_alias,
          "env->global_alias(#{new_name}.to_symbol(env, Value::Conversion::Strict), #{old_name}.to_symbol(env, Value::Conversion::Strict))",
        )
      end

      def execute(vm)
        raise 'todo'
      end
    end
  end
end
