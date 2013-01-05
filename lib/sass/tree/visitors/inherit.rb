# A visitor for performing tree inheritance on a static CSS tree.
class Sass::Tree::Visitors::Inherit < Sass::Tree::Visitors::Base
  # Performs the given inheritance on the static CSS tree based in `root`.
  #
  # @param root [Tree::Node] The root node of the tree to visit.
  # @return [Object] The return value of \{#visit} for the root node.
  def self.visit(root)
    new().send(:visit, root)
  end

  protected

  def initialize()
    @children_stack = []
    @children
  end

  # If an exception is raised, this adds proper metadata to the backtrace.
  def visit(node)
    if !@children_stack.empty? && !node.instance_of?(Sass::Tree::InheritNode)
      @children.push node
    end
    super(node)
  rescue Sass::SyntaxError => e
    e.modify_backtrace(:filename => node.filename, :line => node.line)
    raise e
  end

  def visit_inherit(node)
    yield
    node.children.each do |child|
      # This flag is used to merge another rules into this node.
      child.inherited = true
      @children.push child
    end
  end

  def visit_children(parent)
    @children = []
    @children_stack.push @children
    super
    parent.children = merge(@children_stack.last)
    @children = @children_stack.last
  ensure
    @children_stack.pop
    @children = @children_stack.last
  end

  private

  def merge(children)
    own = children.select {|c| !c.inherited}
    inherited = children.select {|c| c.inherited}
    # Traverse inherited nodes in reverse order to merge into last inherited
    # rule.
    for child in inherited.reverse_each
      # Search for not merged rules with same selectors.
      if child.is_a? Sass::Tree::RuleNode
        selectors = child.resolved_rules.to_s
        for matched in own.select {|c| c.resolved_rules.to_s == selectors}.each
          # Merge properties.
          child.children.concat matched.children
        end
      end
      # Remove merged rules from working copy.
      own = own.select {|c| c.resolved_rules.to_s != selectors}
    end
    # Remove merged nodes from the result. The original array is used again
    # to preserve the order of nodes.
    children.select {|c| own.include?(c) || c.inherited}
  end

end
