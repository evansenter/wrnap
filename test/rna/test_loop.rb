require "test_helper"

module Wrnap
  class Rna
    class LoopTest < Minitest::Test
      def setup
        @loop = Loop.new(from: 2, to: 7)
      end
      
      def test_equality
        assert_equal Loop.new(from: 2, to: 7), Loop.new(from: 2, to: 7)
      end
      
      def test_in
        assert_equal (2..7).to_a.join, @loop.in((0..9).to_a.join)
      end

      def test_length
        assert_equal 6, @loop.length
      end
    end
  end
end
