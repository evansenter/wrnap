module Wrnap
  class Rna
    module Tree
      class Planter
        prepend MetaMissing

        attr_reader :structure, :root

        def initialize(structure, tree: false, lonely_bp: false)
          @structure = structure
          @root      = tree || build_tree(structure.collapsed_helices(lonely_bp: lonely_bp))
        end

        # RNA.from_fa("xpt.fa").trunk.pp
        # * root
        # |---+ (5..12, 66..73 [8])
        # |    |---> (18..22, 30..34 [5])
        # |    +---> (45..50, 58..63 [6])
        # |---+ (75..78, 102..105 [4])     <-
        # |    +---> (80..86, 95..101 [7]) <-
        # +---> (112..125, 133..146 [14])
        #
        # RNA.from_fa("xpt.fa").trunk.prune_interior_loops.pp
        # * root
        # |---+ (5..12, 66..73 [8])
        # |    |---> (18..22, 30..34 [5])
        # |    +---> (45..50, 58..63 [6])
        # |---> (80..86, 95..101 [7])      <-
        # +---> (112..125, 133..146 [14])

        def prune_interior_loops
          self.class.new(structure, tree: root.clone).tap { |tree| tree.handle_interior_loops_by_pruning! }
        end

        def prune_interior_loops!
          tap { handle_interior_loops_by_pruning! }
        end

        # RNA.from_fa("xpt.fa").trunk.pp
        # * root
        # |---+ (5..12, 66..73 [8])
        # |    |---> (18..22, 30..34 [5])
        # |    +---> (45..50, 58..63 [6])
        # |---+ (75..78, 102..105 [4])     <-
        # |    +---> (80..86, 95..101 [7]) <-
        # +---> (112..125, 133..146 [14])
        #
        # RNA.from_fa("xpt.fa").trunk.merge_interior_loops.pp
        # * root
        # |---+ (5..12, 66..73 [8])
        # |    |---> (18..22, 30..34 [5])
        # |    +---> (45..50, 58..63 [6])
        # |---> (75..86, 94..105 [12])     <-
        # +---> (112..125, 133..146 [14])

        def merge_interior_loops
          self.class.new(structure, tree: root.clone).tap { |tree| tree.handle_interior_loops_by_merging! }
        end

        def merge_interior_loops!
          tap { handle_interior_loops_by_merging! }
        end

        def depth_signature
          root.map(&:node_depth)
        end

        alias_method :p, def pp
          root.print_tree and nil
        end

        def inspect
          "#<Planter: %s>" % depth_signature.inspect
        end

        handle_methods_like(Stem::STEM_NOTATION_REGEX) do |match, name, *args, &block|
          root.send(name, *args, &block)
        end

        private

        def handle_interior_loops_by_merging!
          handle_interior_loops! do |node, child|
            node.content.merge!(child.content)
            child.remove_from_parent!
            child.children.each { |grandchild| node.add(grandchild) }
          end
        end

        def handle_interior_loops_by_pruning!
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

        def build_tree(helices)
          helices.inject(Stem.new(:root, structure)) do |tree, helix|
            add_node(tree, Stem.new(helix.name, helix))
          end.root
        end

        def extend_tree(*helices)
          self.class.new(structure, tree: rebuild_tree(helices))
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
      end
    end
  end
end
