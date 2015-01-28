module Wrnap
  class Rna
    class Sequence < Bio::Sequence::NA
      def to_s; self; end
      
      def inspect
        "#<Sequence: %s%s>" % [self[0, 20], length > 20 ? " [%d]" % length : ""]
      end      
    end
  end
end
