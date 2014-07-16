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
              def_delegator :@metadata, :data, :md
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
          attr_reader :__rna__, :data

          def initialize(rna)
            @__rna__, @data = rna, {}
          end

          def method_missing(name, *args, &block)
            case args.size
            when 0 then data[name]
            when 1 then data[name.to_s.gsub(/=$/, "").to_sym] = args.first
            else super end
          end
        end
      end
    end
  end
end
