module Waterfall
  class Then < Base
    attr_reader :output
    # .then(proc)
    # .then block
    def call(previous_output)
      @output = trigger_handler(previous_output)
      post_process
      output
    end

    def post_process
      if is_waterfall? && handler.stop_waterfall?
        root.reject handler.rejection_reason
      end
    end
  end
end
