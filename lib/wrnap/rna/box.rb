module Wrnap
  class Rna
    class Box
      prepend MetaMissing
      extend Forwardable
      include Enumerable
      include Virtus.value_object(strict: true)
      include Wrnap::Global::Yaml

      values do
        attribute :rnas, Array[Rna]
        attribute :name, String, default: ""
      end

      def self.load_all(pattern = "*.fa")
        new(rnas: Dir[File.directory?(pattern) ? File.join(pattern, "*.fa") : pattern].inject([]) do |array, file|
          loaded_rnas = RNA.from_fasta(file)
          array + (loaded_rnas.is_a?(Box) ? loaded_rnas.rnas : [loaded_rnas])
        end)
      end

      def write_fa!(filename)
        filename.tap do |filename|
          File.open(filename, ?w) { |file| file.write(rnas.map(&:formatted_string).join(?\n) + ?\n) }
        end
      end

      def p
        rnas.each(&:p) and nil
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
        Parallel.map(self, progress: "Calling %s on %d RNAs" % [method, rnas.size]) do |rna|
          rna.send(method, *args)
        end.tap do
          Wrnap.debug = debug_status
        end
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
