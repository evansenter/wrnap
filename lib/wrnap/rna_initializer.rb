module Wrnap
  module RnaInitializer
    def self.extended(base)
      base.class_eval do
        prepend Wrnap::Rna::ConstructorInterceptor
        include Virtus.model

        values do
          attribute :sequence,   Wrnap::Rna::SequenceWrapper
          attribute :structures, Array[Wrnap::Rna::StructureWrapper]
          attribute :comment,    String,                 default: ""
          attribute :metadata,   Hash[Symbol => Object], default: {}
        end

        alias_method :seq,  :sequence
        alias_method :strs, :structures
        alias_method :name, :comment
        alias_method :md,   :metadata

        %i|structure= strs= str=|.each { |assigner| alias_method assigner, :structures= }
      end
    end

    def init_from_hash(hash)
      new({
        sequence:   hash[:sequence]   || hash[:seq],
        structures: hash[:structures] || hash[:structure] || hash[:strs] || hash[:str],
        comment:    hash[:comment]    || hash[:name],
        metadata:   hash[:metadata]   || hash[:md]
      }.select { |_, value| value })
    end

    def init_from_string(sequence, *remaining_args)
      init_from_hash(parse_rna_attributes(sequence, remaining_args))
    end

    def init_from_array(array)
      init_from_string(*array)
    end

    alias_method :init_from_fa, def init_from_fasta(string)
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
        init_from_string(*string.split(?\n).reject { |line| line.start_with?(?>) || line.empty? }).tap do |rna|
          if (line = string.split(?\n).first).start_with?(?>) && !(file_comment = line.gsub(/^>\s*/, "")).empty?
            rna.comment = file_comment
          elsif comment
            rna.comment = comment
          end
        end
      end
    end

    def init_from_context(*context, coords: {}, rna: {})
      Context.init_from_entrez(*context, coords: coords, rna: rna)
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
end
