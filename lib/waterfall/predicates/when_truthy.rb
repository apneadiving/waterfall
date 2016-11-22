module Waterfall
  class WhenTruthy < Base

    def initialize(root)
      @root = root
    end

    def call
      @output = yield(*yield_args)
    end

    def dam
      if dammed?
        @root.dam yield(*yield_args)
      end
      @root
    end

    def dammed?
      !@root.dammed? && @output
    end
  end
end
