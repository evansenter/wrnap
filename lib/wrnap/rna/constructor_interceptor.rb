module Wrnap
  class Rna
    module ConstructorInterceptor
      def initialize(*args)
        super
        cast_symbolized_structures
      end

      private

      def cast_symbolized_structures
        self.structures = strs.map do |structure|
          case structure
          when :empty, :empty_str then empty_structure
          when :mfe               then no_str.run(:fold).mfe_rna.structure
          else structure end
        end
      end
    end
  end
end
