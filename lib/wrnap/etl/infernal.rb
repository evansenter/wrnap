module Wrnap
  module Etl
    module Infernal
      class << self
        def parse_file(file)
          output = File.exist?(file) ? File.read(file) : file

          if output =~ /No hits detected that satisfy reporting thresholds/
            []
          else
            output.
              gsub(/^(.*\n)*Hit alignments:\n/, "").
              gsub(/Internal CM pipeline statistics summary:\n(.*\n)*$/, "").
              strip.split(?\n).reject(&:empty?).each_slice(10).map { |lines| parse_hit(lines.join(?\n)) }
          end
        end

        def parse_hit(output)
          name = if output =~ (identifier_regex = />>\s+(\S+)(.*\n){3}.*\s(\d+)\s+(\d+)\s+[\+-].*\n/)
            # This is a pretty fancy regex, and there's no guarantee that the data has this info, so let's just test the waters here.
            _, id, _, seq_from, seq_to, _ = output.match(identifier_regex).to_a
            "%s %d %d" % [id.split(?|).last, seq_from, seq_to]
          end

          Stockholm.fit_structure_to_sequence(
            *output.split(?\n).as do |infernal|
              [
                infernal.select { |line| line =~ /^.*\d+\s+.*\s+\d+\s*$/ }.last.match(/^.*\s+(\S+)\s+\d+\s*$/)[1].upcase.gsub(/[^AUGC]/, ?.),
                convert_infernal_to_dot_bracket(infernal.find { |line| line =~ /CS\s*$/ }.gsub(/\s+CS\s*$/, "").strip)
              ]
            end
          ).tap { |rna| rna.comment = name if name }
        end

        def convert_infernal_to_dot_bracket(structure)
          # http://jalview-rnasupport.blogspot.com/2010/06/parsing-wuss-notation-of-rna-secondary.html
          structure.gsub(/[:,_-]/, ?.).gsub(/[<\[\{]/, ?().gsub(/[>\]\}]/, ?))
        end
      end
    end
  end
end
