module Waterfall
  class Base

    def waterfall?(obj)
      obj.respond_to?(:is_waterfall?) && obj.is_waterfall?
    end

    def call_block
       @block.call(@root.outflow, @root)
    end

    def chained_waterfall(&block)
      child_waterfall = call_block

      unless waterfall?(child_waterfall)
        raise "Your inflow is not a waterfall, but a #{ child_waterfall.class }"
      end

      child_waterfall.call unless child_waterfall.flowing?

      if child_waterfall.dammed?
        @root.dam child_waterfall.error_pool
      else
        block.call(child_waterfall)
      end
    end
  end
end
