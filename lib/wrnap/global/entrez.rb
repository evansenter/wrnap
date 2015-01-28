module Wrnap
  module Global
    module Entrez
      class << self
        # def simple_rna_sequence(id, from, to)
        #   sequence = rna_sequence_from_entrez(id, [from, to].min, 0..((to - from).abs))
        #
        #   to < from ? sequence.complement : sequence
        # end

        def rna_sequence_from_entrez(id, position, window, buffer_size = 0)
          na_sequence_from_entrez(id, position, window, buffer_size)
        end
        
        private

        def na_sequence_from_entrez(id, position, window, buffer_size = 0)
          Bio::Sequence::NA.new(sequence_from_entrez(id, position, Range.new(window.min - buffer_size, window.max + buffer_size)).seq)
        end

        def sequence_from_entrez(id, position, window)
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
