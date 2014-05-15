module Wrnap
  module Package
    class Varna < Base
      self.executable_name = "java"
      self.default_flags   = ->(context, flags) do
        {
          sequenceDBN:  context.data.seq,
          structureDBN: context.data.str,
          resolution:   2
        }
      end
      self.quote_flag_params = %w|sequenceDBN structureDBN|

      def run_command(flags)
        "java fr.orsay.lri.varna.applications.VARNAcmd %s" % stringify_flags(flags)
      end
    end
  end
end
