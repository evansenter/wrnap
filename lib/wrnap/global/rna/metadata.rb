module Wrnap
  module Global
    class Rna
      module Metadata
        def self.included(base)
          base.send(:include, InstanceMethods)
        end

        module InstanceMethods
          def self.included(base)
            base.class_eval do
              def_delegator :@metadata, :__data__, :md
            end
          end

          def meta(&block)
            metadata.tap { metadata.instance_eval(&block) if block_given? }
          end

          def meta_rna(&block)
            metadata.__rna__.tap { meta(&block) }
          end
        end

        class Container
          attr_reader :__rna__, :__data__

          def initialize(rna)
            @__rna__, @__data__ = rna, {}
          end

          def inspect
            "#<Metadata: %s>" % __data__.inspect
          end

          alias :to_s :inspect

          def method_missing(name, *args, &block)
            case args.size
            when 0 then __data__[name]
            when 1 then __data__[name.to_s.gsub(/=$/, "").to_sym] = args.first
            else super end
          end
        end
      end
    end
  end
end
