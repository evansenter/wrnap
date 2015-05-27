module Wrnap
  class Rna
    class StructureWrapper < Virtus::Attribute
      primitive Structure
      
      def coerce(value)
        value.is_a?(String) ? Structure.init_from_dot_bracket(value) : value
      end
    end
  end
end
