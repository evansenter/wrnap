module Wrnap
  class Rna        
    class Loop
      include Virtus.value_object(strict: true)

      values do
        attribute :from, Integer
        attribute :to,   Integer
      end
      
      def in(sequence)
        sequence[from..to]
      end
      
      def length
        to - from + 1
      end
      
      def name
        "(%d, %d [%d])" % [from, to, length]
      end
      
      def inspect
        "#<Loop: %s>" % name
      end
    end
  end
end
