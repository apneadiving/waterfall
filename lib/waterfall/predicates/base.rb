module Waterfall
  class Base
    attr_reader :root, :args, :block, :handler
    def initialize(root, args, &block)
      @root, @args, @block = root, args, block
      @handler = get_handler
    end

    def trigger_handler(previous_output)
      if pass_arg?
        handler.call(previous_output)
      else
        handler.call
      end
    end

    def pass_arg?
      if handler.respond_to? :arity
        handler.arity == 1
      else
        handler.method(:call).arity == 1
      end
    end

    def get_handler
      return block if block
      first_arg_as_method_name? ? root.method(args[0]) : args[0]
    end

    def first_arg_as_method_name?
      args[0].is_a?(Symbol) || args[0].is_a?(String)
    end

    def is_waterfall?
      handler.respond_to?(:is_waterfall?) && handler.is_waterfall?
    end
  end
end
