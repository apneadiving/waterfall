module Waterfall
  class Base

    def waterfall?(obj)
      obj.respond_to?(:is_waterfall?) && obj.is_waterfall?
    end

    def call_block
       @block.call(@root.wf_result, @root)
    end
  end
end
