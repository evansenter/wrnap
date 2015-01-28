module Wrnap
  class Rna
    module Tree
      class Stem < ::Tree::TreeNode
        prepend MetaMissing
        extend Forwardable
        include Enumerable

        STEM_NOTATION_REGEX = /^[pt]_?(\d+_)*\d+(_?[ijkl])?$/

        def_delegators :@content, :i, :j, :k, :l
        def_delegator  :@content, :length, :stem_length
      
        def unpaired_regions
          Wrnap.debugger { "Collecting unpaired regions for %s" % [root.content.name] }
        
          postorder_traversal.inject([]) do |array, node|
            array.tap do
              if node.is_leaf?
                array << Loop.new(from: node.k + 1, to: node.l - 1)
              end
            
              if node != self
                if node.is_only_child?
                  Wrnap.debugger { "Interior node: %s, parent: %s" % [node.content.inspect, node.parent.content.inspect] }
          
                  if node.i - node.parent.k > 0
                    Wrnap.debugger { "Left bulge." }
                    array << Loop.new(from: node.parent.k + 1, to: node.i - 1)
                  end
          
                  if node.parent.l - node.j > 0
                    Wrnap.debugger { "Right bulge." }
                    array << Loop.new(from: node.j + 1, to: node.parent.l - 1)
                  end
                else
                  node_index = node.parent.children.each_with_index.find { |child, _| child == node }.last
              
                  if node.is_last_sibling?
                    Wrnap.debugger { "Leaf node, last child: %s" % node.content.inspect }
                    array << Loop.new(from: node.j + 1, to: node.parent.l - 1)
                  else
                    if node.is_first_sibling?
                      Wrnap.debugger { "Leaf node, first child: %s" % node.content.inspect }
                      array << Loop.new(from: node.parent.k + 1, to: node.i - 1) 
                    end
                
                    Wrnap.debugger { "Connecting node, middle child: %s" % node.content.inspect }
                    alexa = node.siblings[node_index]
                    array << Loop.new(from: node.j + 1, to: alexa.i - 1)
                  end
                end
              end            
            end
          end
        end
      
        def preorder_traversal(&block)
          return enum_for(:preorder_traversal) unless block_given?
          yield self
          children.map { |child| child.preorder_traversal(&block) }
        end
      
        def postorder_traversal(&block)
          return enum_for(:postorder_traversal) unless block_given?
          children.each { |child| child.postorder_traversal(&block) }
          yield self
        end
        
        def detached_copy
          # The implementation of this in RubyTree explicitly returns a new ::Tree::TreeNode instance rather than self.class.new, so we
          # maintain ducktyping by intercepting the method.
          self.class.new(@name, @content ? @content.clone : nil)
        end
      
        handle_methods_like(STEM_NOTATION_REGEX) do |match, name, *args, &block|
          method_name = name.to_s
          call_type   = method_name[0]
          indices     = method_name.gsub(/\D+/, ?_).split(?_).reject(&:empty?).map(&:to_i)
          helix_index = method_name.match(/([ijkl])$/) ? $1 : ""

          if indices.size > 1 && child = children[indices[0] - 1]
            child.send(call_type + indices[1..-1].join(?_) + helix_index)
          elsif child = children[indices[0] - 1]
            case call_type
            when ?p then helix_index.empty? ? child.content : child.send(helix_index)
            when ?t then Planter.new(root.content, Stem.new(:subtree, root.content).tap { |stem| stem << child })
            end
          end
        end
      end
    end
  end
end
