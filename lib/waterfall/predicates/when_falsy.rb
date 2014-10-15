module Waterfall
  class WhenFalsy < Base

    def initialize(root, &block)
      @root, @block = root, block
    end

    def call
      @output = @block.call(@root.wf_result)
    end

    def then(&block)
      unless @output
        @root.reject block.call(@root.wf_result)
      end
      @root
    end
  end
end
