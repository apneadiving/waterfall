require 'ostruct'
require 'waterfall/version'
require 'waterfall/predicates/base'
require 'waterfall/predicates/on_dam'
require 'waterfall/predicates/when_falsy'
require 'waterfall/predicates/when_truthy'
require 'waterfall/predicates/chain'

module Waterfall

  attr_reader :error_pool, :outflow

  class IncorrectDamArgumentError      < StandardError; end
  class IncorrectChainingArgumentError < StandardError; end

  def when_falsy(&block)
    ::Waterfall::WhenFalsy.new(self).tap do |handler|
      _wf_run { handler.call(&block) }
    end
  end

  def when_truthy(&block)
    ::Waterfall::WhenTruthy.new(self).tap do |handler|
      _wf_run { handler.call(&block) }
    end
  end

  def chain(mapping_or_var_name = nil, &block)
    _wf_run do
      ::Waterfall::Chain
        .new(self, mapping_or_var_name)
        .call(&block)
    end
  end

  def on_dam(&block)
    ::Waterfall::OnDam
      .new(self)
      .call(&block)
    self
  end

  def dam(obj)
    raise IncorrectDamArgumentError.new("You cant dam with a falsy object") unless obj
    _wf_run do
      @error_pool = obj
      _reverse_flows(true)
    end
  end

  def halt_chain(&block)
    yield(outflow, error_pool)
  end

  def dammed?
    !error_pool.nil?
  end

  def is_waterfall?
    true
  end

  def has_flown?
    !! @has_flown
  end

  def update_outflow(key, value)
    @outflow[key] = value
    self
  end

  def reverse_flow
  end

  protected

  def _reverse_flows(current_error_spot)
    reverse_flow unless current_error_spot
    (@_executed_flows || []).reverse_each do |f|
      f.send :_reverse_flows, false
    end
  end

  def _add_executed_flow(flow)
    @_executed_flows ||= []
    @_executed_flows.push(flow)
  end

  def _wf_run
    @has_flown = true
    @outflow ||= OpenStruct.new({})
    yield unless dammed?
    self
  end
end

class Wf
  include Waterfall
  def initialize
    _wf_run {}
  end
end

Flow = Wf
