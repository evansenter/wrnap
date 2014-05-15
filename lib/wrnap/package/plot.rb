module Wrnap
  module Package
    class Plot < Base
      self.quote_flag_params = %w|-pre -post|

      def run_command(flags)
        "cat %s | %s %s" % [
          data.temp_fa_file!,
          exec_name,
          stringify_flags(flags)
        ]
      end
    end
  end
end
