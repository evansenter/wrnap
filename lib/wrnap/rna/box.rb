module Wrnap
  class Rna
    class Box
      prepend MetaMissing
      extend Forwardable
      include Enumerable
      include Wrnap::Global::Yaml

      attr_reader :rnas
      attr_accessor :name

      class << self
        def load_all(pattern = "*.fa", &block)
          new(Dir[File.directory?(pattern) ? File.join(pattern, "*.fa") : pattern].inject([]) do |array, file| 
            loaded_rnas = RNA.from_fasta(file, &block)
            array + (loaded_rnas.is_a?(Box) ? loaded_rnas.rnas : [loaded_rnas])
          end)
        end
      end

      def initialize(rnas, name = "")
        @rnas, @name = rnas.kind_of?(Array) ? rnas : [rnas], name
      end
      
      def write_fa!(filename)
        filename.tap do |filename|
          File.open(filename, ?w) { |file| file.write(rnas.map(&:formatted_string).join(?\n) + ?\n) }
        end
      end

      def pp
        rnas.each(&:pp) and nil
      end

      def +(arrayish)
        self.class.new(rnas + (arrayish.is_a?(Box) ? arrayish.rnas : arrayish))
      end

      def_delegators :@rnas, *%i|size length first last [] []= <<|

      def each(&block)
        return enum_for(:each) unless block_given?
        rnas.each(&block)
      end
      
      def run_in_parallel(method, *args)
        Wrnap.debug, debug_status = false, Wrnap.debug
        Parallel.map(self, progress: "Calling %s on %d RNAs" % [method, rnas.size]) { |rna| rna.send(method, *args) }.tap { Wrnap.debug = debug_status }
      end

      def kind_of?(klass)
        klass == Array ? true : super
      end
      
      handle_methods_like(/^run_\w+$/) do |match, name, *args, &block|
        run_in_parallel(name, *args)
      end

      def inspect
        ("#<Wrnap::Rna::Box %s with %d RNAs>" % [name, rnas.size]).gsub(/\s\s+/, " ")
      end
    end
  end
end
