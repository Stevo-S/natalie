# frozen_string_literal: true

module Natalie
  class Compiler
    module Transformers
      class MatchRequiredNode
        def call(node)
          case node.pattern.type
          when :array_pattern_node
            transform_array_pattern_node(node.pattern, node.value)
          when :find_pattern_node
            raise SyntaxError, 'FindPatternNode not yet supported'
          when :hash_pattern_node
            raise SyntaxError, 'HashPatternNode not yet supported'
          when :local_variable_target_node
            transform_local_variable_target_node(node.pattern, node.value)
          when :pinned_expression_node
            transform_eqeqeq_check(node.pattern.expression, node.value)
          when :pinned_variable_node
            transform_eqeqeq_check(node.pattern.variable, node.value)
          else
            transform_eqeqeq_check(node.pattern, node.value)
          end
        end

        private

        def transform_array_pattern_node(node, value)
          if (node.requireds + node.posts).any? { |n| n.is_a?(Prism::PinnedExpressionNode) }
            raise SyntaxError, 'PinnedExpressionNode not yet supported'
          end

          # Transform `expr => [a, b] into `a, b = ->(expr) { expr.deconstruct }.call(expr)`
          targets = node.requireds.filter_map { |n| n.name if n.type == :local_variable_target_node }
          expected_size = node.requireds.size + node.posts.size
          expected_size_str = expected_size.to_s
          if node.rest
            targets << :"*#{node.rest.expression&.name}"
            expected_size = "(#{expected_size}..)"
            expected_size_str << '+'
          end
          targets.concat(node.posts.filter_map { |n| n.name if n.type == :local_variable_target_node })
          targets_str =
            if targets.empty? || targets == [:*]
              ''
            elsif targets.size == 1 && !targets.first.start_with?('*')
              "#{targets.first}, * = "
            else
              "#{targets.join(', ')} = "
            end
          const_check = ''
          const_check = <<~RUBY if node.constant
              unless #{node.constant.full_name} === result
                raise ::NoMatchingPatternError, "\#{result}: #{node.constant.full_name} === \#{result} does not return true"
              end
            RUBY
          main_loop_instructions =
            node.requireds.each_with_index.map do |n, i|
              compare_to = n.type == :pinned_variable_node ? n.variable.location.slice : n.location.slice
              if n.type == :local_variable_target_node
                "outputs << values[#{i}]"
              else
                <<~RUBY
                unless #{compare_to} === values[#{i}]
                  compare_to_str = #{n.type == :pinned_variable_node ? "\"\#{#{n.variable.location.slice}}\"" : compare_to}
                  raise ::NoMatchingPatternError, "\#{result}: \#{compare_to_str} === \#{values[#{i}]} does not return true"
                end
              RUBY
              end
            end
          if node.posts.empty?
            main_loop_instructions << "outputs.concat(values.slice(#{node.requireds.size}..))"
          else
            main_loop_instructions << "outputs.concat(values.slice(#{node.requireds.size}...(values.size - #{node.posts.size})))"
            main_loop_instructions +=
              node.posts.each_with_index.map do |n, i|
                compare_to = n.type == :pinned_variable_node ? n.variable.location.slice : n.location.slice
                if n.type == :local_variable_target_node
                  "outputs << values[#{i - node.posts.size}]"
                else
                  <<~RUBY
                  unless #{compare_to} === values[#{i - node.posts.size}]
                  compare_to_str = #{n.type == :pinned_variable_node ? "\"\#{#{n.variable.location.slice}}\"" : compare_to}
                    raise ::NoMatchingPatternError, "\#{result}: \#{compare_to_str} === \#{values[#{i - node.posts.size}]} does not return true"
                  end
                RUBY
                end
              end
          end
          <<~RUBY
            #{targets_str}lambda do |result|
              #{const_check}
              values = result.deconstruct
              outputs = []
              unless #{expected_size} === values.size
                raise ::NoMatchingPatternError, "\#{result}: \#{values} length mismatch (given \#{values.size}, expected #{expected_size_str})"
              end
              #{main_loop_instructions.join("\n")}
              outputs
            rescue NoMethodError
              raise ::NoMatchingPatternError, "\#{result}: \#{result} does not respond to #deconstruct"
            end.call(#{value.location.slice})
          RUBY
        end

        def transform_eqeqeq_check(node, value)
          # Transform `expr => var` into `->(res, var) { res === var }.call(expr, var)`
          alternations = []
          alternation_handler =
            lambda do |n|
              if n.is_a?(Prism::AlternationPatternNode)
                alternation_handler.call(n.left)
                alternation_handler.call(n.right)
              else
                alternations << n.location.slice
              end
            end
          alternation_handler.call(node)
          <<~RUBY
            lambda do |result, expect|
              if expect.none? { |e| e === result }
                raise ::NoMatchingPatternError, "\#{result}: \#{expect.last} === \#{result} does not return true"
              end
            end.call(#{value.location.slice}, [#{alternations.join(', ')}])
          RUBY
        end

        def transform_local_variable_target_node(node, value)
          # Transform `expr => var` into `var = ->(res) { res }.call(expr)`
          <<~RUBY
            #{node.name} = lambda do |result|
              result
            end.call(#{value.location.slice})
          RUBY
        end
      end
    end
  end
end
