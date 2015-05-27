module Wrnap
  class Rna
    module StructureInitializer
      def self.extended(base)
        base.class_eval do
          include Virtus.value_object(strict: true)
          include Wrnap::Rna::Tree

          values do
            attribute :base_pairs, SortedSet
            attribute :length,     Integer
          end

          alias_method :bps, :base_pairs
          alias_method :len, :length
        end

        alias_method :init_from_string, def init_from_dot_bracket(dot_bracket_structure)
          base_pairs_from_string(dot_bracket_structure)
        end

        def init_from_bp_list(base_pairs, length)
          new(base_pairs: base_pairs, length: length)
        end

        def as_string(structure)
          structure.base_pairs.inject(?. * structure.length) { |string, (i, j)| string.tap { string[i] = ?(; string[j] = ?) } }
        end

        private

        def base_pairs_from_string(dot_bracket_structure)
          raise ArgumentError.new("Provided structure contains invalid characters") unless /^[\.\(\)]*$/ =~ dot_bracket_structure

          base_pairs = pairing_list_from_string(dot_bracket_structure).each_with_index.inject(SortedSet.new) do |set, (j, i)|
            j >= 0 ? set << [i, j].sort : set
          end

          init_from_bp_list(base_pairs, dot_bracket_structure.length)
        end

        def pairing_list_from_string(dot_bracket_structure)
          stack = []

          dot_bracket_structure.each_char.each_with_index.inject(Array.new(dot_bracket_structure.length, -1)) do |array, (symbol, index)|
            array.tap do
              case symbol
              when ?( then stack.push(index)
              when ?) then
                if stack.empty?
                  raise ArgumentError.new("Too many ')' in '#{dot_bracket_structure}'")
                else
                  stack.pop.tap do |opening|
                    array[opening] = index
                    array[index]   = opening
                  end
                end
              end
            end
          end.tap do
            raise ArgumentError.new("Too many '(' in '#{dot_bracket_structure}'") unless stack.empty?
          end
        end
      end
    end
  end
end
