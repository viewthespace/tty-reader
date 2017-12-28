# encoding: utf-8
# frozen_string_literal: true

require 'forwardable'

module TTY
  class Reader
    class Line
      extend Forwardable

      def_delegators :@text, :empty?

      # The editable text
      # @api public
      attr_reader :text

      # The current cursor position witin the text
      # @api public
      attr_reader :cursor

      attr_reader :prompt

      def initialize(prompt, text = "")
        @prompt = prompt.dup
        @text   = text.dup
        @cursor = [0, @text.length].max
        yield self if block_given?
      end

      # Check if cursor reached beginning of the line
      #
      # @return [Boolean]
      #
      # @api public
      def start?
        @cursor == 0
      end

      # Check if cursor reached end of the line
      #
      # @return [Boolean]
      #
      # @api public
      def end?
        @cursor == @text.length
      end

      # Move line position to the left by n chars
      #
      # @api public
      def left(n = 1)
        @cursor = [0, @cursor - n].max
      end

      # Move line position to the right by n chars
      #
      # @api public
      def right(n = 1)
        @cursor = [@text.length, @cursor + n].min
      end

      # Move cursor to beginning position
      #
      # @api public
      def move_to_start
        @cursor = 0
      end

      # Move cursor to end position
      #
      # @api public
      def move_to_end
        @cursor = @text.length # put cursor outside of text
      end

      # Insert characters inside a line. When the lines exceeds
      # maximum length, an extra space is added to accomodate index.
      #
      # @param [Integer] i
      #   the index to insert at
      #
      # @example
      #   text = 'aaa'
      #   line[5]= 'b'
      #   => 'aaa  b'
      #
      # @api public
      def []=(i, chars)
        if i.is_a?(Range)
          @text[i] = chars
          @cursor += chars.length
          return
        end

        if i <= 0
          before_text = ''
          after_text = @text.dup
        elsif i == @text.length - 1
          before_text = @text.dup
          after_text = ''
        elsif i > @text.length - 1
          before_text = @text.dup
          after_text = ?\s * (i - @text.length)
          @cursor += after_text.length
        else
          before_text = @text[0..i-1].dup
          after_text  = @text[i..-1].dup
        end

        if i > @text.length - 1
          @text = before_text + after_text + chars
        else
          @text = before_text + chars + after_text
        end

        @cursor = i + chars.length
      end

      # Read character
      #
      # @api public
      def [](i)
        @text[i]
      end

      # Replace current line with new text
      #
      # @param [String] text
      #
      # @api public
      def replace(text)
        @text = text
        @cursor = @text.length # put cursor outside of text
      end

      # Insert char(s) at cursor position
      #
      # @api public
      def insert(chars)
        self[@cursor] = chars
      end

      # Add char and move cursor
      #
      # @api public
      def <<(char)
        @text << char
        @cursor += 1
      end

      # Remove char from the line at current position
      #
      # @api public
      def delete
        @text.slice!(@cursor, 1)
      end

      # Remove char from the line in front of the cursor
      #
      # @api public
      def remove
        left
        @text.slice!(@cursor, 1)
      end

      # Full line with prompt as string
      #
      # @api public
      def to_s
        "#{@prompt}#{@text}"
      end
      alias inspect to_s

      # Prompt size
      #
      # @api public
      def prompt_size
        sanitize(@prompt).size
      end

      # Full line size with prompt
      #
      # @api public
      def size
        prompt_size + @text.size
      end
      alias length size

      private

      ANSI_MATCHER = /(\[)?\033(\[)?[;?\d]*[\dA-Za-z](\])?/

      # Strip ANSI characters from the text
      #
      # @param [String] text
      #
      # @return [String]
      #
      # @api public
      def sanitize(text)
        text.dup.gsub(ANSI_MATCHER, '')
      end
    end # Line
  end # Reader
end # TTY
