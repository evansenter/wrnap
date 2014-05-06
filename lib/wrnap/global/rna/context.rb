module Wrnap
  module Global
    class Rna
      class Context < Rna
        attr_reader :accession, :from, :to, :coord_options

        class << self
          def init_from_entrez(accession, from, to, options = {})
            new(
              accession: accession,
              from:      from,
              to:        to,
              options:   options
            )
          end

          def init_from_string(sequence, accession, from, to, options = {})
            new(
              sequence:  sequence,
              accession: accession,
              from:      from,
              to:        to,
              options:   options
            )
          end
        end

        def initialize(sequence: nil, accession: nil, from: nil, to: nil, options: {})
          options = { coords: {}, rna: {} }.merge(options)

          @accession, @from, @to, @coord_options = accession, from, to, options[:coords]

          validate_coord_options

          if sequence
            @raw_sequence = (sequence.is_a?(String) ? Bio::Sequence::NA.new(sequence) : sequence).upcase
          end

          super({
            sequence:         self.sequence,
            structure:        options[:rna][:structure]        || options[:rna][:str_1] || options[:rna][:str],
            second_structure: options[:rna][:second_structure] || options[:rna][:str_2],
            comment:          options[:rna][:comment]          || options[:rna][:name]
          })

          remove_instance_variable(:@sequence)
        end

        def validate_coord_options
          unless coord_options.empty?
            unless Set.new(coord_options.keys) == Set.new(%i|direction length|)
              raise ArgumentError.new("coord_options keys must contain only [:direction, :length], found: %s" % coord_options.keys)
            end

            unless (length = coord_options[:length]).is_a?(Integer) && length > 0
              raise ArgumentError.new("coord_options length must be greater than 0, found: %d" % length)
            end

            unless [:up, :down, :both, 5, 3].include?(direction = coord_options[:direction])
              raise ArgumentError.new("coord_options directions is not a valid key, found: %s" % direction)
            end
          end
        end

        def up_coord
          [from, to].min
        end

        def down_coord
          [from, to].max
        end

        def seq_from
          up_coord + coord_window.min
        end

        def seq_to
          up_coord + coord_window.max
        end

        def strand
          plus_strand? ? :plus : :minus
        end

        def plus_strand?
          to > from
        end

        def minus_strand?
          !plus_strand?
        end

        def sequence
          if @raw_sequence
            @raw_sequence
          else
            entrez_sequence = Entrez.rna_sequence_from_entrez(accession, up_coord, coord_window)
            @raw_sequence   = minus_strand? ? entrez_sequence.complement : entrez_sequence
          end
        end

        alias :seq :sequence

        def extend!(coord_options = {})
          self.class.init_from_entrez(accession, from, to, coords: coord_options)
        end

        def coord_window
          # This does not support extending the range in both directions, though it should be easy to do.
          # Options from coord_options ex: { length: 300, direction: 3 }, { length: 250, direction: :both }, { length: 200, direction: :down }
          range = 0..(down_coord - up_coord)

          if coord_options[:length] && coord_options[:direction]
            if coord_options[:direction] == :both
              Range.new(range.min - coord_options[:length], range.max + coord_options[:length])
            else
              case [coord_options[:direction], strand]
              when [3, :plus], [:down, :plus], [5, :minus], [:up, :minus] then Range.new(range.min, range.max + coord_options[:length])
              when [5, :plus], [:up, :plus], [3, :minus], [:down, :minus] then Range.new(range.min - coord_options[:length], range.max)
              else Wrnap.debugger { "WARNING: value for :direction key in sequence retreival needs to be one of 5, 3, :both - found (%s)" % coord_options[:direction].inspect }
              end
            end
          else
            range
          end
        end
      end
    end
  end
end
