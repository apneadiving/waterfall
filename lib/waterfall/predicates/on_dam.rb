module Waterfall
  class OnDam < Base

    def initialize(root)
      @root = root
    end

    def call
      return unless @root.dammed?
      yield @root.error_pool, @root.outflow, @root
    end
  end
end
