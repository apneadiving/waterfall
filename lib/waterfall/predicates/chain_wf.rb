module Waterfall
  class ChainWf < Base

    def initialize(root, mapping)
      @root, @mapping = root, mapping
    end

    def call(&block)
      child_waterfall = yield(*yield_args)
      map_waterfalls(child_waterfall, @mapping)
    end
  end
end
