module Wrnap
  module Package
    class FoldConstrained < Base
      self.executable_name = "RNAfold"
      self.call_with       = [:seq, :constraint_mask]
      self.default_flags   = {
        :C      => true,
        "--noPS" => :empty
      }

      attr_reader :mfe_rna, :structure, :mfe, :ensemble_energy

      def post_process
        structure = Wrnap::Global::Parser.rnafold_mfe_structure(response)

        unless data.len == structure.length
          raise "Sequence: '#{data.seq}'\nStructure: '#{structure}'"
        else
          @mfe_rna, @structure, @mfe = RNA.from_string(data.seq, structure), structure, Wrnap::Global::Parser.rnafold_mfe(response)
        end
      end
    end
  end
end