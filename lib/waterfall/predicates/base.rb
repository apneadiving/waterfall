module Waterfall
  class Base

    def waterfall?(obj)
      obj.respond_to?(:is_waterfall?) && obj.is_waterfall?
    end

    def chained_waterfall(child_waterfall, &block)
      unless waterfall?(child_waterfall)
        raise "Your inflow is not a waterfall, but a #{ child_waterfall.class }"
      end

      child_waterfall.call unless child_waterfall.flowing?

      if child_waterfall.dammed?
        @root.dam child_waterfall.error_pool
      else
        yield
        @root.add_executed_waterfall(child_waterfall)
      end
    end

    def yield_args
      [@root.outflow, @root]
    end
  end
end
