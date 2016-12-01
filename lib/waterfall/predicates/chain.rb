module Waterfall
  class Chain < Base

    def initialize(root, mapping_or_var_name)
      @root, @mapping_or_var_name = root, mapping_or_var_name
    end

    def call
      output = yield(*yield_args)

      if waterfall?(output)
        map_waterfalls(output, @mapping_or_var_name || {})
      else
        @root.update_outflow(@mapping_or_var_name, output) if @mapping_or_var_name
      end
    end

    def map_waterfalls(child_waterfall, mapping)
      child_waterfall.call unless child_waterfall.flowing?

      mapping.each do |k, v|
        @root.update_outflow(k, child_waterfall.outflow[v])
      end

      if child_waterfall.dammed?
        @root.dam child_waterfall.error_pool
      end

      self
    end
  end
end
