module Wrnap
  module Global
    module Yaml
      def serialize(filename = false)
        cereal = YAML.dump(self)
        filename ? File.open(filename, ?w) { |file| file.write(cereal) } : cereal
      end

      def deserialize(string)
        YAML.load(File.exist?(string) ? File.read(string) : string)
      end
    end
  end
end
