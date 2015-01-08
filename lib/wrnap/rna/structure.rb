module Wrnap
  class Rna
    class Structure
      include Virtus.value_object(strict: true)

      values do
        attribute :base_pairs, SortedSet
        attribute :length,     Integer
      end
      
      class << self
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
        	        raise "Too many ')' in '#{dot_bracket_structure}'"
        	      else
        	        stack.pop.tap do |opening|
        	          array[opening] = index
        	          array[index]   = opening
        	        end
        	      end
        	    end
        	  end
        	end.tap do
        	  raise "Too many '(' in '#{dot_bracket_structure}'" unless stack.empty?
        	end
        end
      end
      
      def as_string
        @as_string ||= self.class.as_string(self)
      end
      
      def max_bp_distance
        base_pairs.count + ((length - 3) / 2.0).floor
      end
      
      def loops_and_helices(lonely_bp: true)
        [loop_regions, collapsed_helices(lonely_bp: lonely_bp)]
      end
      
      def loop_regions
        [as_string.split(//), (0...length).to_a].transpose.select { |char, _| char == ?. }.inject([]) do |array, (_, index)|
          array.tap do
            matching_loop = array.map(&:last).each_with_index.find { |end_of_loop, _| end_of_loop + 1 == index }
            matching_loop ? array[matching_loop[-1]][-1] += 1 : array << [index, index]
          end
        end.map { |from, to| Loop.new(from: from, to: to) }
      end
      
      def collapsed_helices(lonely_bp: false)
        all_helices.map { |((i, j), *rest)| Helix.new(i: i, j: j, length: rest.length + 1) }.select { |helix| lonely_bp ? helix : helix.length > 1 }
      end
      
      def inspect
        "#<Structure: %s>" % (as_string[0, 20] + (length > 20 ? " [%d]" % length : ""))
      end
      
      private
      
      def all_helices
        unless (array = base_pairs.to_a).empty?
          array[1..-1].inject([[array.first]]) do |bins, (i, j)|
            bins.tap { bins[-1][-1] == [i - 1, j + 1] ? bins[-1] << [i, j] : bins << [[i, j]] }
          end
        else
          []
        end
      end      
    end
  end
end
