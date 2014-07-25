module Wrnap
  class Rna
    class Box
      extend Forwardable
      include Enumerable
      include Wrnap::Global::Yaml

      attr_reader :rnas

      class << self
        def load_all(pattern = "*.fa", &block)
          new(Dir[File.directory?(pattern) ? pattern + "/*.fa" : pattern].map { |file| RNA.from_fasta(file, &block) })
        end
      end

      def initialize(rnas)
        @rnas = rnas.kind_of?(Array) ? rnas : [rnas]
      end

      def pp
        rnas.each(&:pp) and nil
      end

      def +(arrayish)
        self.class.new(rnas + (arrayish.is_a?(Box) ? arrayish.rnas : arrayish))
      end

      def_delegators :@rnas, *%i|size length [] []= <<|

      def each(&block)
        rnas.each(&block)
      end

      def kind_of?(klass)
        klass == Array ? true : super
      end

      def inspect
        "#<Wrnap::Rna::Box with %d RNAs>" % rnas.size
      end
    end
  end
end
