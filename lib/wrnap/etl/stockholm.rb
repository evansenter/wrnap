module Wrnap
  module Etl
    module Stockholm
      class << self
        def load_all(file)
          entries   = Bio::Stockholm::Reader.parse_from_file(file)[0]
          sequences = entries.records.map(&:last).map(&:sequence)
          structure = dot_bracket_from_stockholm(entries.gc_features["SS_cons"])

          sequences.map { |sequence| fit_structure_to_sequence(sequence, structure) }
        end

        def dot_bracket_from_stockholm(structure)
          structure.gsub(/</, ?().gsub(/>/, ?))
        end

        def fit_structure_to_sequence(sequence, consensus_structure)
          theta_filter(prune_gaps(balanced_consensus_from_sequence(sequence, consensus_structure)))
        end

        def balanced_consensus_from_sequence(sequence, structure)
          Wrnap::Rna.init_from_string(
            sequence,
            Wrnap::Rna.structure_from_bp_list(
              sequence.length,
              sequence.split(//).zip(structure.split(//)).each_with_index.inject(
                Wrnap::Rna.base_pairs(structure).map(&:to_a).select { |i, j| Wrnap::Rna::CANONICAL_BASES.include?(Set.new([sequence[i], sequence[j]])) }
              ) do |valid_bases, ((bp, symbol), i)|
                valid_bases - (bp == ?. && symbol != ?. ? (valid_bases.select { |bps| bps.any? { |j| i == j } }) : [])
              end
            )
          )
        end

        def prune_gaps(rna)
          Wrnap::Rna.init_from_array(rna.seq.split(//).zip(rna.str.split(//)).reject { |nucleotide, _| nucleotide == ?. }.transpose.map(&:join))
        end

        def theta_filter(rna)
          # Needs to happen after gap pruning.
          Wrnap::Rna.init_from_string(
            rna.seq,
            Wrnap::Rna.structure_from_bp_list(rna.len, rna.base_pairs.map(&:to_a).select { |i, j| (j - i).abs > 3 })
          )
        end
      end
    end
  end
end
