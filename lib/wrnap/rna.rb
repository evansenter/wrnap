module Wrnap
  class Rna
    prepend MetaMissing
    extend Forwardable
    include Wrnap::Global::Yaml
    include Wrnap::Rna::Extensions
    include Wrnap::Rna::Wrnapper
    include Wrnap::Rna::Metadata
    include Wrnap::Rna::TreeFunctions
    include Wrnap::Rna::Constraints

    CANONICAL_BASES = Set.new << Set.new([?G, ?C]) << Set.new([?A, ?U]) << Set.new([?G, ?U])

    attr_accessor :comment
    attr_reader   :sequence, :structures, :metadata

    class << self
      def init_from_string(sequence, *remaining_args, &block)
        init_from_hash(parse_rna_attributes(sequence, remaining_args), &block)
      end
      
      def parse_rna_attributes(sequence, attributes = [])
        last_arg = (attributes = attributes.flatten).last
        
        if last_arg.is_a?(Symbol) || Regexp.compile("^[\\.\\(\\)]{%d}$" % sequence.length) =~ last_arg
          { seq: sequence, strs: attributes }
        else
          { seq: sequence, strs: attributes[0..-2], comment: last_arg }
        end
      end

      def init_from_hash(hash, &block)
        new(
          sequence:   hash[:sequence]   || hash[:seq],
          structures: hash[:structures] || hash[:structure] || hash[:strs] || hash[:str],
          comment:    hash[:comment]    || hash[:name],
          &block
        )
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

      def init_from_self(rna, &block)
        # This happens when you call a Wrnap library function with the output of something like Wrnap::Fold.run(...).mfe
        new(
          sequence:   rna.sequence,
          structures: rna.structures,
          comment:    rna.comment,
          &block
        ).tap do |new_rna|
          new_rna.instance_variable_set(:@metadata, rna.metadata.clone)
        end
      end
      
      def init_from_old_rna_object(rna)
        init_from_self(rna).tap do |new_rna|
          new_rna.instance_variable_set(:@structures, [
            rna.instance_variable_get(:@structure),
            rna.instance_variable_get(:@second_structure)
          ].compact)
        end
      end

      alias_method :placeholder, :new
    end

    def initialize(sequence: "", structures: [], comment: "", &block)
      @sequence   = (sequence.kind_of?(Rna) ? sequence.seq : sequence).upcase
      @comment    = comment
      @metadata   = Metadata::Container.new(self)
      @structures = (structures ? [structures].flatten : []).each_with_index.map do |structure, i|
        case structure
        when :empty, :empty_str then empty_structure
        when :mfe   then RNA(@sequence).run(:fold).mfe_rna.structure
        when String then structure
        when Hash   then
          if structure.keys.count > 1
            Wrnap.debugger { "The following options hash has more than one key. This will probably produce unpredictable results: %s" % structure.inspect }
          end

          RNA(@sequence).run(*structure.keys, *structure.values).mfe_rna.structure
        end.tap do |parsed_structure|
          if parsed_structure.length != len
            Wrnap.debugger { "The sequence length (%d) doesn't match the structure length at index %d (%d)" % [len, i, parsed_structure.length] }
          end
        end
      end

      metadata.instance_eval(&block) if block_given?
    end

    alias_method :seq,  :sequence
    alias_method :strs, :structures
    alias_method :name, :comment
    
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
      "." * len
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
      [
        (">%s" % name if name),
        ("%s"  % seq  if seq),
        *structures
      ].compact.join(?\n)
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

    def eql?(other_rna)
      self == other_rna
    end

    def ==(other_rna)
      other_rna.kind_of?(Wrnap::Rna) ? [seq, str_1, str_2] == [other_rna.seq, other_rna.str_1, other_rna.str_2] : super
    end

    def pp
      puts(formatted_string)
    end
    
    def inspect
      "#<RNA: %s>" % [
        ("#{seq[0, 20] + (len > 20 ? '... [%d]' % len : '')}" if seq && !seq.empty?),
        *strs.map { |str| ("#{str[0, 20] + (str.length > 20 ? ' [%d]' % str.length : '')}" if str && !str.empty?) },
        (md.inspect unless md.nil? || md.empty?),
        (name ? name : "#{self.class.name}")
      ].compact.join(", ")
    end
    
    handle_methods_like(/^str(ucture)?_(\d+)$/) do |match, name, *args, &block|
      structures[match[2].to_i - 1]
    end
    
    handle_methods_like(/^run_(\w+)$/) do |match, name, *args, &block|
      run(match[1], *args)
    end
  end
end
