module Waterfall
  class Chain < Base

    def initialize(root, var_name, &block)
      @root, @var_name, @block = root, var_name, block
    end

    def call
      output = call_block
      @root.update_wf_result(@var_name, output) if @var_name
    end

  end
end
