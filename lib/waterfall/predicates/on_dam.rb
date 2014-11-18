module Waterfall
  class OnDam < Base

    def initialize(root, &block)
      @root, @block = root, block
    end

    def call
      if @root.dammed?
        @root._wf_rollback(rollback_self: false)
        @block.call @root.error_pool, @root
      end
    end
  end
end
