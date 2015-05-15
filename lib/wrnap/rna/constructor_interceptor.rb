module Wrnap
  class Rna
    module ConstructorInterceptor
      def initialize(*args, &block)
        super
        cast_symbolized_structures
        instance_eval(&block) if block_given?
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
