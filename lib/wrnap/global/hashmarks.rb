module Wrnap
  module Global
    module Hashmarks
    	def pp
    		p
    		puts hashmarks.join(?\n)
    	end

    	def hashmarks
    		0.upto(Math.log10(length).floor).map(&method(:hashmarks_for_radix))
    	end

    	private

      def hashmarks_for_radix(power)
      	radix  = 10 ** power
        hashes = (0..9).cycle.lazy.drop(1).take(length / radix).map { |i| "%s%d" % [" " * (radix - 1), i] }.force.join

        if hashes.length < length
        	"%s%s%s" % [hashes, " " * (length - hashes.length - 1), hashes[-1]]
        else hashes end
      end
    end
  end
end
