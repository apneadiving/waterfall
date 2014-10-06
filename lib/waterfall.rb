require 'waterfall/version'
require 'waterfall/predicates/base'
require 'waterfall/predicates/then'
require 'waterfall/predicates/catch'
require 'waterfall/predicates/when_falsy'

module Waterfall

  attr_reader :waterfall_result, :rejection_reason

  def then(*args, &block)
    return self if stop_waterfall?

    @waterfall_result = ::Waterfall::Then
                          .new(self, args, &block)
                          .call(waterfall_result)

    self
  end

  def when_falsy(*args, &block)
    return self if stop_waterfall?

    @waterfall_result = ::Waterfall::WhenFalsy
                          .new(self, args, &block)
                          .call(waterfall_result)

    self
  end

  def catch(*args, &block)
    ::Waterfall::Catch.new(self, args, &block).call
  end

  def tap(proc = nil, &block)
    (proc || block).call self
  end

  def reject(obj)
    @rejection_reason = obj
  end

  def stop_waterfall?
    rejection_reason
  end

  def is_waterfall?
    true
  end
end

class Wf
  include Waterfall
end

