module Wrnap
  class Rna
    extend Forwardable
    include Wrnap::Global::Yaml
    include Wrnap::Rna::Extensions
    include Wrnap::Rna::Wrnapper
    include Wrnap::Rna::Metadata
    include Wrnap::Rna::Motifs
    include Wrnap::Rna::TreeFunctions
    include Wrnap::Rna::Constraints

    CANONICAL_BASES = Set.new << Set.new([?G, ?C]) << Set.new([?A, ?U]) << Set.new([?G, ?U])

    attr_accessor :comment
    attr_reader :sequence, :structure, :second_structure, :metadata

    class << self
      def init_from_string(sequence, structure = nil, second_structure = nil, comment = nil, &block)
        new(
          sequence:         sequence,
          structure:        structure,
          second_structure: second_structure,
          comment:          comment,
          &block
        )
      end

      def init_from_hash(hash, &block)
        new(
          sequence:         hash[:sequence]         || hash[:seq],
          structure:        hash[:structure]        || hash[:str_1] || hash[:str],
          second_structure: hash[:second_structure] || hash[:str_2],
          comment:          hash[:comment]          || hash[:name],
          &block
        )
      end

      def init_from_array(array, &block)
        init_from_string(*array, &block)
      end

      def init_from_fasta(string, &block)
        if File.exist?(string)
          comment = File.basename(string, string.include?(?.) ? ".%s" % string.split(?.)[-1] : "")
          string  = File.read(string).chomp
        end

        init_from_string(*string.split(/\n/).reject { |line| line.start_with?(">") }[0, 3], &block).tap do |rna|
          if (line = string.split(/\n/).first).start_with?(">") && !(file_comment = line.gsub(/^>\s*/, "")).empty?
            rna.comment = file_comment
          elsif comment
            rna.comment = comment
          end
        end
      end

      def init_from_context(*context, coords: {}, rna: {}, &block)
        Context.init_from_entrez(*context, coords: coords, rna: rna, &block)
      end

      def init_from_self(rna, &block)
        # This happens when you call a Wrnap library function with the output of something like Wrnap::Fold.run(...).mfe
        new(
          sequence:         rna.sequence,
          strucutre:        rna.structure,
          second_strucutre: rna.second_structure,
          comment:          rna.comment,
          &block
        )
      end

      alias_method :placeholder, :new
    end

    def initialize(sequence: "", structure: "", second_structure: "", comment: "", &block)
      @sequence, @comment, @metadata = (sequence.kind_of?(Rna) ? sequence.seq : sequence).upcase, comment, Metadata::Container.new(self)

      [:structure, :second_structure].each do |structure_symbol|
        instance_variable_set(
          :"@#{structure_symbol}",
          case structure_value = eval("#{structure_symbol}")
          when :empty then empty_structure
          when :mfe   then RNA(sequence).run(:fold).mfe_rna.structure
          when String then structure_value
          when Hash   then
            if structure_value.keys.count > 1
              Wrnap.debugger { "The following options hash has more than one key. This will probably produce unpredictable results: %s" % structure_value.inspect }
            end

            RNA(sequence).run(*structure_value.keys, *structure_value.values).mfe_rna.structure
          end
        )
      end

      metadata.instance_eval(&block) if block_given?

      if str && len != str.length
        Wrnap.debugger { "The sequence length (%d) doesn't match the structure length (%d)" % [seq, str].map(&:length) }
      end

      if str_2 && str_1.length != str_2.length
        Wrnap.debugger { "The first structure length (%d) doesn't match the second structure length (%d)" % [str_1, str_2].map(&:length) }
      end
    end

    alias :seq   :sequence
    alias :str   :structure
    alias :str_1 :structure
    alias :str_2 :second_structure
    alias :name  :comment
    
    def_delegator :@sequence, :length, :len

    def copy_name_from(rna)
      tap { @comment = rna.name }
    end

    def empty_structure
      "." * len
    end

    alias :empty_str :empty_structure

    def no_structure
      self.class.init_from_string(seq, nil, nil, name)
    end

    alias :no_str :no_structure

    def one_structure(structure_1)
      self.class.init_from_string(seq, structure_1.is_a?(Symbol) ? send(structure_1) : structure_1, nil, name)
    end

    alias :one_str :one_structure

    def two_structures(structure_1, structure_2)
      self.class.init_from_string(
        seq,
        *[structure_1, structure_2].map { |argument| argument.is_a?(Symbol) ? send(argument) : argument },
        name
      )
    end

    alias :two_str :two_structures

    def write_fa!(filename)
      filename.tap do |filename|
        File.open(filename, ?w) do |file|
          file.write("> %s\n" % name) if name
          file.write("%s\n" % seq)    if seq
          file.write("%s\n" % str_1)  if str_1
          file.write("%s\n" % str_2)  if str_2
        end
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

    def method_missing(name, *args, &block)
      if (name_str = "#{name}") =~ /^run_\w+$/
        run(name_str.gsub(/^run_/, ""), *args)
      else super end
    end

    def pp
      puts("> %s" % name)       if name
      puts("%s" % seq)          if seq
      puts("%s" % str_1)        if str_1
      puts("%s" % str_2)        if str_2
      puts("%s" % meta.inspect) if meta
    end

    def inspect
      "#<RNA: %s>" % [
        ("#{seq[0, 20]   + (len > 20   ? '... [%d]' % len : '')}" if seq   && !seq.empty?),
        ("#{str_1[0, 20] + (str_1.length > 20 ? ' [%d]'    % len : '')}" if str_1 && !str_1.empty?),
        ("#{str_2[0, 20] + (str_2.length > 20 ? ' [%d]'    % len : '')}" if str_2 && !str_1.empty?),
        (md.inspect unless md.nil? || md.empty?),
        (name ? name : "#{self.class.name}")
      ].compact.join(", ")
    end
  end
end
