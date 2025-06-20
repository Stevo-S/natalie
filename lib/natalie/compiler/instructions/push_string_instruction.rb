require_relative './base_instruction'
require_relative '../string_to_cpp'

module Natalie
  class Compiler
    class PushStringInstruction < BaseInstruction
      include StringToCpp

      def initialize(string, bytesize: string.bytesize, encoding: Encoding::UTF_8, status: nil)
        super()
        @string = string
        @bytesize = bytesize
        @encoding = encoding
        @status = status
      end

      def frozen=(value)
        if value
          @status = :frozen
        elsif @status == :frozen
          @status = nil
        else
          raise ArgumentError, 'unable to determine desired value of status'
        end
      end

      def to_s
        "push_string #{@string.inspect}, #{@bytesize}, #{@encoding.name}#{frozen? ? ', frozen' : ''}#{chilled? ? ', chilled' : ''}"
      end

      def generate(transform)
        if frozen?
          str = transform.interned_string(@string, @encoding)
          transform.push("Value(#{str})")
        else
          enum = @encoding.name.tr('-', '_').upcase
          encoding_object = "EncodingObject::get(Encoding::#{enum})"
          name =
            if @string.empty?
              transform.exec_and_push(:string, "Value(StringObject::create(#{encoding_object}))")
            else
              transform.exec_and_push(
                :string,
                "Value(StringObject::create(#{string_to_cpp(@string)}, (size_t)#{@bytesize}, #{encoding_object}))",
              )
            end
          transform.exec("#{name}.as_string()->set_chilled(StringObject::Chilled::String)") if chilled?
        end
      end

      def execute(vm)
        string = @string.dup.force_encoding(@encoding)
        string.freeze if frozen?
        vm.push(string)
      end

      def serialize(rodata)
        position = rodata.add(@string)
        encoding = rodata.add(@encoding.to_s)

        [instruction_number, position, encoding, frozen? ? 1 : 0].pack('CwwC')
      end

      def self.deserialize(io, rodata)
        string_position = io.read_ber_integer
        encoding_position = io.read_ber_integer
        frozen = io.getbool
        string = rodata.get(string_position, convert: :to_s)
        string = string.dup unless frozen
        encoding = rodata.get(encoding_position, convert: :to_encoding)
        status = :frozen if frozen?
        new(string, bytesize: string.bytesize, encoding: encoding, status:)
      end

      private

      def frozen?
        @status == :frozen
      end

      def chilled?
        @status == :chilled
      end
    end
  end
end
