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
      extend Forwardable
      include Enumerable

      STEM_NOTATION_REGEX = /^p((\d+_)*(\d+))(_?([ijkl]))?$/

      def_delegators :@content, :i, :j
      def_delegator  :@content, :length, :stem_length

      def method_missing(name, *args, &block)
        if name.to_s =~ STEM_NOTATION_REGEX
          if $2 && child = children[$2.to_i - 1]
            child.send("p%s" % name.to_s.gsub(/^p\d+_/, ""))
          elsif child = children[$1.to_i - 1]
            $5 ? child.content.send($5) : child.content
          else
            nil
          end
        else super end
      end
    end

    class TreePlanter
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

      def merge_interior_loops!
        root.tap do
          self.class.postorder_traversal(root) do |node|
            if node.children.count == 1 && !node.is_root?
              child = node.children.first
              node.parent.add(child)
              node.remove_from_parent!
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

      def inspect
        "#<TreePlanter: %s>" % depth_signature.inspect
      end

      alias :to_s :inspect

      def method_missing(name, *args, &block)
        if name.to_s =~ TreeStem::STEM_NOTATION_REGEX
          root.send(name, *args, &block)
        else super end
      end

      class << self
        def preorder_traversal(node, &block)
          node.children.map { |child| preorder_traversal(child, &block) }
          yield node
        end

        def postorder_traversal(node, &block)
          node.children.map { |child| postorder_traversal(child, &block) }
          yield node
        end
      end
    end
  end
end
