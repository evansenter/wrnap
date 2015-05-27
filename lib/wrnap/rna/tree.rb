module Wrnap
  class Rna
    module Tree
      Autoloaded.module {}

      def trunk(lonely_bp: false)
        Planter.new(self, lonely_bp: lonely_bp)
      end
    end
  end
end
