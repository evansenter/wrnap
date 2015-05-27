module Wrnap
  module Package
    class Fold < Base
      self.executable_name = "RNAfold"
      self.default_flags   = {
        "--noPS" => :empty
      }

      attr_reader :mfe_rna, :structure, :mfe, :ensemble_energy

      def post_process
        structure = Wrnap::Global::Parser.rnafold_mfe_structure(response)

        unless data.len == structure.length
          raise "Sequence: '#{data.seq}'\nStructure: '#{structure}'"
        else
          @mfe_rna   = Wrnap::Rna.init_from_string(data.seq, structure)
          @structure = Wrnap::Rna::Structure.init_from_dot_bracket(structure)
          @mfe       = Wrnap::Global::Parser.rnafold_mfe(response)
        end

        if flags[:p] == 0
          @ensemble_energy = Wrnap::Global::Parser.rnafold_ensemble_energy(response)
        end
      end
    end
  end
end
