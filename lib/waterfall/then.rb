module Waterfall
  class Then < Base
    attr_reader :output
    # .then(proc)
    # .then block
    # .then(method_name, error_text)
    # .then(method_name, error_text, error_key)
    def call(previous_output)
      @output = trigger_handler(previous_output)
      post_process
      output
    end

    def post_process
      if is_waterfall? && handler.stop_waterfall?
        handler.errors.each do |key, value|
          root.reject key, value
        end
      end
      if root._reject_step_on_falsy? && !output
        root.reject error_key, error_value
      end
    end

    def error_key
      if first_arg_as_method_name?
        args[2] || args[0]
      else
        args[2] || 'base'
      end
    end

    def error_value
      args[1] || 'invalid'
    end

    def is_waterfall?
      handler.respond_to?(:is_waterfall?) && handler.is_waterfall?
    end
  end
end
