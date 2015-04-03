module Waterfall
  class WhenTruthy < Base

    def initialize(root)
      @root = root
    end

    def call(&block)
      @output = yield(*yield_args)
    end

    def dam(&block)
      if !@root.dammed? && @output
        @root.dam yield(*yield_args)
      end
      @root
    end
  end
end
