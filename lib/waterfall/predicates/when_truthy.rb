module Waterfall
  class WhenTruthy < Base

    def initialize(root)
      @root = root
    end

    def call
      @output = yield(*yield_args)
    end

    def dam
      if !@root.dammed? && @output
        @root.dam yield(*yield_args)
      end
      @root
    end
  end
end
