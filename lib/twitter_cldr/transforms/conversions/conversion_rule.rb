# encoding: UTF-8

# Copyright 2012 Twitter, Inc
# http://www.apache.org/licenses/LICENSE-2.0

module TwitterCldr
  module Transforms
    module Conversions

      class ConversionRule < Rule
        class << self
          include TwitterCldr::Tokenizers

          def parse(rule_text, symbol_table, index)
            options = {
              original_rule_text: rule_text,
              index: index
            }

            tokens = tokenize(rule_text, symbol_table)
            parser.parse(tokens, options)
          end

          private

          def tokenize(rule_text, symbol_table)
            cleaned_rule_text = remove_comment(rule_text)
            tokens = tokenizer.tokenize(cleaned_rule_text)
            # tokens = preprocess_tokens(tokens)
            replace_symbols(tokens, symbol_table)
          end

          def remove_comment(rule_text)
            # comment must come after semicolon
            if rule_idx = rule_text.index(/;[ ]*#/)
              rule_text[0..rule_idx]
            else
              rule_text
            end
          end

          # Warning: not thread-safe
          def parser
            @parser ||= Parser.new
          end

          def tokenizer
            @tokenizer ||= TwitterCldr::Transforms::Tokenizer.new
          end
        end

        attr_reader :direction, :left, :right
        attr_reader :original_rule_text, :index

        def initialize(direction, left, right, original_rule_text, index)
          @direction = direction
          @left = left
          @right = right
          @original_rule_text = original_rule_text
          @index = index
        end

        def can_invert?
          direction == :bidirectional || direction == :backward
        end

        def forward?
          direction == :bidirectional || direction == :forward
        end

        def backward?
          direction == :backward
        end

        def is_conversion_rule?
          true
        end

        def invert
          if can_invert?
            case direction
              when :backward
                self.class.new(
                  :forward, left, right, original_rule_text, index
                )
              else
                self.class.new(
                  direction, right, left, original_rule_text, index
                )
            end
          else
            raise NotInvertibleError,
              "cannot invert this #{self.class.name}"
          end
        end

        def codepoints
          left.codepoints
        end

        def has_codepoints?
          left.has_codepoints?
        end

        def match(cursor)
          left.match(cursor)
        end

        def original
          @original ||= begin
            key = left.key.inject('') do |ret, token|
              ret + (token.type == :capture ? '' : token.value)
            end

            left.before_context + key + left.after_context
          end
        end

        def replacement_for(side_match)
          right.key.inject('') do |ret, token|
            ret + case token.type
              when :capture
                idx = token.value[1..-1].to_i - 1
                side_match.captures[idx]
              else
                token_value(token)
            end
          end
        end

        def cursor_offset
          right.cursor_offset
        end
      end

    end
  end
end