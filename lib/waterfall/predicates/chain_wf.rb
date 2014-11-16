module Waterfall
  class ChainWf < Base

    def initialize(root, mapping, &block)
      @root, @mapping, @block = root, mapping, block
    end

    def call
      chained_waterfall do |child_waterfall|
        @mapping.each do |k, v|
          @root.update_outflow(k, child_waterfall.outflow[v])
        end
      end
    end

  end
end
