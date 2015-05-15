module Wrnap
  class Rna
    module Wrnapper
      def wrnap
        Wrnap::Rna::Box.new(rnas: self)
      end
    end
  end
end
