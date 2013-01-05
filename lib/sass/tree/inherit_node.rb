module Sass
  module Tree
    # A static node that wraps the {Sass::Tree} for an `@inherit`ed file.
    # It doesn't have a functional purpose other than to add the `@inherit`ed file
    # to the backtrace if an error occurs.
    class InheritNode < ImportNode
    end
  end
end
