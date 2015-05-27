module Wrnap
  class Rna
    module Constraints
      class Mask
        attr_reader :mask

        def initialize(mask)
          @mask = mask
        end

        def from; 0; end
        alias_method :to, def length; mask.length; end
        alias_method :name, def render; mask; end

        def inspect
          "#<FullConstraintMask: %s>" % mask
        end
      end
    end
  end
end
