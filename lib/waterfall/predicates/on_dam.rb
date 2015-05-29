module Waterfall
  class OnDam < Base

    def initialize(root, &block)
      @root = root
    end

    def call(&block)
      return unless @root.dammed?
      yield @root.error_pool, @root
      @root._wf_rollback(rollback_self: false) if @root.dammed?
    end
  end
end
