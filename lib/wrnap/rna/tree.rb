module Wrnap
  class Rna
    module TreeFunctions
      def with_tree
        meta_rna { |metadata| tree(TreePlanter.new(metadata.__rna__)) }
      end

      def trunk
        md[:tree] || with_tree.trunk
      end
    end

    class TreeStem < Tree::TreeNode
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
              array << Loop.new(node.k + 1, node.l - 1)
            end
            
            if node != self
              if node.is_only_child?
                Wrnap.debugger { "Interior node: %s, parent: %s" % [node.content.inspect, node.parent.content.inspect] }
          
                if node.i - node.parent.k > 0
                  Wrnap.debugger { "Left bulge." }
                  array << Loop.new(node.parent.k + 1, node.i - 1)
                end
          
                if node.parent.l - node.j > 0
                  Wrnap.debugger { "Right bulge." }
                  array << Loop.new(node.j + 1, node.parent.l - 1)
                end
              else
                node_index = node.parent.children.each_with_index.find { |child, _| child == node }.last
              
                if node.is_last_sibling?
                  Wrnap.debugger { "Leaf node, last child: %s" % node.content.inspect }
                  array << Loop.new(node.j + 1, node.parent.l - 1)
                else
                  if node.is_first_sibling?
                    Wrnap.debugger { "Leaf node, first child: %s" % node.content.inspect }
                    array << Loop.new(node.parent.k + 1, node.i - 1) 
                  end
                
                  Wrnap.debugger { "Connecting node, middle child: %s" % node.content.inspect }
                  alexa = node.siblings[node_index]
                  array << Loop.new(node.j + 1, alexa.i - 1)
                end
              end
            end            
          end
        end
      end
      
      def detached_copy
        self.class.new(@name, @content ? @content.clone : nil)
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
          when ?t then child
          end
        end
      end
    end

    class TreePlanter
      prepend MetaMissing
      
      attr_reader :rna, :root

      def initialize(rna, tree = false)
        @rna  = rna
        @root = tree || build_tree(rna.collapsed_helices)
      end

      def build_tree(helices)
        helices.inject(TreeStem.new(:root, rna)) do |tree, helix|
          add_node(tree, TreeStem.new(helix.name, helix))
        end.root
      end

      def extend_tree(*helices)
        self.class.new(rna, rebuild_tree(helices))
      end

      def extend_tree!(*helices)
        tap { @root = rebuild_tree(helices) }
      end

      def rebuild_tree(helices)
        build_tree((root.map(&:content).select { |helix| helix.is_a?(Helix) } + helices.flatten).sort_by(&:i))
      end

      def add_node(subtree, node)
        # This function has an implicit, *very important* expectation that nodes are added in a depth-first, preorder traversal fashion.
        # What this means is that given a tree containing two sibling nodes (i, j), (k, l), you can't later add another node (m, n) which
        # makes (i, j), (k, l) into a multiloop. (m, n) *must* be added before any of it's children for the resulting structure to be accurate.

        # Case 1: the tree is empty.
        if subtree.is_root? && subtree.size == 1
          subtree << node
        # Case 2: the node to add is after the current stem.
        elsif node.i > subtree.j
          # It's a sibling, pop up until we're at its parent node.
          subtree = subtree.parent until subtree.is_root? || subtree.j > node.i
          node.tap { subtree << node }
        # Case 3: the node to add is within the current stem.
        elsif node.j < subtree.j
          # Going deeper.
          subtree << node
        end
      end

      def coalesce
        self.class.new(rna, root.dup).tap { |tree| tree.merge_interior_loops! }
      end

      def coalesce!
        tap { merge_interior_loops! }
      end
      
      def fuse
        self.class.new(rna, root.dup).tap { |tree| tree.extend_interior_loops! }
      end

      def fuse!
        tap { extend_interior_loops! }
      end
  
      def extend_interior_loops!
        handle_interior_loops! do |node, child|
          node.content.merge!(child.content)
          child.remove_from_parent!
          child.children.each { |grandchild| node.add(grandchild) }
        end
      end
  
      def merge_interior_loops!
        handle_interior_loops! do |node, child|
          node.parent.add(child)
          node.remove_from_parent!
        end
      end
      
      def handle_interior_loops!(&block)
        root.tap do
          root.postorder_traversal do |node|
            if node.children.count == 1 && !node.is_root?              
              yield(node, node.children.first)
            end
          end
          
          extend_tree!
        end
      end

      def depth_signature
        root.map(&:node_depth)
      end

      def pp
        root.print_tree and nil
      end

      alias_method :to_s, def inspect
        "#<TreePlanter: %s>" % depth_signature.inspect
      end
      
      handle_methods_like(TreeStem::STEM_NOTATION_REGEX) do |match, name, *args, &block|
        root.send(name, *args, &block)
      end
    end
  end
end
