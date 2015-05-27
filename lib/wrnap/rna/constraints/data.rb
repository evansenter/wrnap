module Wrnap
  class Rna
    module Constraints
      class Data
        attr_reader :from, :to, :symbol

        def initialize(from, to, symbol)
          @from, @to, @symbol = from, to, symbol
        end

        def render
          symbol * length
        end

        def name
          "(%d to %d as '%s')" % signature
        end

        def signature
          [from, to, symbol]
        end

        def length
          to - from + 1
        end

        def inspect
          "#<Constraint: %s>" % name
        end
      end
    end
  end
end
      