module Deep
  module Matchers

    def deep_eql(expected)
      DeepEql.new(expected)
    end

    class DeepEql

      def initialize(expectation)
        @have_diff = false
        begin
          require 'awesome_print'
          require 'awesome_print/core_ext/kernel'
          @have_ap = true
          begin
            require 'diff-lcs'
            @have_diff = true
          rescue Exception
          end
        rescue Exception
          @have_ap = false
        end
        @expectation = expectation
      end

      def matches?(target)
        result = true
        @target = target
        case @expectation
        when Hash
          result &&= @target.is_a?(Hash) && @target.keys.count == @expectation.keys.count
          @expectation.keys.each do |key|
            result &&= @target.has_key?(key) &&
            DeepEql.new(@expectation[key]).matches?(@target[key])
          end
        when Array
          result &&= @target.is_a?(Array) && @target.count == @expectation.count
          @expectation.each_index do |index|
            result &&= DeepEql.new(@expectation[index]).matches?(@target[index])
          end
        else
          result &&= @target == @expectation
        end
        result
      end

      def pretty_print(thing)
        if @have_ap
          thing.awesome_inspect(:plain => true)
        else
          thing.inspect
        end
      end

      def diff_if_available
        return '' unless @have_diff
        # This code is stolen straight from https://github.com/halostatue/diff-lcs/blob/master/lib/diff/lcs/ldiff.rb
        # TODO - Pull out into a method in diff-lcs so that we can just
        #        reuse rather than copy and pasting.
        data_new = pretty_print(@expectation).split("\n")
        data_old = pretty_print(@target).split("\n")
        file_length_difference = 0
        diffs = Diff::LCS.diff(data_old, data_new)
        # Loop over hunks. If a hunk overlaps with the last hunk, join them.
        # Otherwise, print out the old one.
        oldhunk = hunk = nil
        output = []
        diffs.each do |piece|
          begin
            hunk = Diff::LCS::Hunk.new(data_old, data_new, piece, @lines,
                                       file_length_difference)
            file_length_difference = hunk.file_length_difference

            next unless oldhunk
            next if (@lines > 0) and hunk.merge(oldhunk)

            output << oldhunk.diff(:unified) << "\n"
          ensure
            oldhunk = hunk
          end
        end

        output << oldhunk.diff(:unified) << "\n"
        "\nDiff between old and new is:\n#{output.join("")}"
      end

      def failure_message_for_should
        "expected #{pretty_print @target} to be deep_eql with #{pretty_print @expectation}#{diff_if_available}"
      end

      def failure_message_for_should_not
        "expected #{pretty_print @target} not to be in deep_eql with #{pretty_print @expectation}#{diff_if_available}"
      end
    end

  end
end

