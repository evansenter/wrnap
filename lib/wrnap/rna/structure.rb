module Wrnap
  class Rna
    class Structure
      extend StructureInitializer
      include Wrnap::Global::Hashmarks

      alias_method :to_s, def as_string
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

      def p
        puts to_s
      end

      def inspect
        if length > 0
          "#<Structure: %s%s>" % [as_string[0, 20], length > 20 ? " [%d]" % length : ""]
        else
          "#<Structure (empty)>"
        end
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
