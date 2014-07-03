module Wrnap
  module Etl
    module Infernal
      class << self
        def parse_hit(output)
          Stockholm.fit_structure_to_sequence(
            *output.split(?\n).as do |infernal|
              [
                infernal.select { |line| line =~ /^.*\d+\s+.*\s+\d+\s*$/ }.last.match(/^.*\s+(.*)\s+\d+\s*$/)[1].upcase.gsub(/[^AUGC]/, ?.),
                convert_infernal_to_dot_bracket(infernal.find { |line| line =~ /CS\s*$/ }.gsub(/\s+CS\s*$/, "").strip)
              ]
            end
          )
        end

        def convert_infernal_to_dot_bracket(structure)
          # http://jalview-rnasupport.blogspot.com/2010/06/parsing-wuss-notation-of-rna-secondary.html
          structure.gsub(/[:,_-]/, ?.).gsub(/[<\[\{]/, ?().gsub(/[>\]\}]/, ?))
        end
      end
    end
  end
end
