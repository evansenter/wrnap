module Wrnap
  class Rna
    module Extensions
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
        base.extend(OneStructureBasedMethods)
        base.extend(TwoStructureBasedMethods)
        base.class_eval do
          OneStructureBasedMethods.public_instance_methods.each do |class_method|
            define_method(class_method) do |*args|
              self.class.send(class_method, *[structure].concat(args))
            end
          end

          TwoStructureBasedMethods.public_instance_methods.each do |class_method|
            define_method(class_method) do |*args|
              self.class.send(class_method, *[str_1, str_2].concat(args))
            end
          end
        end

        base.send(:include, InstanceMethods)
      end

      module ClassMethods
        def generate_sequence(sequence_length)
          # 0th order Markov chain w/ uniform probability distribution
          Rna.init_from_string(sequence_length.times.inject("") { |string, _| string + %w[A U C G][rand(4)] })
        end

        def shuffle(sequence, token_length = 2)
          Shuffle.new(sequence).shuffle(token_length)
        end

        def structure_from_bp_list(length, base_pairs)
          base_pairs.to_a.map(&:to_a).map(&:sort).inject("." * length) { |structure, (i, j)| structure.tap { structure[i] = ?(; structure[j] = ?) } }
        end
      end

      module InstanceMethods
        def hamming_distance(other_rna)
          raise "The two sequences are not the same length" unless len == other_rna.len
          
          [seq, other_rna.seq].map(&:each_char).map(&:to_a).transpose.select { |array| array.uniq.size > 1 }.count
        end
        
        def local_structural_shuffle(dishuffle: false)
          sequence       = " " * len
          loops, helices = loops_and_helices
        
          loops.each { |loop| sequence[loop.i..loop.j] = Shuffle.new(loop.in(seq)).send(dishuffle ? :dishuffle : :shuffle) }
          helices.each do |helix|
            left_stem, right_stem = if dishuffle
              Shuffle.new(helix.in(seq)).dishuffle
            else
              Shuffle.new(helix.in(seq)).shuffle.map { |array| rand(2).zero? ? array : array.reverse }
            end.transpose.map(&:join)
            
            sequence[helix.i..helix.k] = left_stem
            sequence[helix.l..helix.j] = right_stem.reverse
          end
          
          Rna.init_from_string(sequence, str)
        end
        
        def local_structural_dishuffle
          local_structural_shuffle(dishuffle: true)
        end
        
        def global_structural_shuffle
          sequence         = " " * len
          loops, helices   = loops_and_helices
          shuffled_loops   = Shuffle.new(loops.map { |loop| loop.in(seq) }.join.split(//)).shuffle
          shuffled_helices = helices.map { |helix| helix.in(seq) }.inject(&:+).shuffle.map { |array| rand(2).zero? ? array : array.reverse }
        
          loops.each { |loop| sequence[loop.i..loop.j] = shuffled_loops.shift(loop.length).join }
          helices.each do |helix|
            left_stem, right_stem      = shuffled_helices.shift(helix.length).transpose.map(&:join)
            sequence[helix.i..helix.k] = left_stem
            sequence[helix.l..helix.j] = right_stem.reverse
          end
          
          Rna.init_from_string(sequence, str)
        end
        
        def dishuffle
          Rna.init_from_string(self.class.shuffle(sequence, 2))
        end

        def gc_content
          seq.split(//).select { |i| i =~ /[GC]/i }.size.to_f / seq.size
        end

        def boltzmann_probability(dangle: 2)
          Math.exp(-run(:eval, d: dangle).mfe / Wrnap::RT) / Math.exp(-run(:fold, d: dangle, p: 0).ensemble_energy / Wrnap::RT)
        end
      end

      module OneStructureBasedMethods
        def max_bp_distance(structure)
          base_pairs(structure).count + ((structure.length - 3) / 2.0).floor
        end
        
        def loops_and_helices(structure)
          [loop_regions(structure), collapsed_helices(structure, lonely_bp: true)]
        end
        
        def loop_regions(structure)
          [structure.split(//), (0...structure.length).to_a].transpose.select { |char, _| char == ?. }.inject([]) do |array, (_, index)|
            array.tap do
              matching_loop = array.map(&:last).each_with_index.find { |end_of_loop, _| end_of_loop + 1 == index }
              matching_loop ? array[matching_loop[-1]][-1] += 1 : array << [index, index]
            end
          end.map { |loop_indices| Loop.new(*loop_indices) }
        end
        
        def helices(structure)
          unless (array = base_pairs(structure).sort_by(&:first).map(&:to_a)).empty?
            array[1..-1].inject([[array.first]]) do |bins, (i, j)|
              bins.tap { bins[-1][-1] == [i - 1, j + 1] ? bins[-1] << [i, j] : bins << [[i, j]] }
            end
          else
            []
          end
        end

        def collapsed_helices(structure, lonely_bp: false)
          helices(structure).map { |((i, j), *rest)| Helix.new(i, j, rest.length + 1) }.select { |helix| lonely_bp ? helix : helix.length > 1 }
        end

        def base_pairs(structure)
          get_pairings(structure).each_with_index.inject(Set.new) do |set, (j, i)|
            j >= 0 ? set << Set[i, j] : set
          end
        end

        def get_pairings(structure)
        	stack = []

          structure.each_char.each_with_index.inject(Array.new(structure.length, -1)) do |array, (symbol, index)|
        	  array.tap do
        	    case symbol
        	    when "(" then stack.push(index)
        	    when ")" then
        	      if stack.empty?
        	        raise "Too many ')' in '#{structure}'"
        	      else
        	        stack.pop.tap do |opening|
        	          array[opening] = index
        	          array[index]   = opening
        	        end
        	      end
        	    end
        	  end
        	end.tap do
        	  raise "Too many '(' in '#{structure}'" unless stack.empty?
        	end
        end
      end

      module TwoStructureBasedMethods
        def bp_distance(structure_1, structure_2)
          # Takes two structures and calculates the distance between them by |symmetric difference(bp_in_a, bp_in_b)|
          raise "The two structures are not the same length" unless structure_1.length == structure_2.length

          bp_set_1, bp_set_2 = base_pairs(structure_1), base_pairs(structure_2)

          ((bp_set_1 - bp_set_2) + (bp_set_2 - bp_set_1)).count
        end
      end
    end
  end
end
