module Waterfall
  class MergeWf < Base

    def initialize(root, &block)
      @root, @block = root, block
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
        child_waterfall.wf_result.each do |k, v|
          @root.update_wf_result(k, v)
        end
      end
    end

  end
end
