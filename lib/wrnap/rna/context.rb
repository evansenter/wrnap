module Wrnap
  class Rna
    class Context < Rna
      extend Forwardable

      attr_reader :accession, :from, :to, :coord_options

      class << self
        def init_from_entrez(accession, from, to, options = {})
          new(
            accession: accession,
            from:      from.to_i,
            to:        to.to_i,
            options:   options
          )
        end

        def init_from_string(sequence, accession, from, to, options = {})
          new(
            sequence:  sequence,
            accession: accession,
            from:      from.to_i,
            to:        to.to_i,
            options:   options
          )
        end
      end

      def initialize(sequence: nil, accession: nil, from: nil, to: nil, options: {})
        @accession, @from, @to, @coord_options = accession, from, to, validate_coord_options(options)

        super(sequence: sequence || retrieve_sequence, comment: identifier)
      end

      def validate_coord_options(options)
        unless options.empty?
          unless Set.new(options.keys) == Set.new(%i|direction length|)
            raise ArgumentError.new("coord_options keys must contain only [:direction, :length], found: %s" % options.keys)
          end

          unless (length = options[:length]).is_a?(Integer) && length > 0
            raise ArgumentError.new("coord_options length must be greater than 0, found: %d" % length)
          end

          unless [:up, :down, :both, 5, 3].include?(direction = options[:direction])
            raise ArgumentError.new("coord_options directions is not a valid key, found: %s" % direction)
          end
        end

        options
      end

      def up_coord
        [from, to].min
      end

      def down_coord
        [from, to].max
      end

      def seq_from
        up_coord + (plus_strand? ? coord_window.min : coord_window.max)
      end

      def seq_to
        up_coord + (minus_strand? ? coord_window.min : coord_window.max)
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

      def retrieve_sequence
        retrieved_sequence = Wrnap::Global::Entrez.sequence_from_entrez(accession, up_coord, coord_window)

        minus_strand? ? retrieved_sequence.complement : retrieved_sequence
      end

      def expand(coord_options = {})
        self.class.init_from_entrez(accession, from, to, coords: coord_options)
      end

      def coord_window
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

      def identifier
        "%s %d - %d" % [accession, seq_from, seq_to]
      end

      def _id
        identifier.gsub(/[^A-Z0-9]/, ?_).gsub(/__+/, ?_)
      end

      def inspect
        if super.match(/Wrnap::(\w+(::)?)+>$/)
          super.sub(/([\w:]+)>$/) { |_| "%s %s>" % [identifier, $1] }
        else
          super
        end
      end
    end
  end
end
