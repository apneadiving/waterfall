module Waterfall
  class ChainWf < Base

    def initialize(root, mapping, &block)
      @root, @mapping, @block = root, mapping, block
    end

    def call
      child_waterfall = call_block

      unless waterfall?(child_waterfall)
        raise "You're wf chaining a #{ child_waterfall.class } instead of a waterfall"
      end

      child_waterfall.call

      if child_waterfall.stop_waterfall?
        @root.reject child_waterfall.rejection_reason
      else
        @mapping.each do |k, v|
          @root.update_wf_result(k, child_waterfall.wf_result[v])
        end
      end
    end

  end
end
