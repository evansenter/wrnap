module Wrnap
  module Global
    class Rna
      module TreeFunctions
        def with_tree
          meta_rna { |metadata| tree(TreePlanter.new(metadata.__rna__)) }
        end

        def trunk; md[:tree] || with_tree.trunk; end
      end

      class TreePlanter
        attr_reader :rna, :root

        def initialize(rna, tree = false)
          @rna  = rna
          @root = tree || build_tree
        end

        def build_tree
          rna.collapsed_helices.inject(Tree::TreeNode.new(:root, rna)) do |tree, helix|
            node = Tree::TreeNode.new(helix.name, helix)

            if tree.is_root?
              tree << node
            elsif helix.i > tree.content.j
              # It's a sibling, pop up until we're at its parent node.
              tree = tree.parent until tree.is_root? || tree.content.j > helix.i
              node.tap { tree << node }
            elsif helix.j < tree.content.j
              # Going deeper.
              tree << node
            end
          end.root
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
end
