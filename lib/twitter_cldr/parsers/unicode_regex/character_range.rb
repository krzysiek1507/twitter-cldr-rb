# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

include TwitterCldr::Utils

module TwitterCldr
  module Parsers
    class UnicodeRegexParser

      # Regex character range eg. a-z or 0-9
      # Can only exist in character classes
      class CharacterRange < Component

        attr_reader :initial, :final

        def initialize(initial, final)
          @initial = initial
          @final = final
        end

        # Unfortunately, due to the ambiguity of having both character
        # ranges and set operations in the same syntax (which both use
        # the "-" operator and square brackets), we have to treat
        # CharacterRange as both a token and an operand. This type method
        # helps it behave like a token.
        def type
          :character_range
        end

        def to_set
          RangeSet.new(
            [initial.to_set.to_full_a.first..final.to_set.to_full_a.first]
          )
        end

      end
    end
  end
end