module Waterfall
  class MergeWf < Base

    def initialize(root)
      @root = root
    end

    def call(&block)
      child_waterfall = yield(*yield_args)
      chained_waterfall(child_waterfall) do
        child_waterfall.outflow.each do |k, v|
          @root.update_outflow(k, v)
        end
      end
    end

  end
end
