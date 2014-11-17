module Waterfall
  class OnDam < Base

    def initialize(root, &block)
      @root, @block = root, block
    end

    def call
      if @root.dammed?
        @block.call @root.error_pool, @root
      end
    end
  end
end
