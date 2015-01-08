module Wrnap
  class Rna
    class Sequence < Bio::Sequence::NA
      def inspect
        "#<Sequence: %s>" % (self[0, 20] + (length > 20 ? " [%d]" % length : ""))
      end      
    end
  end
end
