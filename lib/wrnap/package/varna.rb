module Wrnap
  module Package
    class Varna < Base
      self.executable_name = "java"
      self.default_flags   = ->(context, flags) do
        defaults = {
          sequenceDBN:  context.data.seq,
          structureDBN: context.data.str,
          titleSize:    8,
          resolution:   2
        }

        context.data.name ? defaults.merge(title: context.data.name) : defaults
      end
      self.quote_flag_params = %w|sequenceDBN structureDBN title|

      def run_command(flags)
        "java -Djava.awt.headless=true fr.orsay.lri.varna.applications.VARNAcmd %s" % stringify_flags(flags)
      end
    end
  end
end
