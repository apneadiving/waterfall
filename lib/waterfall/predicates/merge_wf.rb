module Waterfall
  class MergeWf < Base

    def initialize(root, &block)
      @root, @block = root, block
    end

    def call
      chained_waterfall do |child_waterfall|
        child_waterfall.outflow.each do |k, v|
          @root.update_outflow(k, v)
        end
      end
    end

  end
end
