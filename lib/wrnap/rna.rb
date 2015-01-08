module Wrnap
  class Rna
    Autoloaded.class {}
    
    prepend SequenceInitializer
    prepend MetaMissing
    extend Forwardable
    include Virtus.value_object(strict: true)
    include Wrnap::Global::Yaml
    include Wrnap::Rna::Extensions
    include Wrnap::Rna::Wrnapper
    include Wrnap::Rna::Constraints
    
    values do
      attribute :sequence,   SequenceWrapper
      attribute :structures, Array[StructureWrapper]
      attribute :comment,    String,                 default: ""
      attribute :metadata,   Hash[Symbol => Object], default: {}
    end

    class << self
      def init_from_hash(hash, &block)
        new({
          sequence:   hash[:sequence]   || hash[:seq],
          structures: hash[:structures] || hash[:structure] || hash[:strs] || hash[:str],
          comment:    hash[:comment]    || hash[:name]
        }.select { |_, value| value }, &block)
      end
      
      def init_from_string(sequence, *remaining_args, &block)
        init_from_hash(parse_rna_attributes(sequence, remaining_args), &block)
      end

      def init_from_array(array, &block)
        init_from_string(*array, &block)
      end

      alias_method :init_from_fa, def init_from_fasta(string, &block)
        if File.exist?(string)
          comment = File.basename(string, string.include?(?.) ? ".%s" % string.split(?.)[-1] : "")
          string  = File.read(string).chomp
        end
          
        if string.count(?>) > 1
          string.split(/>/).reject(&:empty?).map do |rna_string|
            rna_data = rna_string.split(?\n).reject(&:empty?)
            init_from_string(*rna_data[1..-1]).copy_name_from(rna_data[0])
          end.wrnap
        else
          init_from_string(*string.split(?\n).reject { |line| line.start_with?(?>) || line.empty? }, &block).tap do |rna|
            if (line = string.split(?\n).first).start_with?(?>) && !(file_comment = line.gsub(/^>\s*/, "")).empty?
              rna.comment = file_comment
            elsif comment
              rna.comment = comment
            end
          end
        end
      end

      def init_from_context(*context, coords: {}, rna: {}, &block)
        Context.init_from_entrez(*context, coords: coords, rna: rna, &block)
      end
      
      private
      
      def parse_rna_attributes(sequence, attributes = [])
        last_arg = (attributes = attributes.flatten).last
        
        if last_arg.is_a?(Symbol) || Regexp.compile("^[\\.\\(\\)]{%d}$" % sequence.length) =~ last_arg
          { seq: sequence, strs: attributes }
        else
          { seq: sequence, strs: attributes[0..-2], comment: last_arg }
        end
      end
    end

    alias_method :seq,  :sequence
    alias_method :strs, :structures
    alias_method :name, :comment
    alias_method :md,   :metadata
    
    def_delegator :@sequence,   :length, :len
    def_delegator :@structures, :first,  :structure
    def_delegator :@structures, :first,  :str

    def copy_name_from(nameish)
      tap { @comment = nameish.is_a?(String) ? nameish : nameish.name }
    end
    
    alias_method :num_strs, def number_of_structures
      structures.length
    end

    alias_method :empty_str, def empty_structure
      Structure.init_from_string("." * len)
    end

    alias_method :no_str, def no_structure
      self.class.init_from_string(seq, name)
    end

    alias_method :one_str, def one_structure(structure_1)
      self.class.init_from_string(seq, structure_1.is_a?(Symbol) ? send(structure_1) : structure_1, name)
    end

    alias_method :two_str, def two_structures(structure_1, structure_2)
      self.class.init_from_string(
        seq,
        [structure_1, structure_2].map { |argument| argument.is_a?(Symbol) ? send(argument) : argument },
        name
      )
    end
    
    def formatted_string
      [(">%s" % name if name), (seq if seq), *structures.map(&:as_string)].compact.join(?\n)
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

    def pp
      puts(formatted_string)
    end
    
    def inspect
      "#<RNA: %s>" % [seq.inspect, *strs.map(&:inspect), name.empty? ? self.class.name : name].compact.join(", ")
    end
    
    handle_methods_like(/^str(ucture)?_(\d+)$/) do |match, name, *args, &block|
      structures[match[2].to_i - 1]
    end
    
    handle_methods_like(/^run_(\w+)$/) do |match, name, *args, &block|
      run(match[1], *args)
    end
  end
end
