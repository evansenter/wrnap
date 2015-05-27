module Wrnap
  class Rna
    Autoloaded.class {}

    prepend MetaMissing
    extend Forwardable
    extend Wrnap::RnaInitializer
    include Wrnap::Global::Hashmarks
    include Wrnap::Global::Yaml
    include Wrnap::Rna::Extensions
    include Wrnap::Rna::Wrnapper
    include Wrnap::Rna::Constraints

    def_delegator :@sequence,   :length, :length
    def_delegator :@sequence,   :length, :len
    def_delegator :@structures, :first,  :structure
    def_delegator :@structures, :first,  :str

    def copy_name_from(nameish)
      tap { @comment = nameish.is_a?(String) ? nameish : nameish.name }
    end

    alias_method :num_strs, def number_of_structures
      strs.length
    end

    alias_method :empty_str, def empty_structure
      Structure.init_from_string("." * len)
    end

    alias_method :no_str, def no_structure
      self.class.init_from_string(seq, name)
    end

    alias_method :one_str, def one_structure(str_1)
      self.class.init_from_string(seq, str_1.is_a?(Symbol) ? send(str_1) : str_1, name)
    end

    alias_method :two_str, def two_structures(str_1, str_2)
      self.class.init_from_string(
        seq,
        [str_1, str_2].map { |argument| argument.is_a?(Symbol) ? send(argument) : argument },
        name
      )
    end

    def formatted_string
      [(">%s" % name if name), (seq if seq), *strs.map(&:as_string)].compact.join(?\n)
    end

    def write_fa!(filename)
      filename.tap do |filename|
        File.open(filename, ?w) { |file| file.write(formatted_string + ?\n) }
      end
    end

    def temp_fa_file!
      write_fa!(Tempfile.new("rna")).path
    end

    def run(package_name, options = {})
      Wrnap::Package.lookup(package_name).run(self, options)
    end

    def p
      puts(formatted_string)
    end

    def inspect
      "#<RNA: %s>" % [seq.inspect, *strs.map(&:inspect), name.empty? ? self.class.name : name].compact.join(", ")
    end

    handle_methods_like(/^str(ucture)?_?(\d+)$/) do |match, name, *args, &block|
      structures[match[2].to_i - 1]
    end

    handle_methods_like(/^run_(\w+)$/) do |match, name, *args, &block|
      run(match[1], *args)
    end
  end
end
