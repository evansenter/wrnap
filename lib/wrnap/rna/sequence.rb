module Wrnap
  class Rna
    class Sequence < Bio::Sequence::NA
      include Wrnap::Global::Hashmarks

      def to_s; self; end

      def p
        puts self
      end

      def inspect
      	if length > 0
      		"#<Sequence: %s%s>" % [self[0, 20], length > 20 ? " [%d]" % length : ""]
      	else
        "#<Sequence (empty)>"
        end
      end
    end
  end
end
