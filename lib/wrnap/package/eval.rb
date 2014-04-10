module Wrnap
  module Package
    class Eval < Base
      self.call_with = [:seq, :str]
      
      attr_reader :mfe
    
      def post_process
        @mfe = Wrnap::Global::Parser.rnafold_mfe(response)
      end
    end
  end
end
