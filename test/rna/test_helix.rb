require "test_helper"

module Wrnap
  class Rna
    class HelixTest < Minitest::Test
      def setup
        @helix = Helix.new(i: 0, j: 9, length: 2)
      end

      def test_equality
        assert_equal(Helix.new(i: 0, j: 9, length: 2), Helix.new(i: 0, j: 9, length: 2))
      end

      def test_in
        assert_equal([%w|0 9|, %w|1 8|], @helix.in((0..9).to_a.join))
      end

      def test_to_loops
        assert_equal([
          Loop.new(from: @helix.i, to: @helix.i + @helix.length - 1),
          Loop.new(from: @helix.j - @helix.length + 1, to: @helix.j)
        ], @helix.to_loops)
      end

      def test_apply!
        assert_equal("((......))", @helix.apply!(?. * 10))
      end

      def test_merge!
        inner_helix = Helix.new(i: 3, j: 6, length: 2)
        assert_equal(Helix.new(i: 0, j: 9, length: 5), @helix.merge!(inner_helix))
      end
    end
  end
end
