module Waterfall
  class WhenFalsy < Base

    def initialize(root, &block)
      @root, @block = root, block
    end

    def call
      @output = call_block
    end

    def reject(&block)
      if !@root.stop_waterfall? && !@output
        @root.reject block.call(@root.wf_result)
      end
      @root
    end
  end
end
