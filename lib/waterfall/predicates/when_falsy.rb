module Waterfall
  class WhenFalsy < Base

    def initialize(root, error_value, &block)
      @root, @error_value, @block = root, error_value, block
    end

    def call
      output = @block.call(@root.wf_result)
      @root.reject @error_value if !output
    end
  end
end
