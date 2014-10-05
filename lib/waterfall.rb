require 'active_model'
require 'waterfall/version'
require 'waterfall/base'
require 'waterfall/then'
require 'waterfall/catch'

module Waterfall

  attr_reader :waterfall_result

  def self.included(base)
    base.send :include, ::ActiveModel::Validations
  end

  def then(*args, &block)
    return self if stop_waterfall?

    @waterfall_result = ::Waterfall::Then
                          .new(self, args, &block)
                          .call(waterfall_result)

    self
  end

  def tap(proc = nil, &block)
    (proc || block).call self
  end

  def catch(*args, &block)
    ::Waterfall::Catch.new(self, args, &block).call
  end

  def reject(key, value)
    errors.add(key, value)
  end

  def stop_waterfall?
    errors.any?
  end

  def is_waterfall?
    true
  end

  def _reject_step_on_falsy?
    true
  end
end

class Wf
  include Waterfall
  attr_reader :options
  def initialize(options = {})
    @options = options.merge _default_options
  end

  def _reject_step_on_falsy?
    options[:reject_on_falsy]
  end

  def _default_options
    {
      reject_on_falsy: true
    }
  end
end

