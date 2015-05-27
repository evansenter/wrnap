module Wrnap
  class Rna
    module Constraints
      Autoloaded.module {}
      
      def constraint_mask
        md[:constraint_mask]
      end

      def show_constraints(&block)
        init_constraint_box(metadata.__rna__).mask
      end

      def build_constraints(&block)
        meta_rna do |metadata|
          set :constraint_mask, init_constraint_box(metadata.__rna__)
        end
      end
    end
  end
end
