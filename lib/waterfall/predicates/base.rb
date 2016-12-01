module Waterfall
  class Base

    def waterfall?(obj)
      obj.respond_to?(:is_waterfall?) && obj.is_waterfall?
    end

    def yield_args
      [@root.outflow, @root]
    end
  end
end
