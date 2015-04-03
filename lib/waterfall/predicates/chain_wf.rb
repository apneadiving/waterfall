module Waterfall
  class ChainWf < Base

    def initialize(root, mapping)
      @root, @mapping = root, mapping
    end

    def call(&block)
      child_waterfall = yield(*yield_args)
      chained_waterfall(child_waterfall) do
        @mapping.each do |k, v|
          @root.update_outflow(k, child_waterfall.outflow[v])
        end
      end
    end

  end
end
