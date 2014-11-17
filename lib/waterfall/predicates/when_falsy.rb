module Waterfall
  class WhenFalsy < Base

    def initialize(root, &block)
      @root, @block = root, block
    end

    def call
      @output = call_block
    end

    def dam(&block)
      if !@root.dammed? && !@output
        @root.dam block.call(@root.outflow)
      end
      @root
    end
  end
end
