module Waterfall
  class MergeWf < Base

    def initialize(root)
      @root = root
    end

    def call(&block)
      child_waterfall = yield(*yield_args)
      merge_waterfalls(child_waterfall)
    end

  end
end
