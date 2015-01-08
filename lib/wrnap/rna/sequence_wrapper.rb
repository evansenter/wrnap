module Wrnap
  class Rna
    class SequenceWrapper < Virtus::Attribute
      primitive Sequence
      
      def coerce(value)
        value.is_a?(String) ? Sequence.new(value) : value
      end
    end
  end
end
