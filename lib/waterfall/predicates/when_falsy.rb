module Waterfall
  class WhenFalsy < Base
    attr_reader :output
    # .when_falsy(method_name, error_obj)
    def call(previous_output)
      @output = trigger_handler(previous_output)
      post_process
      output
    end

    def post_process
      if is_waterfall? && handler.stop_waterfall?
        root.reject handler.rejection_reason
      elsif !output
        root.reject build_error
      end
    end

    def build_error
      args[1] || 'invalid'
    end
  end
end
