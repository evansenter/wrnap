module Wrnap
  class Rna    
    class Helix
      include Virtus.value_object(strict: true)

      values do
        attribute :i,      Integer
        attribute :j,      Integer
        attribute :length, Integer
      end
      
      def k; i + length - 1; end
      def l; j - length + 1; end
      
      def in(sequence)
        (0...length).map do |stem_position|
          [sequence[i + stem_position], sequence[j - stem_position]]
        end
      end
      
      def to_loops
        [Loop.new(from: i, to: k), Loop.new(from: l, to: j)]
      end
      
      def apply!(structure)
        structure.tap do
          structure[i, length] = ?( * length
          structure[l, length] = ?) * length
        end
      end
      
      def merge!(helix)
        tap { self.length = helix.k - i + 1 }
      end

      def name
        "(%d..%d, %d..%d [%d])" % [i, k, l, j, length]
      end

      def inspect
        "#<Helix: %s>" % name
      end
    end
  end
end
