module Natalie
  class Compiler
    module Flags
      RELEASE_FLAGS = %w[
        -pthread
        -O3
        -Wno-unused-value
        -Wno-trigraphs
      ].freeze

      DEBUG_FLAGS = %w[
        -pthread
        -g
        -Wall
        -Wextra
        -Werror
        -Wunused-result
        -Wno-missing-field-initializers
        -Wno-unused-parameter
        -Wno-unused-variable
        -Wno-unused-but-set-variable
        -Wno-unused-value
        -Wno-unknown-warning-option
        -Wno-trigraphs
        -DNAT_GC_GUARD
      ].freeze

      SANITIZE_FLAG = "-fsanitize=#{ENV.fetch('NAT_SANITIZE_FLAG_VALUE', 'address')}".freeze

      SANITIZED_FLAGS = DEBUG_FLAGS + [
        SANITIZE_FLAG,
        '-fno-omit-frame-pointer',
      ] - %w[
        -DNAT_GC_GUARD
      ]

      COVERAGE_FLAGS = DEBUG_FLAGS + %w[
        -fprofile-arcs
        -ftest-coverage
      ].freeze

      LIBNAT_AND_REPL_FLAGS = %w[
        -fPIC
        -shared
        -rdynamic
        -Wl,-undefined,dynamic_lookup
      ].freeze
    end
  end
end
