module Wrnap
  module Etl
    module Infernal
      NAME_REGEX   = />>\s+(\S+)(.*\n){3}.*\s(\d+)\s+(\d+)\s+[\+-].*\n/
      HIT_SEQUENCE = /^.*\d+\s+(.*)\s+\d+\s*$/
      LOCAL_END    = /\*\[\s*\d+\s*\]\*/

      class << self
        def parse_file(file)
          output = File.exist?(file) ? File.read(file) : file

          if output =~ /No hits detected that satisfy reporting thresholds/
            []
          else
            output.
              gsub(/^(.*\n)*Hit alignments:\n/, "").
              gsub(/Internal CM pipeline statistics summary:\n(.*\n)*$/, "").
              strip.split(?\n).reject(&:empty?).each_slice(10).map { |lines| parse_hit(lines.join(?\n)) }.compact
          end
        end

        def parse_hit(output)
          name = if output =~ NAME_REGEX
            # This is a pretty fancy regex, and there's no guarantee that the data has this info, so let's just test the waters here.
            _, id, _, seq_from, seq_to, _ = output.match(NAME_REGEX).to_a
            "%s %d %d" % [id.split(?|).last, seq_from, seq_to]
          end

          unless (hit_sequence = pull_infernal_hit_sequence(output)) =~ LOCAL_END
            Stockholm.fit_structure_to_sequence(hit_sequence, pull_infernal_hit_structure(output)).tap { |rna| rna.comment = name if name }
          end
        end

        def pull_infernal_hit_sequence(output)
          # Dots are gaps in Stockholm format, and this uses the Stockholm parser underneath.
          output.split(?\n).select { |line| line =~ HIT_SEQUENCE }.last.match(HIT_SEQUENCE)[1].upcase.gsub(?-, ?.)
        end

        def pull_infernal_hit_structure(output)
          convert_infernal_to_dot_bracket(output.split(?\n).find { |line| line =~ /CS\s*$/ }.gsub(/\s+CS\s*$/, "").strip)
        end

        def convert_infernal_to_dot_bracket(structure)
          # http://jalview-rnasupport.blogspot.com/2010/06/parsing-wuss-notation-of-rna-secondary.html
          structure.gsub(/[:,_-]/, ?.).gsub(/[<\[\{]/, ?().gsub(/[>\]\}]/, ?))
        end
      end
    end
  end
end
