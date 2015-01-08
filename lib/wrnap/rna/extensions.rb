module Wrnap
  class Rna
    module Extensions
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.extend(ClassMethods)
        base.extend(TwoStructureBasedMethods)
        base.class_eval do
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
      end

      module InstanceMethods
        def hamming_distance(other_rna)
          raise "The two sequences are not the same length" unless len == other_rna.len
          
          [seq, other_rna.seq].map(&:each_char).map(&:to_a).transpose.select { |array| array.uniq.size > 1 }.count
        end
        
        def local_structural_shuffle(dishuffle: false)
          # Permutes the base pairs of the structure provided for the template sequence independently of the unpaired regions, as in
          # global_structural_shuffle. This adds the additional constraint that loops and helices are permuted as individual sets,
          # rather than using two global loop / helix bags.
          raise "the structural_shuffle functions require the initial RNA to have a structure" unless str
          
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
          # Permutes the nucleotides of the sequence such that the basepairs in the initial structure are shuffled independently of the
          # unpaired bases. This ensures that the resulting sequence is compatible with the original structure.
          raise "the structural_shuffle functions require the initial RNA to have a structure" unless str
          
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
