require "test_helper"

module Wrnap
  class Rna
    class StructureTest < Minitest::Test
      def test_init_from_string
        assert_equal "...(((...)))...", Structure.init_from_string("...(((...)))...").as_string
      end
  
      def test_init_from_dot_bracket
        assert_equal "...(((...)))...", Structure.init_from_dot_bracket("...(((...)))...").as_string
      end
  
      def test_init_from_bp_list
        assert_equal "...(((...)))...", Structure.init_from_bp_list(SortedSet.new([[3, 11], [4, 10], [5, 9]]), 15).as_string
      end
      
      def test_accessors
        base_pairs = SortedSet.new([[3, 11], [4, 10], [5, 9]])
        structure  = Structure.init_from_bp_list(base_pairs, 15)
        
        assert_equal base_pairs, structure.base_pairs
        assert_equal base_pairs, structure.bps
        assert_equal 15,         structure.length
        assert_equal 15,         structure.len
      end
      
      def test_equality
        assert_equal Structure.init_from_dot_bracket("...(((...)))..."), Structure.init_from_bp_list(SortedSet.new([[3, 11], [4, 10], [5, 9]]), 15)
      end
  
      def test_max_bp_distance
        assert_equal 9, Structure.init_from_string(".((((...)))).").max_bp_distance
        assert_equal 8, Structure.init_from_string(".((((...))))").max_bp_distance
        assert_equal 8, Structure.init_from_string("((((...))))").max_bp_distance
      end
  
      def test_loops_and_helices
        expected_structure_motifs = [
          [Loop.new(from: 0, to: 1), Loop.new(from: 4, to: 5), Loop.new(from: 8, to: 9), Loop.new(from: 11, to: 11), Loop.new(from: 13, to: 13)],
          [Helix.new(i: 2, j: 7, length: 2), Helix.new(i: 10, j: 12, length: 1)]
        ]
        
        assert_equal expected_structure_motifs, Structure.init_from_string("..((..))..(.).").loops_and_helices
        assert_equal [
          expected_structure_motifs[0],
          expected_structure_motifs[1].select { |helix| helix.length > 1 }
        ], Structure.init_from_string("..((..))..(.).").loops_and_helices(lonely_bp: false)
      end
    end
  end
end
