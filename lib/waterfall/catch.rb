module Waterfall
  class Catch < Base
    def call
      if root.stop_waterfall?
        trigger_handler(root.errors)
      else
        root.waterfall_result
      end
    end
  end
end
