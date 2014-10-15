module Waterfall
  class Chain

    def initialize(root, var_name, &block)
      @root, @var_name, @block = root, var_name, block
    end

    def call
      output = @block.call(@root.wf_result)
      @root.update_wf_result(@var_name, output) if @var_name
    end

  end
end
