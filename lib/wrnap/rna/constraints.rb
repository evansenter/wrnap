require File.join(File.dirname(__FILE__), "tree.rb")

module Wrnap
  class Rna
    module Constraints
      def self.included(base)
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def constraint_mask
          md[:constraint_mask]
        end
        
        def show_constraints(&block)
          ConstraintBox.new(metadata.__rna__).tap { |box| box.instance_eval(&block) }.to_s
        end

        def build_constraints(&block)
          meta_rna do |metadata|
            constraint_mask(ConstraintBox.new(metadata.__rna__).tap { |box| box.instance_eval(&block) })
          end
        end
      end

      class ConstraintBox
        prepend MetaMissing
        
        attr_reader :rna, :constraints

        def initialize(rna)
          @rna, @constraints = rna, []
        end
        
        def n
          rna.len - 1
        end

        def between(i, j)
          Loop.new(i, j)
        end
        
        def inside(i, j)
          between(i + 1, j - 1)
        end
        
        def start_to(i)
          between(0, i)
        end
        
        def end_to(i)
          between(i, n)
        end
        
        def freeze(mask_object)
          force mask_object
          prohibit mask_object.unpaired_regions
        end
        
        def mask!(mask_object, *args)
          case mask_object
          when TreeStem then mask_object.preorder_traversal { |node| mask!(node.content, *args) }
          when Array    then mask_object.map { |node| mask!(node, *args) }
          when Helix    then mask_helix!(mask_object, *args)
          when Loop     then mask_loop!(mask_object, symbol: args[0][:symbol])
          end
        end

        def mask_helix!(helix, side: :both, symbol: "()")
          left_loop, right_loop = helix.to_loops

          if symbol.length > 1
            left_symbol, right_symbol = symbol.split(//)
          else
            left_symbol = right_symbol = symbol
          end

          mask_loop!(left_loop,  symbol: left_symbol)  if side == :left  || side == :both
          mask_loop!(right_loop, symbol: right_symbol) if side == :right || side == :both
        end
        
        def mask_loop!(l00p, symbol: "x")
          mask_region!(l00p.i, l00p.j, symbol: symbol)
        end
        
        def mask_region!(i, j, symbol: "x")
          raise ArgumentError.new("Trying to apply symbol '%s' from %d to %d, all symbols must be 1 char long." % [symbol, i, j]) if symbol.length > 1
          
          constraints << ConstraintData.new(i, j, symbol)
          prune!
        end

        def prune!
          @constraints = constraints.group_by(&:name).map(&:last).map(&:first)
        end

        def inspect
          "#<Constraints: %s>" % constraints.map(&:name).join(", ")
        end

        def to_s
          (?. * rna.len).tap do |string|
            constraints.each { |constraint| string[constraint.from..constraint.to] = constraint.symbol * constraint.length }
          end
        end
        
        alias_method :mask, :to_s

        handle_methods_like(TreeStem::STEM_NOTATION_REGEX) do |match, name, *args, &block|
          rna.trunk.send(name.to_s)
        end
        
        handle_methods_like(/^(prohibit|force)(_(left|right)_stem)?$/) do |match, name, *args, &block|
          side_symbol = match[3] ? match[3].to_sym : :both
          
          case match[1]
          when "prohibit" then mask!(args[0], side: side_symbol, symbol: args[1] || ?x)
          when "force"    then mask!(args[0], side: side_symbol, symbol: args[1] || "()")
          end
        end
      end

      class ConstraintData
        attr_reader :from, :to, :symbol

        def initialize(from, to, symbol)
          @from, @to, @symbol = from, to, symbol
        end

        def name
          "(%d to %d as '%s')" % [from, to, symbol]
        end

        def length
          to - from + 1
        end

        def inspect
          "#<Constraint: %s>" % name
        end
      end
    end
  end
end
