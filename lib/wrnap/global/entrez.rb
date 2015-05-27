module Wrnap
  module Global
    module Entrez
      class << self
        def sequence_from_entrez(id, position, window)
          Bio::Sequence::NA.new(query_entrez(id, position, window).seq).rna
        end

        private

        def query_entrez(id, position, window)
          Wrnap.debugger { "Retrieving sequence from Entrez: using nuccore DB (id: #{id}, seq_start: #{position + window.min}, seq_stop: #{position + window.max})" }
          Wrnap.debugger { "> True starting position: #{position} with window #{window.min} to #{window.max}" }

          fasta = ::Entrez.EFetch("nuccore", {
            id:        id,
            seq_start: position + window.min,
            seq_stop:  position + window.max,
            retmode:   :fasta,
            rettype:   :text
          })

          Wrnap.debugger { fasta }

          Bio::FastaFormat.new(fasta.response.body)
        end
      end
    end
  end
end
