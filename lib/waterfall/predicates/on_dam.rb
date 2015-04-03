module Waterfall
  class OnDam < Base

    def initialize(root, &block)
      @root = root
    end

    def call(&block)
      if @root.dammed?
        @root._wf_rollback(rollback_self: false)
        yield @root.error_pool, @root
      end
    end
  end
end
